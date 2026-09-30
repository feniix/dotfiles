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


    def test_setup_prompt_link_matches_shell_source_path(self):
        setup = (REPO / "setup.sh").read_text().split("# --- Homebrew", 1)[0]
        # Exercise the real filesystem setup prefix, excluding chmod of repo scripts.
        setup = setup.split("# --- Make scripts executable ---", 1)[0] + (
            setup.split("# --- XDG directories ---", 1)[1]
        )
        self.command(["/bin/bash", "-ec", setup])
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
