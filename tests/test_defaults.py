"""macOS defaults are simulated; no live preference writes or sudo calls."""

import copy
import json
import plistlib

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
            "user:com.apple.dock": {
                "original-dock": "keep", "autohide": 0,
                "mru-spaces": True, "autohide-delay": 0.5,
            },
            "user:com.apple.finder": {"original-finder": "keep"},
            # Separators and a trailing newline must survive the manifest.
            "user:com.apple.screencapture": {"location": "/a:b|c\n"},
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
    if os.getenv('FAIL_WRITE') == key + ':' + args[2]: sys.exit(1)
    kind, value = args[-2:]
    value = {{'-int': int, '-float': float, '-string': str,
              '-bool': lambda v: v in ('true', 'yes', 'YES', 'TRUE')}}[kind](value)
    data.setdefault(key, {{}})[args[2]] = value
elif op == 'read':
    value = data.get(key, {{}})
    if len(args) > 2:
        if args[2] not in value: sys.exit(1)
        value = value[args[2]]
    print(int(value) if isinstance(value, bool) else value)
elif op == 'read-type':
    value = data.get(key, {{}})
    if args[2] not in value:
        print('The domain/default pair of (' + domain + ', ' + args[2] + ') does not exist',
              file=sys.stderr)
        sys.exit(1)
    value = value[args[2]]
    for kind, name in ((bool, 'boolean'), (int, 'integer'), (float, 'float'),
                       (str, 'string'), (list, 'array'), (dict, 'dictionary')):
        if isinstance(value, kind):
            print('Type is ' + name); break
elif op == 'delete':
    if args[2] not in data.get(key, {{}}): sys.exit(1)
    del data[key][args[2]]
else:
    raise RuntimeError('Unexpected defaults call: ' + repr(args))
