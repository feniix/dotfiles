"""Package-manager CLI boundaries are mocked; no software is installed."""

import json
import os
import shutil

from test_rollback import REPO, Sandbox


class SoftwareTests(Sandbox):
    def brew_fixture(self, fail_bundle=False, with_dependency=False):
        inventory = self.home / "brew.json"
        inventory.write_text(json.dumps({"formula": ["existing"], "cask": ["old-app"]}))
        self.mock("brew", f"""exec python3 - "$@" <<'PY'
import json, pathlib, sys
p = pathlib.Path({str(inventory)!r})
data = json.loads(p.read_text())
args = sys.argv[1:]
if args[0] == 'list':
    print('\\n'.join(data['cask' if '--cask' in args else 'formula']))
elif args[0] == 'bundle':
    if 'added' not in data['formula']: data['formula'].append('added')
    if 'new-app' not in data['cask']: data['cask'].append('new-app')
    if {with_dependency!r} and 'dependency' not in data['formula']:
        data['formula'].append('dependency')
elif args[0] == 'install':
    data['formula'].append(args[-1])
    if args[-1] == 'mise':
        pathlib.Path({str(self.home / 'bin/mise')!r}).symlink_to({str(self.home / 'mise-executable')!r})
elif args[0] == 'leaves':
    print('\\n'.join(p for p in data['formula']
                    if p != 'dependency' or 'added' not in data['formula']))
elif args[0] == 'uninstall':
    kind = 'cask' if '--cask' in args else 'formula'
    data[kind].remove(args[-1])
p.write_text(json.dumps(data))
sys.exit({1 if fail_bundle else 0} if args[0] == 'bundle' else 0)
PY
""")
        return inventory

    def source_setup(self, name, input=None, check=True):
        return self.command(
            ["/bin/bash", "-ec",
             f'log_warning() {{ :; }}; source "{REPO}/scripts/lib/state.sh"; '
             f'state_init; source "{REPO}/scripts/setup/{name}"'],
            input=input, check=check,
        )

    def test_brew_uninstall_removes_only_new_formulae_and_casks(self):
        inventory = self.brew_fixture()
        self.source_setup("setup_homebrew.sh", input="y\n")
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"formula": ["existing"], "cask": ["old-app"]})

    def mise_fixture(self, fail_install=False):
        inventory = self.home / "mise.json"
        trust = self.home / "trusted-config"
        inventory.write_text(json.dumps({"node": [{"version": "old"}]}))
        self.mock("mise", f"""exec python3 - "$@" <<'PY'
import json, pathlib, sys
p = pathlib.Path({str(inventory)!r})
data = json.loads(p.read_text())
args = sys.argv[1:]
status = 0
if args[0] == 'version':
    print('fixture')
elif args[0] == 'trust':
    pathlib.Path({str(trust)!r}).write_text(args[-1])
elif args[0] == 'ls':
    if not pathlib.Path({str(trust)!r}).exists(): sys.exit(1)
    print(json.dumps(data))
elif args[0] == 'install':
    if not pathlib.Path({str(trust)!r}).exists(): sys.exit(1)
    if not any(v['version'] == 'new' for v in data['node']):
        data['node'].append({{'version': 'new'}})
    status = {1 if fail_install else 0}
elif args[0] == 'uninstall':
    tool, version = args[-1].rsplit('@', 1)
    data[tool] = [v for v in data[tool] if v['version'] != version]
else:
    raise RuntimeError('Unexpected mise command: ' + repr(args))
p.write_text(json.dumps(data))
sys.exit(status)
PY
""")
        return inventory

    def test_mise_uninstall_removes_only_added_versions(self):
        inventory = self.mise_fixture()
        config = self.home / "config/mise/config.toml"
        config.parent.mkdir(parents=True)
        config.write_text("[tools]\nnode = 'old'\n")
        self.source_setup("setup_mise.sh")
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"node": [{"version": "old"}]})
        self.assertEqual(config.read_text(), "[tools]\nnode = 'old'\n")

    def test_partial_brew_failure_still_tracks_added_packages(self):
        inventory = self.brew_fixture(fail_bundle=True)
        result = self.source_setup("setup_homebrew.sh", input="y\n", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"formula": ["existing"], "cask": ["old-app"]})

    def test_interrupted_brew_install_is_recovered_on_the_next_run(self):
        inventory = self.brew_fixture()
        # A run killed during brew bundle: its before-snapshot is left behind
        # and the packages it added are already installed.
        self.state(
            's="$STATE_DIR/software-brew.killed"; mkdir -p "$s"; '
            'printf "existing\\n" > "$s/formula.before"; '
            'printf "old-app\\n" > "$s/cask.before"; '
            'state_record SOFTWARE_INVENTORY "$s" brew'
        )
        inventory.write_text(json.dumps(
            {"formula": ["added", "existing"], "cask": ["new-app", "old-app"]}))
        self.source_setup("setup_homebrew.sh", input="y\n")
        manifest = (self.home / "data/dotfiles-state/manifest").read_text()
        self.assertNotIn("SOFTWARE_INVENTORY", manifest)
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"formula": ["existing"], "cask": ["old-app"]})

    def test_partial_mise_failure_is_reported_and_added_version_is_owned(self):
        inventory = self.mise_fixture(fail_install=True)
        result = self.source_setup("setup_mise.sh", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("All mise tools have been installed!", result.stdout)
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"node": [{"version": "old"}]})

    def test_optional_software_cleanup_survives_normal_uninstall(self):
        inventory = self.brew_fixture()
        self.source_setup("setup_homebrew.sh", input="y\n")
        self.uninstall()
        self.assertIn("added", json.loads(inventory.read_text())["formula"])
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text())["formula"], ["existing"])

    def test_legacy_software_without_inventory_is_left_alone(self):
        brew = self.brew_fixture()
        mise = self.mise_fixture()
        self.state(
            'state_record SOFTWARE brew "$DOTFILES_DIR/Brewfile"; '
            'state_record SOFTWARE mise "$HOME/config/mise/config.toml"'
        )
        self.uninstall("--software")
        self.assertEqual(json.loads(brew.read_text())["formula"], ["existing"])
        self.assertEqual(json.loads(mise.read_text()), {"node": [{"version": "old"}]})
        self.assertTrue((self.home / "data/dotfiles-state/manifest").exists())

    def test_fresh_mise_setup_bootstraps_binary_and_tracked_configuration(self):
        inventory = self.mise_fixture()
        (self.home / "bin/mise").rename(self.home / "mise-executable")
        self.brew_fixture()
        for name in ("python3", "jq"):
            (self.home / "bin" / name).symlink_to(shutil.which(name))
        self.env["PATH"] = str(self.home / "bin") + os.pathsep + "/usr/bin:/bin"
        self.source_setup("setup_mise.sh")
        config = self.home / "config/mise/config.toml"
        self.assertTrue(config.is_symlink())
        self.assertEqual(config.resolve(), REPO / "mise/config.toml")
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text()),
                         {"node": [{"version": "old"}]})

    def test_added_dependencies_are_removed_after_their_dependents(self):
        inventory = self.brew_fixture(with_dependency=True)
        self.source_setup("setup_homebrew.sh", input="y\n")
        self.uninstall("--software")
        self.assertEqual(json.loads(inventory.read_text())["formula"], ["existing"])
