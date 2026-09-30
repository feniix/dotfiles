"""Standalone setup entry points run against temporary homes and CLI mocks."""

import shutil

from test_rollback import REPO, Sandbox


class SetupTests(Sandbox):
    def fake_repo(self):
        repo = self.home / "repo"
        shutil.copytree(REPO / "scripts/lib", repo / "scripts/lib")
        for name in ("nvim", "pi/agent/agents", "mise"):
            (repo / name).mkdir(parents=True)
        for name in ("pi/agent/settings.json", "pi/agent/models.json"):
            (repo / name).write_text("{}")
        for name in ("pi/agent/AGENTS.md", ".vimrc"):
            (repo / name).write_text("fixture")
        self.env["DOTFILES_DIR"] = str(repo)
        return repo

    def test_standalone_xdg_nvim_and_pi_setup(self):
        repo = self.fake_repo()
        for name in ("xdg", "nvim", "pi"):
            self.command(["/bin/bash", str(REPO / f"scripts/setup/setup_{name}.sh")])
        self.assertEqual((self.home / "config/nvim").resolve(), (repo / "nvim").resolve())
        self.assertEqual((self.home / ".pi/agent/settings.json").resolve(),
                         (repo / "pi/agent/settings.json").resolve())
        self.assertTrue((self.home / "data/dotfiles-state/manifest").exists())
        self.uninstall()
        self.assertFalse((self.home / "config/nvim").exists())
        self.assertFalse((self.home / ".pi/agent/settings.json").exists())

    def test_standalone_zsh_setup_tracks_new_omz_installation(self):
        self.mock("curl", "printf '%s\\n' 'mkdir -p \"$HOME/.oh-my-zsh\"'\n")
        self.mock("brew", "exit 0\n")
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_zsh.sh")])
        self.assertTrue((self.home / ".oh-my-zsh").exists())
        self.uninstall("--software")
        self.assertFalse((self.home / ".oh-my-zsh").exists())

    def test_zsh_check_only_does_not_initialize_state(self):
        (self.home / ".oh-my-zsh").mkdir()
        self.mock("brew", "exit 0\n")
        self.command([
            "/bin/bash", str(REPO / "scripts/setup/setup_zsh.sh"), "--check-only",
        ])
        self.assertFalse((self.home / "data").exists())
