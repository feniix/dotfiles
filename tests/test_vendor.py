"""Skill source selection and ownership are tested without network access."""

import shutil
import subprocess

from test_rollback import REPO, Sandbox


# mattpocock/skills v1.2.3 skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh
UPSTREAM_GUARDRAIL_HOOK = r'''#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
'''


class VendorTests(Sandbox):
    def setUp(self):
        super().setUp()
        self.bash = shutil.which("bash")
        result = self.command([self.bash, "-c", "echo ${BASH_VERSINFO[0]}"])
        if int(result.stdout) < 4:
            self.skipTest("bash 4+ required for skill vendoring")
        self.repo = self.home / "repo"
        self.dest = self.repo / "agents/skills"
        self.dest.mkdir(parents=True)
        self.manifest = self.repo / "agents/skills.vendor"
        self.lock = self.repo / "agents/skills.lock"
        self.manifest.write_text(
            "source fixture https://fixture.invalid/repo main\n"
            "skill fixture skills/*\n"
        )
        self.original_lock = (
            "fixture oldsha https://fixture.invalid/repo\nvendored fixture demo\n"
        )
        self.lock.write_text(self.original_lock)
        (self.dest / "demo").mkdir()
        (self.dest / "demo/SKILL.md").write_text("previous owned skill")
        self.cache = self.home / "cache/dotfiles-vendor-skills/fixture"
        (self.cache / ".git").mkdir(parents=True)
        self.env["DOTFILES_DIR"] = str(self.repo)
        self.mock("git", 'case "$*" in *rev-parse*) echo newsha;; esac\n')

    def vendor(self, *args, check=True):
        return self.command(
            [self.bash, str(REPO / "scripts/agents/vendor_skills.sh"), *args],
            check=check,
        )

    def test_zero_matches_fail_without_losing_lock_or_owned_skills(self):
        result = self.vendor(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.lock.read_text(), self.original_lock)
        self.assertTrue((self.dest / "demo/SKILL.md").exists())

    def test_failed_fetch_preserves_lock_and_owned_skills(self):
        self.mock("git", 'case "$*" in *fetch*) exit 1;; *rev-parse*) echo newsha;; esac\n')
        result = self.vendor(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.lock.read_text(), self.original_lock)
        self.assertTrue((self.dest / "demo/SKILL.md").exists())

    def test_explicit_empty_selection_removes_owned_skills(self):
        self.manifest.write_text("source fixture https://fixture.invalid/repo main\n")
        self.vendor()
        self.assertFalse((self.dest / "demo").exists())
        self.assertNotIn("vendored fixture demo", self.lock.read_text())

    def test_skipping_all_matches_is_an_intentional_empty_result(self):
        skill = self.cache / "skills/demo"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("upstream")
        with self.manifest.open("a") as file:
            file.write("skip fixture demo\n")
        self.vendor()
        self.assertFalse((self.dest / "demo").exists())


