"""Filesystem lifecycle tests; all writes are confined to temporary homes."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class Sandbox(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(self.home),
            DOTFILES_DIR=str(REPO),
            XDG_CONFIG_HOME=str(self.home / "config"),
            XDG_DATA_HOME=str(self.home / "data"),
            XDG_STATE_HOME=str(self.home / "state"),
            XDG_CACHE_HOME=str(self.home / "cache"),
        )

    def command(self, args, input=None, check=True):
        result = subprocess.run(
            args, env=self.env, input=input, text=True,
            capture_output=True, timeout=20,
        )
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def state(self, script):
        return self.command([
            "/bin/bash", "-ec",
            f'log_warning() {{ :; }}; source "{REPO}/scripts/lib/state.sh"; '
            "state_init; " + script,
        ])

    def uninstall(self, *args):
        return self.command(
            ["/bin/bash", str(REPO / "uninstall.sh"), *args], input="y\n"
        )

    def mock(self, name, body):
        directory = self.home / "bin"
        directory.mkdir(exist_ok=True)
        path = directory / name
        path.write_text("#!/bin/bash\nset -e\n" + body)
        path.chmod(0o755)
        self.env["PATH"] = str(directory) + ":" + os.environ["PATH"]
        return path


class RollbackTests(Sandbox):
    def test_unreferenced_backup_from_old_uninstall_is_not_reused(self):
        path = self.home / "config-file"
        path.write_text("new baseline")
        self.state(
            'name="$(_state_backup_name "$HOME/config-file")"; '
            'printf obsolete > "$STATE_BACKUPS/$name"; '
            'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"'
        )
        self.uninstall()
        self.assertEqual(path.read_text(), "new baseline")

    def test_reinstall_captures_new_baseline_with_optional_state_retained(self):
        path = self.home / "config-file"
        path.write_text("baseline A")
        self.state(
            'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"; '
            'state_record SOFTWARE unknown'
        )
        self.uninstall()
        path.write_text("baseline B")
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        self.uninstall()
        self.assertEqual(path.read_text(), "baseline B")

    def test_original_survives_removed_link_and_setup_rerun(self):
        path = self.home / "config-file"
        path.write_text("original")
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        path.unlink()
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        self.uninstall()
        self.assertEqual(path.read_text(), "original")

    def test_writing_original_symlink_leaves_its_target_untouched(self):
        target = self.home / "target"
        target.write_text("original target")
        path = self.home / "config-file"
        path.symlink_to(target)
        self.state(
            'state_write_file "$HOME/config-file"; '
            'printf managed > "$HOME/config-file"; state_finish_file "$HOME/config-file"'
        )
        self.uninstall()
        self.assertTrue(path.is_symlink())
        self.assertEqual(target.read_text(), "original target")

    def test_user_replacement_preserves_backup_and_can_be_retried(self):
        path = self.home / "config-file"
        path.write_text("original")
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        path.unlink()
        path.write_text("user replacement")
        self.uninstall()
        self.assertEqual(path.read_text(), "user replacement")
        self.assertTrue((self.home / "data/dotfiles-state/manifest").exists())
        path.unlink()
        self.uninstall()
        self.assertEqual(path.read_text(), "original")

    def test_original_directory_and_dangling_symlink_are_restored(self):
        directory = self.home / "directory"
        directory.mkdir()
        (directory / "original").write_text("directory content")
        dangling = self.home / "dangling"
        dangling.symlink_to(self.home / "missing")
        self.state(
            'state_symlink "$DOTFILES_DIR/nvim" "$HOME/directory"; '
            'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/dangling"'
        )
        self.uninstall()
        self.assertEqual((directory / "original").read_text(), "directory content")
        self.assertEqual(os.readlink(dangling), str(self.home / "missing"))

    def test_created_file_is_removed_after_write_rerun(self):
        for _ in range(2):
            self.state(
                'state_write_file "$HOME/new"; printf managed > "$HOME/new"; '
                'state_finish_file "$HOME/new"'
            )
        self.uninstall()
        self.assertFalse((self.home / "new").exists())

    def test_ambiguous_legacy_records_are_not_destroyed(self):
        state_dir = self.home / "data/dotfiles-state"
        backups = state_dir / "backups"
        backups.mkdir(parents=True)
        (backups / "original").write_text("legacy original")
        path = self.home / "legacy"
        path.symlink_to(REPO / "zshrc")
        manifest = state_dir / "manifest"
        manifest.write_text(
            f"SYMLINK_OVER_FILE|old|{path}|original\n"
            f"SYMLINK|new|{path}|{REPO}/zshrc\n"
        )
        self.uninstall()
        self.assertTrue(path.is_symlink())
        self.assertEqual((backups / "original").read_text(), "legacy original")
        self.assertIn("SYMLINK_OVER_FILE", manifest.read_text())

    def test_missing_legacy_link_restores_its_backup(self):
        state_dir = self.home / "data/dotfiles-state"
        backups = state_dir / "backups"
        backups.mkdir(parents=True)
        (backups / "original").write_text("legacy original")
        path = self.home / "legacy"
        (state_dir / "manifest").write_text(
            f"SYMLINK_OVER_FILE|old|{path}|original\n"
        )
        self.uninstall()
        self.assertEqual(path.read_text(), "legacy original")

    def test_skill_conflict_is_retained_outside_disposable_state(self):
        fake_repo = self.home / "repo"
        canonical = fake_repo / "agents/skills/demo"
        canonical.mkdir(parents=True)
        (canonical / "SKILL.md").write_text("canonical")
        library = fake_repo / "scripts/lib"
        library.mkdir(parents=True)
        (library / "state.sh").write_text((REPO / "scripts/lib/state.sh").read_text())
        (library / "defaults.sh").write_text((REPO / "scripts/lib/defaults.sh").read_text())
        target = self.home / ".pi/agent/skills/demo"
        target.mkdir(parents=True)
        (target / "SKILL.md").write_text("custom")
        self.env["DOTFILES_DIR"] = str(fake_repo)
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh"),
                      "--absorb"])
        self.uninstall()
        conflicts = list((self.home / "data/dotfiles-conflicts").rglob("SKILL.md"))
        self.assertEqual([path.read_text() for path in conflicts], ["custom"])
        self.assertEqual((target / "SKILL.md").read_text(), "custom")

    def test_skill_reconciliation_can_update_symlinked_settings_safely(self):
        fake_repo = self.home / "repo"
        (fake_repo / "agents/skills").mkdir(parents=True)
        library = fake_repo / "scripts/lib"
        library.mkdir(parents=True)
        for name in ("state.sh", "defaults.sh"):
            (library / name).write_text((REPO / "scripts/lib" / name).read_text())
        directory = fake_repo / "pi/agent"
        directory.mkdir(parents=True)
        original = self.home / "original-settings.json"
        original.write_text('{"skills":[]}\n')
        settings = directory / "settings.json"
        settings.symlink_to(original)
        self.env["DOTFILES_DIR"] = str(fake_repo)
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh")])
        self.assertIn("!**/.agents/skills/**", settings.read_text())
        self.assertEqual(original.read_text(), '{"skills":[]}\n')
        self.uninstall()
        self.assertTrue(settings.is_symlink())

    def skill_repo(self):
        repo = self.home / "repo"
        (repo / "agents/skills/demo").mkdir(parents=True)
        (repo / "agents/skills/demo/SKILL.md").write_text("canonical")
        library = repo / "scripts/lib"
        library.mkdir(parents=True)
        for name in ("state.sh", "defaults.sh"):
            (library / name).write_text((REPO / "scripts/lib" / name).read_text())
        self.env["DOTFILES_DIR"] = str(repo)
        return repo

    def test_matching_and_unique_skills_restore_after_repeated_setup(self):
        repo = self.skill_repo()
        directory = self.home / ".pi/agent/skills"
        for name in ("demo", "unique"):
            target = directory / name
            target.mkdir(parents=True)
            (target / "SKILL.md").write_text("canonical")
        for _ in range(2):
            self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh"),
                          "--absorb"])
        self.uninstall()
        for name in ("demo", "unique"):
            self.assertFalse((directory / name).is_symlink())
            self.assertEqual((directory / name / "SKILL.md").read_text(), "canonical")
        self.assertTrue((repo / "agents/skills/unique/SKILL.md").exists())

    def test_whole_directory_skill_link_is_restored(self):
        repo = self.skill_repo()
        directory = self.home / ".pi/agent/skills"
        directory.parent.mkdir(parents=True)
        directory.symlink_to(repo / "agents/skills")
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh")])
        self.assertFalse(directory.is_symlink())
        self.uninstall()
        self.assertTrue(directory.is_symlink())
        self.assertEqual(directory.resolve(), (repo / "agents/skills").resolve())

    def test_replaced_skill_directory_preserves_new_user_entries(self):
        repo = self.skill_repo()
        directory = self.home / ".pi/agent/skills"
        directory.parent.mkdir(parents=True)
        directory.symlink_to(repo / "agents/skills")
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh")])
        (directory / ".user-state").write_text("keep")
        self.uninstall()
        self.assertFalse(directory.is_symlink())
        self.assertEqual((directory / ".user-state").read_text(), "keep")
        (directory / ".user-state").unlink()
        self.uninstall()
        self.assertTrue(directory.is_symlink())

    def test_skill_dry_run_creates_no_state_or_tool_directories(self):
        repo = self.skill_repo()
        before = sorted(str(p.relative_to(self.home)) for p in self.home.rglob("*"))
        self.command([
            "/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh"), "--dry-run",
        ])
        after = sorted(str(p.relative_to(self.home)) for p in self.home.rglob("*"))
        self.assertEqual(after, before)
        self.assertFalse((repo / "agents/prompts").exists())

    def conflicts(self):
        root = self.home / "data/dotfiles-conflicts/setup"
        return sorted(p for p in root.rglob("*") if p.is_file()) if root.exists() else []

    def test_rerun_moves_aside_directory_that_replaced_a_link(self):
        link = 'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-dir"'
        self.state(link)
        path = self.home / "config-dir"
        path.unlink()
        path.mkdir()
        (path / "precious.lua").write_text("mine")
        self.state(link)
        self.assertTrue(path.is_symlink())
        [saved] = self.conflicts()
        self.assertEqual(saved.name, "precious.lua")
        self.assertEqual(saved.read_text(), "mine")
        # The pre-dotfiles baseline is still what uninstall restores.
        self.uninstall()
        self.assertFalse(path.exists())

    def test_rerun_over_own_link_sets_nothing_aside(self):
        link = 'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"'
        self.state(link)
        self.state(link)
        self.assertEqual(self.conflicts(), [])

    def test_first_run_backs_up_instead_of_setting_aside(self):
        path = self.home / "config-file"
        path.write_text("baseline")
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        self.assertEqual(self.conflicts(), [])
        self.uninstall()
        self.assertEqual(path.read_text(), "baseline")

    def test_rerun_moves_aside_recreated_deleted_file(self):
        path = self.home / ".gitconfig"
        path.write_text("baseline")
        delete = 'state_delete_file "$HOME/.gitconfig"'
        self.state(delete)
        path.write_text("written by a tool")
        self.state(delete)
        self.assertFalse(path.exists())
        [saved] = self.conflicts()
        self.assertEqual(saved.read_text(), "written by a tool")

    def test_backslash_paths_are_tracked_and_restored(self):
        path = self.home / "odd\\name"
        path.write_text("baseline")
        link = 'state_symlink "$DOTFILES_DIR/zshrc" "$HOME/odd\\\\name"'
        self.state(link)
        self.state(link)
        manifest = (self.home / "data/dotfiles-state/manifest").read_text()
        self.assertEqual(manifest.count("ORIGINAL|"), 1)
        self.uninstall()
        self.assertEqual(path.read_text(), "baseline")

    def test_pipe_in_path_is_refused(self):
        result = self.command([
            "/bin/bash", "-c",
            f'log_warning() {{ echo "$1"; }}; source "{REPO}/scripts/lib/state.sh"; '
            'state_init; state_record MANAGED "$HOME/a|b" x',
        ], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not supported", result.stdout)
        manifest = (self.home / "data/dotfiles-state/manifest").read_text()
        self.assertNotIn("a|b", manifest)

    def test_unreadable_file_has_no_hash(self):
        path = self.home / "secret"
        path.write_text("x")
        path.chmod(0)
        result = self.command([
            "/bin/bash", "-c",
            f'source "{REPO}/scripts/lib/state.sh"; _state_file_hash "$HOME/secret"',
        ], check=False)
        path.chmod(0o600)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_orphaned_original_is_restored(self):
        # Setup killed after recording the baseline, before its MANAGED record.
        path = self.home / "config-file"
        path.write_text("baseline")
        self.state('_state_capture_original "$HOME/config-file"; rm "$HOME/config-file"; '
                   'ln -s "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        self.uninstall()
        self.assertEqual(path.read_text(), "baseline")
        self.assertFalse((self.home / "data/dotfiles-state").exists())

    def test_busy_xdg_base_directory_does_not_block_cleanup(self):
        self.state('state_mkdir "$XDG_CONFIG_HOME/zsh"')
        (self.home / "config/other-app").mkdir()
        self.uninstall()
        self.assertTrue((self.home / "config/other-app").is_dir())
        self.assertFalse((self.home / "config/zsh").exists())
        self.assertFalse((self.home / "data/dotfiles-state").exists())

    def test_failed_manifest_rewrite_keeps_manifest(self):
        self.state('state_symlink "$DOTFILES_DIR/zshrc" "$HOME/config-file"')
        manifest = self.home / "data/dotfiles-state/manifest"
        before = manifest.read_text()
        self.mock("awk", "exit 1\n")
        result = self.command([
            "/bin/bash", "-ec",
            f'log_warning() {{ :; }}; source "{REPO}/scripts/lib/state.sh"; '
            'state_record MANAGED "$HOME/config-file" changed || exit 3',
        ], check=False)
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(manifest.read_text(), before)
        self.assertEqual(list(manifest.parent.glob("manifest.*")), [])


if __name__ == "__main__":
    unittest.main()
