"""Standalone setup entry points run against temporary homes and CLI mocks."""

import json
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

    def test_omz_install_keeps_managed_zshrc_and_fixed_path(self):
        # Mirrors the real installer: ZDOTDIR moves the install and the zshrc
        # is replaced unless KEEP_ZSHRC=yes; --unattended must reach it.
        self.mock("curl", "cat <<'EOF'\n"
                  'ZSH="${ZSH:-${ZDOTDIR:+$ZDOTDIR/ohmyzsh}}"; ZSH="${ZSH:-$HOME/.oh-my-zsh}"\n'
                  'mkdir -p "$ZSH"\n'
                  'zrc="${ZDOTDIR:-$HOME}/.zshrc"\n'
                  '[ "$KEEP_ZSHRC" = yes ] || { mv "$zrc" "$zrc.pre-oh-my-zsh"; echo template > "$zrc"; }\n'
                  'echo "$@" > "$HOME/omz-args"\n'
                  "EOF\n")
        self.mock("brew", "exit 0\n")
        zdotdir = self.home / "config/zsh"
        zdotdir.mkdir(parents=True)
        (zdotdir / ".zshrc").write_text("managed")
        self.env["ZDOTDIR"] = str(zdotdir)
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_zsh.sh")])
        self.assertTrue((self.home / ".oh-my-zsh").is_dir())
        self.assertFalse((zdotdir / "ohmyzsh").exists())
        self.assertEqual((zdotdir / ".zshrc").read_text(), "managed")
        self.assertIn("--unattended", (self.home / "omz-args").read_text())

    def test_failed_step_does_not_stop_the_remaining_setup(self):
        # Run the real setup.sh on a copy of the repo with every CLI it calls
        # mocked; brew bundle fails the way a refused mas install does.
        repo = self.home / "repo"
        shutil.copytree(REPO, repo, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        self.env["DOTFILES_DIR"] = str(repo)
        self.mock("brew", 'case "$1" in bundle) exit 1;; esac; exit 0\n')
        self.mock("gh", 'case "$1" in config) mkdir -p "$XDG_CONFIG_HOME/gh"; '
                  'echo "$3: $4" >> "$XDG_CONFIG_HOME/gh/config.yml";; esac; exit 0\n')
        self.mock("mise", 'case "$1" in ls) echo "{}";; version) echo 2026.9.0;; esac; exit 0\n')
        self.mock("curl", "printf '%s\\n' 'mkdir -p \"$HOME/.oh-my-zsh\"'\n")
        self.mock("defaults", 'case "$1" in export) echo "<plist><dict/></plist>";; esac; exit 0\n')
        self.mock("ssh-keygen", "exit 1\n")
        nvim_log = self.home / "nvim-calls"
        self.mock("nvim", f'echo "$*" >> "{nvim_log}"\n')
        # Homebrew: install packages (fails); macOS defaults: no; new key: no.
        result = self.command(["/bin/bash", str(repo / "setup.sh")],
                              input="y\nn\nn\n", check=False)
        out = result.stdout + result.stderr
        self.assertEqual(result.returncode, 1, out)
        self.assertIn("Setting up Homebrew packages failed; continuing.", out)
        self.assertIn("failed step(s):\n  - Setting up Homebrew packages", out)
        self.assertEqual(out.count("failed; continuing."), 1, out)
        # Steps after the failure still ran.
        self.assertTrue((self.home / ".oh-my-zsh").is_dir())
        self.assertTrue((self.home / "config/nvim").is_symlink())
        self.assertTrue((self.home / ".pi/agent/settings.json").is_symlink())
        self.assertIn("commits will fail until it does", out)
        # A fresh machine restores plugins from the lockfile, blocking.
        self.assertIn("Lazy! restore", nvim_log.read_text())

    def test_missing_signing_key_is_created_only_on_request(self):
        git = self.home / "config/git"
        git.mkdir(parents=True)
        (git / "config").write_text(
            "[user]\n  email = me@example.com\n  signingkey = ~/.ssh/id_ed25519\n")
        self.mock("ssh-keygen", 'while [[ $1 != -f ]]; do shift; done\n'
                  'echo private > "$2"; echo "ssh-ed25519 AAAA me" > "$2.pub"\n')
        script = ["/bin/bash", str(REPO / "scripts/ssh/manage_ssh_keys.sh"), "signing-key"]
        key = self.home / ".ssh/id_ed25519"
        declined = self.command(script, input="n\n")
        self.assertIn("commits will fail until it does", declined.stdout)
        self.assertFalse(key.exists())
        accepted = self.command(script, input="y\n")
        self.assertTrue(key.exists())
        self.assertIn("gh ssh-key add", accepted.stdout)
        again = self.command(script)
        self.assertIn("Git signing key present", again.stdout)

    def ssh_dir(self):
        ssh = self.home / ".ssh"
        ssh.mkdir()
        for name in ("id_ed25519", "id_ed25519_gatx"):
            (ssh / name).write_text("private")
            (ssh / name).chmod(0o644)
            (ssh / f"{name}.pub").write_text("ssh-ed25519 AAAA")
        (ssh / "config").write_text("Include ~/.config/ssh/config\n")
        (ssh / "config").chmod(0o644)
        return ssh

    def test_ssh_key_permissions_cover_every_key_and_the_config(self):
        ssh = self.ssh_dir()
        self.command(["/bin/bash", str(REPO / "scripts/ssh/manage_ssh_keys.sh"),
                      "fix-permissions"])
        for name in ("id_ed25519", "id_ed25519_gatx", "config"):
            self.assertEqual(oct((ssh / name).stat().st_mode & 0o777), "0o600", name)

    def test_failed_passphrase_change_leaves_no_unencrypted_copy(self):
        ssh = self.ssh_dir()
        self.mock("ssh-keygen", "exit 1\n")
        result = self.command(["/bin/bash", str(REPO / "scripts/ssh/manage_ssh_keys.sh"),
                               "add-passphrase", "id_ed25519_gatx"], check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((ssh / "id_ed25519_gatx.bak").exists())
        self.assertEqual((ssh / "id_ed25519_gatx").read_text(), "private")

    def test_zsh_check_only_does_not_initialize_state(self):
        (self.home / ".oh-my-zsh").mkdir()
        self.mock("brew", "exit 0\n")
        self.command([
            "/bin/bash", str(REPO / "scripts/setup/setup_zsh.sh"), "--check-only",
        ])
        self.assertFalse((self.home / "data").exists())

    def github_setup(self):
        self.env["GH_CONFIG_DIR"] = str(self.home / "gh")
        config = self.home / "gh/config.yml"
        self.mock("brew", 'case "$1" in list) exit 0;; *) exit 0;; esac\n')
        self.mock("gh", f"""exec python3 - "$@" <<'PY'
import json, pathlib, sys
path = pathlib.Path({str(config)!r})
args = sys.argv[1:]
if args[0] == '--version':
    print('gh fixture')
elif args[0] == 'config':
    data = json.loads(path.read_text()) if path.exists() and path.read_text().strip() else {{}}
    data[args[2]] = args[3]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data))
elif args[0] != 'auth':
    raise RuntimeError(args)
PY
""")
        return config

    def test_github_config_restores_existing_values(self):
        config = self.github_setup()
        config.parent.mkdir()
        original = '{"editor":"original","pager":"less","other":"keep"}'
        config.write_text(original)
        for _ in range(2):
            self.command(["/bin/bash", str(REPO / "scripts/setup/setup_github.sh")])
        self.assertEqual(json.loads(config.read_text())["pager"], "")
        self.uninstall()
        self.assertEqual(config.read_text(), original)

    def test_github_config_removes_created_file_but_preserves_user_edits(self):
        config = self.github_setup()
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_github.sh")])
        config.write_text('{"editor":"user replacement"}')
        self.uninstall()
        self.assertEqual(json.loads(config.read_text())["editor"], "user replacement")
        config.unlink()
        self.uninstall()
        self.assertFalse(config.exists())

    def test_github_config_detaches_and_restores_original_symlink(self):
        config = self.github_setup()
        config.parent.mkdir()
        target = self.home / "original-gh-config"
        target.write_text('{"editor":"original"}')
        config.symlink_to(target)
        self.command(["/bin/bash", str(REPO / "scripts/setup/setup_github.sh")])
        self.assertEqual(target.read_text(), '{"editor":"original"}')
        self.uninstall()
        self.assertTrue(config.is_symlink())
