"""macOS defaults are simulated; no live preference writes or sudo calls."""

import json

from test_rollback import REPO, Sandbox


class DefaultsTests(Sandbox):
    def test_standalone_macos_setup(self):
        self.command(
            ["/bin/bash", str(REPO / "scripts/setup/setup_macos.sh")], input="n\n"
        )
        path = self.home / "Library/KeyBindings/DefaultKeyBinding.dict"
        self.assertTrue(path.exists())
        self.uninstall("--defaults")
        self.assertFalse(path.exists())

    def setUp(self):
        super().setUp()
        self.preferences = self.home / "preferences.json"
        self.original = {
            "user:NSGlobalDomain": {"original-global": "keep", "KeyRepeat": 9},
            "host:NSGlobalDomain": {"original-host": "keep"},
            "user:com.apple.dock": {"original-dock": "keep", "autohide": 0},
            "user:com.apple.finder": {"original-finder": "keep"},
        }
        self.preferences.write_text(json.dumps(self.original))
        self.mock("defaults", f"""exec python3 - "$@" <<'PY'
import json, os, pathlib, plistlib, sys
p = pathlib.Path({str(self.preferences)!r})
data = json.loads(p.read_text())
args = sys.argv[1:]
scope = 'user'
if args[0] == '-currentHost':
    scope = 'host'; args = args[1:]
op, domain = args[:2]
key = scope + ':' + domain
if op == 'export':
    if os.getenv('FAIL_EXPORT') == key: sys.exit(1)
    sys.stdout.buffer.write(plistlib.dumps(data.get(key, {{}})))
elif op == 'import':
    if os.getenv('FAIL_IMPORT') == key: sys.exit(1)
    data[key] = plistlib.loads(pathlib.Path(args[2]).read_bytes())
elif op == 'write':
    value = args[-1]
    if args[-2] in ('-int', '-bool'):
        value = int(value) if args[-2] == '-int' else int(value == 'true')
    data.setdefault(key, {{}})[args[2]] = value
elif op == 'read':
    value = data.get(key, {{}})
    if len(args) > 2:
        if args[2] not in value: sys.exit(1)
        value = value[args[2]]
    print(value)
else:
    raise RuntimeError('Unexpected defaults call: ' + repr(args))
p.write_text(json.dumps(data))
PY
""")
        self.mock("sw_vers", "echo 15.0\n")
        self.mock("sudo", 'case "$1" in -v|-n) exit 0;; esac; exec "$@"\n')
        self.mock("killall", "exit 0\n")
        self.mock("chflags", "exit 0\n")
        # Do not invoke the real sudo refresh loop's sleep.
        self.mock("sleep", "exec /bin/sleep 0.02\n")

    def apply(self, *args, check=True):
        return self.command(
            ["/bin/bash", str(REPO / "scripts/macos/osx-defaults"), *args],
            check=check,
        )

    def test_domains_and_host_preferences_restore_the_first_baseline(self):
        self.apply("--only", "dock,input")
        self.apply("--only", "dock,input")
        self.uninstall("--defaults")
        data = json.loads(self.preferences.read_text())
        for key, original in self.original.items():
            self.assertEqual(data[key], original)

    def test_failed_import_is_reported_and_retryable(self):
        self.apply("--only", "dock")
        self.env["FAIL_IMPORT"] = "user:com.apple.dock"
        result = self.uninstall("--defaults")
        self.assertNotIn("Restored defaults: user:com.apple.dock", result.stdout)
        self.assertIn("Unresolved", result.stdout)
        self.env.pop("FAIL_IMPORT")
        self.uninstall("--defaults")
        self.assertEqual(json.loads(self.preferences.read_text())["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_failed_export_prevents_changes_to_that_domain(self):
        self.env["FAIL_EXPORT"] = "user:com.apple.dock"
        result = self.apply("--only", "dock", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(self.preferences.read_text()), self.original)

    def test_default_uninstall_keeps_optional_defaults_backups(self):
        self.apply("--only", "dock")
        self.uninstall()
        self.uninstall("--defaults")
        self.assertEqual(json.loads(self.preferences.read_text())["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_legacy_dump_is_preserved_without_global_import(self):
        backup = self.home / "legacy.plist"
        backup.write_text("legacy all-domain dump")
        self.state('state_record DEFAULTS_BACKUP "$HOME/legacy.plist"')
        result = self.uninstall("--defaults")
        self.assertIn("cannot be safely imported", result.stdout)
        self.assertEqual(backup.read_text(), "legacy all-domain dump")
        self.assertEqual(json.loads(self.preferences.read_text()), self.original)

    def test_backup_only_does_not_apply_settings(self):
        self.apply("--backup", "--only", "dock")
        self.assertEqual(json.loads(self.preferences.read_text()), self.original)
        self.assertTrue(list((self.home / "data/dotfiles-state/backups/defaults").glob("*.plist")))

    def test_dry_run_creates_no_state_or_backup(self):
        self.apply("--dry-run", "--only", "dock")
        self.assertFalse((self.home / "data").exists())
        self.assertEqual(json.loads(self.preferences.read_text()), self.original)
