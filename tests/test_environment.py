"""Shell environment behavior with home-directory writes sandboxed."""

import shutil

from test_rollback import REPO, Sandbox


class EnvironmentTests(Sandbox):
    def setUp(self):
        super().setUp()
        for name in ("AWS_CONFIG_FILE", "AWS_SHARED_CREDENTIALS_FILE"):
            self.env.pop(name, None)

    def shell(self, command):
        self.env["HOMEBREW_PREFIX"] = "/fixture"
        # zshenv's runtime directory is system-wide; do not create/chmod it.
        return self.command([
            "/bin/zsh", "-dfc",
            'mkdir() { [[ "$1" == "-p" ]] && shift; '
            'case "$1" in "$HOME"/*) command mkdir -p "$1";; *) return 0;; esac; }; '
            'chmod() { :; }; source "$DOTFILES_DIR/zshenv"; ' + command,
        ])

    def test_shell_does_not_force_web_identity(self):
        self.env.pop("AWS_WEB_IDENTITY_TOKEN_FILE", None)
        result = self.shell('print -r -- "${AWS_WEB_IDENTITY_TOKEN_FILE-unset}"')
        self.assertEqual(result.stdout.strip(), "unset")

    def test_explicit_web_identity_environment_is_preserved(self):
        self.env["AWS_WEB_IDENTITY_TOKEN_FILE"] = "/explicit/project/token"
        result = self.shell('print -r -- "$AWS_WEB_IDENTITY_TOKEN_FILE"')
        self.assertEqual(result.stdout.strip(), "/explicit/project/token")

    def test_normal_aws_credentials_are_selected_when_cli_is_available(self):
        aws = shutil.which("aws")
        if not aws:
            self.skipTest("AWS CLI not installed")
        directory = self.home / ".config/aws"
        directory.mkdir(parents=True)
        (directory / "credentials").write_text(
            "[default]\naws_access_key_id=fixture\naws_secret_access_key=fixture\n"
        )
        for name in ("AWS_WEB_IDENTITY_TOKEN_FILE", "AWS_ROLE_ARN", "AWS_PROFILE",
                     "AWS_DEFAULT_PROFILE", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
                     "AWS_SESSION_TOKEN"):
            self.env.pop(name, None)
        self.env["AWS_EC2_METADATA_DISABLED"] = "true"
        result = self.shell(f'"{aws}" configure list')
        self.assertIn("shared-credentials-file", result.stdout)

    def test_legacy_aws_paths_remain_available_until_migrated(self):
        directory = self.home / ".aws"
        directory.mkdir()
        for name in ("credentials", "config"):
            (directory / name).write_text("fixture")
        result = self.shell(
            'print -r -- "$AWS_SHARED_CREDENTIALS_FILE"; print -r -- "$AWS_CONFIG_FILE"'
        )
        self.assertEqual(result.stdout.splitlines(),
                         [str(directory / "credentials"), str(directory / "config")])

    def test_explicit_aws_paths_are_preserved(self):
        self.env["AWS_CONFIG_FILE"] = "/explicit/config"
        self.env["AWS_SHARED_CREDENTIALS_FILE"] = "/explicit/credentials"
        result = self.shell(
            'print -r -- "$AWS_SHARED_CREDENTIALS_FILE"; print -r -- "$AWS_CONFIG_FILE"'
        )
        self.assertEqual(result.stdout.splitlines(),
                         ["/explicit/credentials", "/explicit/config"])

    def test_history_reload_updates_current_shell(self):
        source = (REPO / "zshrc").read_text()
        block = source.split("reload_shared_history() {", 1)[1].split(
            "# History search functions", 1
        )[0]
        history = self.home / "history"
        self.command([
            "/bin/zsh", "-dfc",
            'autoload -Uz add-zsh-hook; '
            f'export HISTFILE="{history}"; HISTSIZE=1000; SAVEHIST=1000; '
            "reload_shared_history() {" + block +
            'print -r -- "echo shared-marker" > "$HISTFILE"; '
            'reload_shared_history; fc -l -1',
        ])
        result = self.command([
            "/bin/zsh", "-dfc",
            'autoload -Uz add-zsh-hook; '
            f'export HISTFILE="{history}"; HISTSIZE=1000; SAVEHIST=1000; '
            "reload_shared_history() {" + block +
            'reload_shared_history; fc -l -1',
        ])
        self.assertIn("shared-marker", result.stdout)

    def setup_prefix(self):
        setup = (REPO / "setup.sh").read_text().split("# --- Setup steps ---", 1)[0]
        # Exercise the real filesystem setup prefix, excluding chmod of repo scripts.
        setup = setup.split("# --- Make scripts executable ---", 1)[0] + (
            setup.split("# --- XDG directories ---", 1)[1]
        )
        return self.command(["/bin/bash", "-ec", setup])

    def test_setup_keeps_hosts_other_tools_add_to_ssh_config(self):
        self.setup_prefix()
        config = self.home / ".ssh/config"
        with config.open("a") as f:
            f.write("\nHost gcp-vm\n  HostName 10.0.0.5\n")
        self.setup_prefix()
        text = config.read_text()
        self.assertIn("Host gcp-vm", text)
        self.assertEqual(text.count("Include ~/.config/ssh/config"), 1)

    def test_setup_puts_include_ahead_of_existing_ssh_hosts(self):
        ssh = self.home / ".ssh"
        ssh.mkdir()
        (ssh / "config").write_text("Host old\n  HostName 10.0.0.9\n")
        self.setup_prefix()
        lines = (ssh / "config").read_text().splitlines()
        include = lines.index("Include ~/.config/ssh/config")
        self.assertLess(include, lines.index("Host old"))
        self.assertEqual(oct((ssh / "config").stat().st_mode & 0o777), "0o600")
        self.uninstall()
        self.assertEqual((ssh / "config").read_text(), "Host old\n  HostName 10.0.0.9\n")

    def test_provider_wrappers_see_only_their_own_key(self):
        self.env.update(KIMI_API_KEY="kimi-secret", OPENAI_API_KEY="o",
                        OPENAI_ADMIN_KEY="a", LINEAR_API_KEY="l",
                        ANTHROPIC_API_KEY="real")
        for wrapper in ("kimi", "zai", "dseek", "ccc", "ccmm"):
            result = self.command([
                "/bin/zsh", "-dfc",
                f'source "{REPO}/claude.source"; claude() {{ env; }}; {wrapper}',
            ])
            names = (line.split("=", 1)[0] for line in result.stdout.splitlines())
            keys = [n for n in names if n.endswith(("_API_KEY", "_ADMIN_KEY"))]
            self.assertEqual(keys, [], wrapper)
            self.assertIn("ANTHROPIC_AUTH_TOKEN=", result.stdout)
        kimi = self.command(["/bin/zsh", "-dfc",
                             f'source "{REPO}/claude.source"; claude() {{ env; }}; kimi'])
        self.assertIn("ANTHROPIC_AUTH_TOKEN=kimi-secret", kimi.stdout)

    def test_sops_diff_decrypts_only_in_opted_in_repos(self):
        self.setup_prefix()
        canary = self.home / "sops-ran"
        self.mock("sops", f'touch "{canary}"; sed s/ciphertext/decrypted/ "$2"\n')
        repo = self.home / "cloned"
        repo.mkdir()
        git = ["git", "-C", str(repo), "-c", "commit.gpgsign=false"]
        self.command(git + ["init", "-q"])
        # What a hostile repo ships to reach the global sopsdiffer driver.
        (repo / ".gitattributes").write_text("*.enc diff=sopsdiffer\n")
        (repo / "secret.enc").write_text("ciphertext v1\n")
        self.command(git + ["add", "."])
        self.command(git + ["-c", "user.name=t", "-c", "user.email=t@t",
                            "commit", "-qm", "init"])
        (repo / "secret.enc").write_text("ciphertext v2\n")
        diff = self.command(git + ["diff"]).stdout
        self.assertFalse(canary.exists())
        self.assertIn("ciphertext v2", diff)
        self.command(git + ["config", "sops.diff", "true"])
        self.assertIn("+decrypted v2", self.command(git + ["diff"]).stdout)
        self.assertTrue(canary.exists())

    def test_setup_prompt_link_matches_shell_source_path(self):
        self.setup_prefix()
        source = (REPO / "zshrc").read_text()
        line = next(line for line in source.splitlines()
                    if line.startswith("[[ ! -f ") and ".p10k.zsh" in line)
        result = self.command([
            "/bin/zsh", "-dfc",
            f'XDG_CONFIG_HOME="{self.home / "config"}"; '
            'source() { print -r -- "$1"; }; ' + line,
        ])
        self.assertEqual(result.stdout.strip(),
                         str(self.home / "config/zsh/.p10k.zsh"))