class UpstreamVendorTests(Sandbox):
    """Runs vendor_skills.sh against real local git repos standing in for upstreams."""

    def setUp(self):
        super().setUp()
        self.bash = shutil.which("bash")
        result = self.command([self.bash, "-c", "echo ${BASH_VERSINFO[0]}"])
        if int(result.stdout) < 4:
            self.skipTest("bash 4+ required for skill vendoring")
        self.repo = self.home / "repo"
        self.dest = self.repo / "agents/skills"
        self.dest.mkdir(parents=True)
        self.manifest = self.repo / "agents/skills.vendor"
        self.lock = self.repo / "agents/skills.lock"
        self.env["DOTFILES_DIR"] = str(self.repo)
        self.upstreams = {}

    def git(self, cwd, *args):
        result = subprocess.run(
            ["git", "-c", "user.name=t", "-c", "user.email=t@example.invalid",
             "-c", "commit.gpgsign=false", "-c", "init.defaultBranch=main", *args],
            cwd=cwd, env=self.env, text=True, capture_output=True, check=True,
        )
        return result.stdout.strip()

    def upstream(self, name, files):
        """Create upstream <name>, or add a commit to it; files maps path -> text."""
        root = self.home / "upstream" / name
        if name not in self.upstreams:
            root.mkdir(parents=True)
            self.git(root, "init", "-q")
            self.upstreams[name] = root
        for path, text in files.items():
            target = root / path
            if not path.endswith((".md", ".sh")):
                target = target / "SKILL.md"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
        self.git(root, "add", "-A")
        self.git(root, "commit", "-q", "-m", "update")
        return self.git(root, "rev-parse", "HEAD")

    def vendor(self, *args, check=True, cwd=None):
        result = subprocess.run(
            [self.bash, str(REPO / "scripts/agents/vendor_skills.sh"), *args],
            cwd=cwd or self.home, env=self.env, text=True,
            capture_output=True, timeout=60,
        )
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def lock_sha(self, source):
        for line in self.lock.read_text().splitlines():
            parts = line.split()
            if parts and parts[0] == source:
                return parts[1]
        return None

    def test_globs_expand_against_the_clone_not_the_cwd(self):
        self.upstream("up", {
            "skills/engineering/only": "only",
            "skills/engineering/alpha": "alpha",
            "skills/engineering/beta": "beta",
        })
        self.manifest.write_text(
            f"source up {self.upstreams['up']} main\n"
            "skill  up skills/engineering/*\n"
        )
        decoy = self.home / "cwd"
        (decoy / "skills/engineering/only").mkdir(parents=True)
        self.vendor(cwd=decoy)
        for name in ("only", "alpha", "beta"):
            self.assertTrue((self.dest / name / "SKILL.md").exists(), name)

    def pinned_fixture(self):
        first = self.upstream("up", {"skills/a": "a v1", "skills/b": "b v1"})
        self.manifest.write_text(
            f"source up {self.upstreams['up']} main\nskill  up skills/*\n"
        )
        self.vendor()
        self.assertEqual(self.lock_sha("up"), first)
        second = self.upstream("up", {"skills/a": "a v2", "skills/b": "b v2"})
        return first, second

    def test_rerun_without_update_keeps_the_pinned_commit(self):
        first, _ = self.pinned_fixture()
        with self.manifest.open("a") as file:
            file.write("skip up b\n")
        self.vendor()
        self.assertEqual(self.lock_sha("up"), first)
        self.assertEqual((self.dest / "a/SKILL.md").read_text(), "a v1")
        self.assertFalse((self.dest / "b").exists())

    def test_update_moves_the_pin(self):
        _, second = self.pinned_fixture()
        self.vendor("--update")
        self.assertEqual(self.lock_sha("up"), second)
        self.assertEqual((self.dest / "a/SKILL.md").read_text(), "a v2")

    def test_update_with_an_id_moves_only_that_source(self):
        first, second = self.pinned_fixture()
        other = self.upstream("other", {"skills/c": "c v1"})
        with self.manifest.open("a") as file:
            file.write(f"source other {self.upstreams['other']} main\n"
                       "skill  other skills/*\n")
        self.vendor()  # no lock entry yet: resolves its ref
        self.assertEqual(self.lock_sha("other"), other)
        self.assertEqual(self.lock_sha("up"), first)
        self.upstream("other", {"skills/c": "c v2"})
        self.vendor("--update", "up")
        self.assertEqual(self.lock_sha("up"), second)
        self.assertEqual(self.lock_sha("other"), other)
        self.assertEqual((self.dest / "c/SKILL.md").read_text(), "c v1")

    def test_vendored_skill_never_overwrites_a_first_party_skill(self):
        mine = self.dest / "a"
        mine.mkdir()
        (mine / "SKILL.md").write_text("first-party")
        (mine / "notes.txt").write_text("keep me")
        self.upstream("up", {"skills/a": "upstream a", "skills/b": "upstream b"})
        self.manifest.write_text(
            f"source up {self.upstreams['up']} main\nskill  up skills/*\n"
        )
        result = self.vendor(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("up wants", result.stderr)
        self.assertIn("first-party", result.stderr)
        self.assertEqual((mine / "SKILL.md").read_text(), "first-party")
        self.assertEqual((mine / "notes.txt").read_text(), "keep me")
        self.assertEqual((self.dest / "b/SKILL.md").read_text(), "upstream b")
        self.assertIn("vendored up b", self.lock.read_text())
        self.assertNotIn("vendored up a", self.lock.read_text())

    def test_vendored_skill_never_overwrites_another_sources_skill(self):
        self.upstream("one", {"skills/shared": "from one"})
        self.manifest.write_text(
            f"source one {self.upstreams['one']} main\nskill  one skills/*\n"
        )
        self.vendor()
        self.upstream("two", {"skills/shared": "from two", "skills/extra": "extra"})
        with self.manifest.open("a") as file:
            file.write(f"source two {self.upstreams['two']} main\n"
                       "skill  two skills/*\n")
        result = self.vendor(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("two wants", result.stderr)
        self.assertIn("source one", result.stderr)
        self.assertEqual((self.dest / "shared/SKILL.md").read_text(), "from one")
        self.assertEqual((self.dest / "extra/SKILL.md").read_text(), "extra")
        lock = self.lock.read_text()
        self.assertIn("vendored one shared", lock)
        self.assertNotIn("vendored two shared", lock)

    def test_git_guardrails_hook_is_patched_on_every_vendor_run(self):
        hook = "skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh"
        self.upstream("mattpocock", {
            "skills/misc/git-guardrails-claude-code": "guardrails",
            hook: UPSTREAM_GUARDRAIL_HOOK,
        })
        self.manifest.write_text(
            f"source mattpocock {self.upstreams['mattpocock']} main\n"
            "skill  mattpocock skills/misc/*\n"
        )
        result = self.vendor()
        self.assertIn("patch", result.stdout)
        self.assertNotIn("upstream block-dangerous-git.sh changed", result.stdout)
        patched = self.dest / "git-guardrails-claude-code/scripts/block-dangerous-git.sh"
        repo_copy = REPO / "agents/skills/git-guardrails-claude-code/scripts/block-dangerous-git.sh"
        self.assertEqual(patched.read_text(), repo_copy.read_text())
        self.assertTrue(patched.stat().st_mode & 0o111)

    def test_frozen_refuses_a_source_without_a_pin(self):
        self.upstream("up", {"skills/a": "a v1"})
        self.manifest.write_text(
            f"source up {self.upstreams['up']} main\nskill  up skills/*\n"
        )
        result = self.vendor("--frozen", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.dest / "a").exists())

    def test_update_follows_a_tag_the_upstream_moved(self):
        first = self.upstream("up", {"skills/a": "a v1"})
        self.git(self.upstreams["up"], "tag", "v1")
        self.manifest.write_text(
            f"source up {self.upstreams['up']} v1\nskill  up skills/*\n"
        )
        self.vendor()
        self.assertEqual(self.lock_sha("up"), first)
        second = self.upstream("up", {"skills/a": "a v2"})
        self.git(self.upstreams["up"], "tag", "-f", "v1")
        self.vendor("--update")
        self.assertEqual(self.lock_sha("up"), second)
        self.assertEqual((self.dest / "a/SKILL.md").read_text(), "a v2")

    def test_rename_treats_the_old_name_literally_and_only_rewrites_docs(self):
        self.upstream("up", {
            "skills/a.b": "---\nname: a.b\n---\nUse /a.b, not /axb or `axb`.\n",
            "skills/axb": "---\nname: axb\n---\nSee `a.b`.\n",
            "skills/a.b/run.sh": "echo /a.b\n",
        })
        self.manifest.write_text(
            f"source up {self.upstreams['up']} main\nskill  up skills/*\n"
            "rename up a.b renamed\n"
        )
        self.vendor()
        self.assertEqual(
            (self.dest / "renamed/SKILL.md").read_text(),
            "---\nname: renamed\n---\nUse /renamed, not /axb or `axb`.\n",
        )
        self.assertEqual(
            (self.dest / "axb/SKILL.md").read_text(),
            "---\nname: axb\n---\nSee `renamed`.\n",
        )
        self.assertEqual((self.dest / "renamed/run.sh").read_text(), "echo /a.b\n")
