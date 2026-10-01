"""Neovim config modules probed with `nvim -u NONE`, plus setup_nvim.sh guards.

No test loads the real init.lua: lazy.nvim would clone or update plugins.
"""

import json
import re
import shutil

from test_rollback import REPO, Sandbox


class NvimModuleTests(Sandbox):
    def run_lua(self, body):
        """Run `body` with nvim/lua on the path; it returns a JSON-able value."""
        nvim = shutil.which("nvim")
        if not nvim:
            self.fail("nvim is required for Neovim config tests")
        result = self.home / "result.json"
        script = self.home / "probe.lua"
        script.write_text(f"""
package.path = {json.dumps(str(REPO / 'nvim/lua/?.lua'))} .. ';' ..
  {json.dumps(str(REPO / 'nvim/lua/?/init.lua'))} .. ';' .. package.path
vim.notify = function() end
local value = (function()
{body}
end)()
vim.fn.writefile({{vim.json.encode(value)}}, {json.dumps(str(result))})
""")
        self.command([nvim, "--headless", "-u", "NONE", "-i", "NONE",
                      "--noplugin", "-l", str(script)])
        return json.loads(result.read_text())

    def test_language_setup_does_not_stack_autocmds(self):
        counts = self.run_lua("""
local out = {}
for _, lang in ipairs({ 'python', 'puppet', 'rust', 'terraform', 'go' }) do
  local mod = require('plugins.config.lang.' .. lang)
  mod.setup()
  local once = #vim.api.nvim_get_autocmds({})
  mod.setup()
  out[lang] = { once, #vim.api.nvim_get_autocmds({}) }
end
require('core.utils').setup()
local once = #vim.api.nvim_get_autocmds({ event = 'VimEnter' })
require('core.utils').setup()
out.utils = { once, #vim.api.nvim_get_autocmds({ event = 'VimEnter' }) }
return out
""")
        for name, (once, twice) in counts.items():
            self.assertEqual(once, twice, name)

    def test_terraform_lsp_toggle_without_config_only_warns(self):
        self.mock("terraform-ls", "exit 0\n")
        messages = self.run_lua("""
local seen = {}
vim.notify = function(msg, level) table.insert(seen, { msg, level }) end
require('plugins.config.lang.terraform').toggle_terraform_lsp()
return seen
""")
        self.assertEqual(len(messages), 1, messages)
        self.assertIn("No LSP configuration for terraformls", messages[0][0])

    def test_user_keymaps_accept_list_and_mode_tables(self):
        maps = self.run_lua("""
vim.g.mapleader = ','
local keymaps = require('user.overrides.keymaps')
keymaps.setup({ { 'n', '<leader>zl', ':echo 1<CR>' } })
keymaps.setup({ n = { ['<leader>zm'] = ':echo 2<CR>' } })
return { vim.fn.maparg(',zl', 'n'), vim.fn.maparg(',zm', 'n') }
""")
        self.assertEqual(maps, [":echo 1<CR>", ":echo 2<CR>"])

    def node_provider(self):
        # `npm` must never run at startup; the mock records any call. Only
        # the mocks and the system dirs are on PATH, so a real
        # neovim-node-host cannot leak in.
        self.mock("npm", 'echo "$@" >> "$HOME/npm-calls"\n')
        self.mock("node", "exit 0\n")
        self.env["PATH"] = str(self.home / "bin") + ":/usr/bin:/bin"
        result = self.run_lua("""
require('core.options').setup()
return { vim.g.node_host_prog or '', vim.g.loaded_node_provider or -1 }
""")
        self.assertFalse((self.home / "npm-calls").exists())
        return result

    def test_node_provider_uses_neovim_node_host_on_path(self):
        host = self.mock("neovim-node-host", "exit 0\n")
        self.assertEqual(self.node_provider(), [str(host), -1])

    def test_node_provider_disabled_without_neovim_package(self):
        self.assertEqual(self.node_provider(), ["", 0])

    def test_language_maps_do_not_shadow_global_leader_maps(self):
        shadowed = self.run_lua("""
vim.g.mapleader = ','
require('core.keymaps').setup()
require('plugins.config.tools').setup_keymaps()
local out = {}
for _, lang in ipairs({ 'python', 'puppet', 'terraform', 'go' }) do
  require('plugins.config.lang.' .. lang).setup()
  vim.cmd('enew')
  vim.bo.filetype = lang
  for _, lhs in ipairs({ ',pi', ',pu', ',pc', ',ps', ',ph', ',pr', ',ti', ',tI', ',tn' }) do
    local map = vim.fn.maparg(lhs, 'n', false, true)
    if map.buffer == 1 then table.insert(out, lang .. ' ' .. lhs) end
  end
end
return out
""")
        self.assertEqual(shadowed, [])

    def test_python_installer_matches_the_tools_python_lua_runs(self):
        source = (REPO / "nvim/lua/plugins/config/lang/python.lua").read_text()
        invoked = set(re.findall(r"executable\('([\w-]+)'\)", source))
        invoked -= {"python3", "python"}
        installed = self.run_lua("""
local names = vim.tbl_keys(require('core.installer').tools.python_tools)
table.sort(names)
return names
""")
        self.assertEqual(sorted(invoked), installed)


class SetupNvimTests(Sandbox):
    """setup_nvim.sh with `nvim` mocked; the mock records each call's args."""

    def setUp(self):
        super().setUp()
        repo = self.home / "repo"
        shutil.copytree(REPO / "scripts/lib", repo / "scripts/lib")
        (repo / "nvim").mkdir(parents=True)
        (repo / ".vimrc").write_text("fixture")
        self.env["DOTFILES_DIR"] = str(repo)
        self.calls = self.home / "nvim-calls"
        self.mock("nvim", f'printf "%s\\n" "$@" "--" >> {json.dumps(str(self.calls))}\n'
                  'exit "${NVIM_EXIT:-0}"\n')

    def setup_nvim(self, *args):
        result = self.command(["/bin/bash", str(REPO / "scripts/setup/setup_nvim.sh"), *args])
        calls = self.calls.read_text().split("--\n")[:-1] if self.calls.exists() else []
        return result, [c.splitlines() for c in calls]

    def test_existing_lazy_nvim_is_not_touched(self):
        (self.home / "data/nvim/lazy/lazy.nvim").mkdir(parents=True)
        _, calls = self.setup_nvim("--install-plugins")
        self.assertEqual(calls, [])

    def test_fresh_machine_restores_from_the_lockfile_once(self):
        _, calls = self.setup_nvim("--install-plugins")
        self.assertEqual(calls, [["--headless", "+Lazy! restore", "+qa"]])

    def test_without_the_flag_nvim_is_not_run(self):
        _, calls = self.setup_nvim()
        self.assertEqual(calls, [])

    def test_failed_restore_warns_without_failing_setup(self):
        self.env["NVIM_EXIT"] = "1"
        result, calls = self.setup_nvim("--install-plugins")
        self.assertEqual(len(calls), 1)
        self.assertIn("Plugin install failed", result.stdout)

    def test_vimrc_is_left_to_setup_sh(self):
        self.setup_nvim()
        self.assertFalse((self.home / ".vimrc").exists())
        self.assertFalse((self.home / "config/vim/vimrc").exists())
