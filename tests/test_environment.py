"""Shell environment behavior with home-directory writes sandboxed."""

import shutil

from test_rollback import REPO, Sandbox


class EnvironmentTests(Sandbox):
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