p.write_text(json.dumps(data))
PY
""")
        self.mock("sw_vers", "echo 15.0\n")
        self.mock("sudo", 'case "$1" in -v|-n) exit 0;; esac; exec "$@"\n')
        self.mock("killall", "exit 0\n")
        self.mock("chflags", "exit 0\n")
        self.mock("pmset", "exit 0\n")
        self.mock("nvram", "exit 0\n")
        # Do not invoke the real sudo refresh loop's sleep.
        self.mock("sleep", "exec /bin/sleep 0.02\n")

    def apply(self, *args, check=True):
        return self.command(
            ["/bin/bash", str(REPO / "scripts/macos/osx-defaults"), *args],
            check=check,
        )

    def load(self):
        return json.loads(self.preferences.read_text())

    def edit(self, change):
        data = self.load()
        change(data)
        self.preferences.write_text(json.dumps(data))

    def legacy_snapshot(self, domain):
        """Record a domain snapshot the way installs before per-key tracking did."""
        backups = self.home / "data/dotfiles-state/backups/defaults"
        backups.mkdir(parents=True, exist_ok=True)
        (backups / "legacy.plist").write_bytes(plistlib.dumps(self.original[domain]))
        self.state(f'state_record DEFAULTS_DOMAIN "{domain}" defaults/legacy.plist')

    def test_uninstall_restores_only_the_keys_it_wrote(self):
        self.apply("--only", "dock,input,screenshot")
        self.apply("--only", "dock,input,screenshot")

        def user_changes(data):
            data["user:com.apple.dock"]["original-dock"] = "changed by user"
            data["user:com.apple.dock"]["added-by-user"] = 1
            data["host:NSGlobalDomain"]["host-added-by-user"] = 1
        self.edit(user_changes)
        expected = copy.deepcopy(self.original)
        user_changes(expected)

        self.uninstall("--defaults")
        data = self.load()
        for domain, values in expected.items():
            self.assertEqual(data[domain], values, domain)
        # Originals come back with their types.
        dock = data["user:com.apple.dock"]
        self.assertIs(dock["mru-spaces"], True)
        self.assertIs(type(dock["autohide"]), int)
        self.assertIs(type(dock["autohide-delay"]), float)
        # Keys that did not exist (including -currentHost) are deleted.
        self.assertNotIn("show-recents", dock)
        self.assertNotIn("com.apple.mouse.tapBehavior", data["host:NSGlobalDomain"])
        self.assertEqual(data["user:com.apple.WindowManager"], {})
        self.assertFalse((self.home / "data/dotfiles-state").exists())

    def test_unrepresentable_value_restores_its_domain_snapshot(self):
        self.original["user:com.apple.dock"]["autohide"] = [1, 2]
        self.preferences.write_text(json.dumps(self.original))
        self.apply("--only", "dock")
        self.uninstall("--defaults")
        self.assertEqual(self.load()["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_legacy_domain_snapshot_restores_the_whole_domain(self):
        self.legacy_snapshot("user:com.apple.dock")
        self.edit(lambda data: data["user:com.apple.dock"].update(
            {"autohide": 1, "added-later": 1}))
        result = self.uninstall("--defaults")
        self.assertIn("Restored defaults: user:com.apple.dock", result.stdout)
        self.assertEqual(self.load()["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_rerun_over_legacy_install_keeps_the_old_snapshot_as_baseline(self):
        self.legacy_snapshot("user:com.apple.dock")
        # The old install already applied its values to the domain.
        self.edit(lambda data: data["user:com.apple.dock"].update({"autohide": True}))
        self.apply("--only", "dock")
        manifest = (self.home / "data/dotfiles-state/manifest").read_text()
        dock_keys = [line for line in manifest.splitlines()
                     if line.startswith("DEFAULTS_KEY|") and "|user:com.apple.dock:" in line]
        self.assertTrue(dock_keys)
        self.assertTrue(all(line.endswith("|SNAPSHOT") for line in dock_keys), dock_keys)
        self.uninstall("--defaults")
        self.assertEqual(self.load()["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_failed_import_is_reported_and_retryable(self):
        self.legacy_snapshot("user:com.apple.dock")
        self.env["FAIL_IMPORT"] = "user:com.apple.dock"
        result = self.uninstall("--defaults")
        self.assertNotIn("Restored defaults: user:com.apple.dock", result.stdout)
        self.assertIn("Unresolved", result.stdout)
        self.env.pop("FAIL_IMPORT")
        self.uninstall("--defaults")
        self.assertEqual(self.load()["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_failed_key_restore_is_reported_and_retryable(self):
        self.apply("--only", "dock")
        self.env["FAIL_WRITE"] = "user:com.apple.dock:autohide"
        result = self.uninstall("--defaults")
        self.assertIn("Unresolved: DEFAULTS_KEY (user:com.apple.dock:autohide)",
                      result.stdout)
        self.assertIs(self.load()["user:com.apple.dock"]["autohide"], True)
        self.env.pop("FAIL_WRITE")
        self.uninstall("--defaults")
        self.assertEqual(self.load()["user:com.apple.dock"],
                         self.original["user:com.apple.dock"])

    def test_commands_without_a_restore_are_listed_not_undone(self):
        self.mock("nvram", "exit 1\n")  # a refused command changed nothing
        self.apply("--only", "system,energy,finder", check=False)
        result = self.uninstall()
        self.assertNotIn("Not undone automatically", result.stdout)
        result = self.uninstall("--defaults")
        listed = result.stdout.split("Not undone automatically", 1)[1]
        for command in ("sudo pmset -a standbydelay 86400", "sudo pmset -c sleep 78",
                        f"chflags nohidden {self.home}/Library",
                        "sudo chflags nohidden /Volumes"):
            self.assertIn("  " + command + "\n", listed)
        self.assertNotIn("nvram", listed)
        self.assertFalse((self.home / "data/dotfiles-state").exists())

    def test_failed_export_prevents_changes_to_that_domain(self):
        self.env["FAIL_EXPORT"] = "user:com.apple.dock"
        result = self.apply("--only", "dock", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SKIPPED (no backup of user:com.apple.dock)", result.stderr)
        data = json.loads(self.preferences.read_text())
        self.assertEqual(data["user:com.apple.dock"], self.original["user:com.apple.dock"])
        # Other domains in the section are still applied.
        self.assertIn("user:com.apple.WindowManager", data)

    def test_refused_write_skips_only_that_command(self):
        # e.g. a TCC-protected domain when the terminal lacks Full Disk Access
        defaults = self.home / "bin/defaults"
        defaults.write_text(defaults.read_text().replace(
            "exec python3",
            '[[ "$1" == write && "$2" == com.apple.dock && "$3" == autohide ]] && exit 1\n'
            "exec python3", 1))
        result = self.apply("--only", "dock,finder", check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("FAILED: defaults write com.apple.dock autohide", result.stderr)
        data = json.loads(self.preferences.read_text())
        self.assertEqual(data["user:com.apple.dock"]["autohide"], 0)
        self.assertEqual(data["user:com.apple.dock"]["show-recents"], 0)
        self.assertEqual(data["user:com.apple.finder"]["ShowPathbar"], 1)
        self.assertIn("Verified:", result.stdout)

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
