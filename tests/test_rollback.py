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
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_agent_skills.sh")])
        self.uninstall()
        conflicts = list((self.home / "data/dotfiles-conflicts").rglob("SKILL.md"))
        self.assertEqual([path.read_text() for path in conflicts], ["custom"])


if __name__ == "__main__":
    unittest.main()
