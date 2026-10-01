"""Neovim config modules probed with `nvim -u NONE`, plus setup_nvim.sh guards.

No test loads the real init.lua: lazy.nvim would clone or update plugins.
"""

import json
import shutil

from test_rollback import REPO, Sandbox


class NvimModuleTests(Sandbox):
    def run_lua(self, body):
        """Run `body` with nvim/lua on the path; it returns a JSON-able value."""
        if not shutil.which("nvim"):
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
        self.command(["nvim", "--headless", "-u", "NONE", "-i", "NONE",
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
