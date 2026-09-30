"""Skill source selection and ownership are tested without network access."""

import shutil

from test_rollback import REPO, Sandbox


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
