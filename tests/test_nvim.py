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
