"""Agent skill tooling: the patched git guardrail hook and setup_agent_skills.sh.

Everything runs in temporary homes; nothing touches the real ~/.claude*,
~/.agents, ~/.codex or ~/.pi.
"""

import json
import shutil
import subprocess
import unittest

from test_rollback import REPO, Sandbox


HOOK = REPO / "agents/skills/git-guardrails-claude-code/scripts/block-dangerous-git.sh"

BLOCKED = [
    "git push",
    "git push origin main --force",
    "git -C . push",
    "git  push",
    "git -c core.editor=vi push",
    "git --git-dir=.git push",
    '"git" push',
    "ls && git push",
    'bash -c "git push"',
    'echo "$(git push)"',
    "git push>/dev/null",
    "git reset --hard HEAD~1",
    "git clean -f",
    "git clean -fd",
    "git clean -xdf",
    "git branch -D topic",
    "git branch -df topic",
    "git branch --delete --force topic",
    "git checkout .",
    "git checkout -- .",
    "git checkout main -- file.txt",
    "git restore .",
]

ALLOWED = [
    'git commit -m "do not git push"',
    "git commit -m 'git reset --hard was a mistake'",
    'gh pr create --title "fix git push docs"',
    "git status",
    "git -C /tmp/repo log --oneline",
    "git clean -n",
    "git clean -xdn",
    "git branch -d topic",
    "git checkout -b feature",
    "git checkout main",
    "git restore --staged file.txt",
    "git reset --soft HEAD~1",
    "git diff -- .",
    "echo hello",
]


class GuardrailHookTests(unittest.TestCase):
    def run_hook(self, stdin, env=None):
        return subprocess.run(
            ["/bin/bash", str(HOOK)], input=stdin, env=env, text=True,
            capture_output=True, timeout=20,
        )

    def hook(self, command):
        return self.run_hook(json.dumps({"tool_input": {"command": command}}))

    def test_dangerous_commands_are_blocked(self):
        if not shutil.which("jq"):
            self.skipTest("jq required")
        for command in BLOCKED:
            with self.subTest(command=command):
                result = self.hook(command)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("BLOCKED", result.stderr)

    def test_safe_commands_and_quoted_mentions_are_allowed(self):
        if not shutil.which("jq"):
            self.skipTest("jq required")
        for command in ALLOWED:
            with self.subTest(command=command):
                result = self.hook(command)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_jq_fails_closed(self):
        result = self.run_hook(
            json.dumps({"tool_input": {"command": "git status"}}),
            env={"PATH": "/nonexistent"},
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("jq", result.stderr)

    def test_unparseable_input_fails_closed(self):
        if not shutil.which("jq"):
            self.skipTest("jq required")
        self.assertEqual(self.run_hook("not json").returncode, 2)
