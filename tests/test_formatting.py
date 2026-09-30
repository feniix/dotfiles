"""Exercise real Neovim buffer commands with formatter executables mocked."""

import json
import shutil

from test_rollback import REPO, Sandbox


class FormattingTests(Sandbox):
    def run_buffer(self, path, lines, invocation):
        result = self.home / "result.json"
        script = self.home / "test.lua"
        script.write_text(f"""
package.path = {json.dumps(str(REPO / 'nvim/lua/?.lua'))} .. ';' .. package.path
vim.notify = function() end
vim.cmd('edit ' .. vim.fn.fnameescape({json.dumps(str(path))}))
vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.json.decode({json.dumps(json.dumps(lines))}))
{invocation}
vim.fn.writefile({{vim.json.encode(vim.api.nvim_buf_get_lines(0, 0, -1, false))}},
  {json.dumps(str(result))})
""")
        self.command(["nvim", "--headless", "-u", "NONE", "-i", "NONE",
                      "--noplugin", "-l", str(script)])
        return json.loads(result.read_text())

    def format_case(self, module, method, command, failure=False, on_save=False,
                    warning=False, directory=None, before=""):
        if not shutil.which("nvim"):
            self.fail("nvim is required for formatting regression tests")
        body = "echo formatter-error >&2; exit 1\n" if failure else (
            "/usr/bin/tr '[:lower:]' '[:upper:]'\n" +
            ("echo formatter-warning >&2\n" if warning else "")
        )
        self.mock(command, body)
        extension = {"rustfmt": "rs", "terraform": "tf"}.get(command, "py")
        path = (directory or self.home) / f"file.{extension}"
        path.write_text("saved disk content\n")
        result = self.home / "result.json"
        script = self.home / "test.lua"
        invocation = f"require('{module}').{method}()"
        if on_save:
            invocation = (
                f"require('{module}').setup(); vim.g.rust_format_on_save = true; "
                "vim.cmd('write')"
            )
        script.write_text(f"""
package.path = {json.dumps(str(REPO / 'nvim/lua/?.lua'))} .. ';' ..
  {json.dumps(str(REPO / 'nvim/lua/?/init.lua'))} .. ';' .. package.path
vim.notify = function() end
vim.cmd('edit ' .. vim.fn.fnameescape({json.dumps(str(path))}))
vim.api.nvim_buf_set_lines(0, 0, -1, false, {{'unsaved content'}})
vim.api.nvim_win_set_cursor(0, {{1, 3}})
{before}
{invocation}
vim.fn.writefile({{vim.json.encode({{
  lines=vim.api.nvim_buf_get_lines(0, 0, -1, false),
  cursor=vim.api.nvim_win_get_cursor(0)
}})}}, {json.dumps(str(result))})
""")
        self.command(["nvim", "--headless", "-u", "NONE", "-i", "NONE",
                      "--noplugin", "-l", str(script)])
        data = json.loads(result.read_text())
        self.assertEqual(data["lines"],
                         ["unsaved content"] if failure else ["UNSAVED CONTENT"])
        self.assertEqual(data["cursor"], [1, 3])
        if on_save:
            self.assertEqual(path.read_text(), "UNSAVED CONTENT\n")

    def test_python_imports_format_current_buffer_not_disk(self):
        self.format_case("plugins.config.lang.python", "sort_imports", "isort")

    def test_black_formats_current_buffer_and_preserves_cursor(self):
        self.format_case("plugins.config.lang.python", "format_python", "black")

    def test_successful_formatter_stderr_is_not_buffer_content(self):
        for module, method, command in (
            ("plugins.config.lang.python", "format_python", "black"),
            ("plugins.config.lang.python", "sort_imports", "isort"),
            ("plugins.config.lang.rust", "format_rust", "rustfmt"),
            ("plugins.config.lang.terraform", "format_terraform", "terraform"),
        ):
            with self.subTest(command=command):
                self.format_case(module, method, command, warning=True)

    def test_terraform_formats_buffer_through_stdin(self):
        self.format_case("plugins.config.lang.terraform", "format_terraform", "terraform")

    def test_rust_format_current_buffer_not_disk(self):
        self.format_case("plugins.config.lang.rust", "format_rust", "rustfmt")

    def test_formatter_failure_preserves_buffer_and_cursor(self):
        for module, method, command in (
            ("plugins.config.lang.python", "sort_imports", "isort"),
            ("plugins.config.lang.python", "format_python", "black"),
            ("plugins.config.lang.rust", "format_rust", "rustfmt"),
            ("plugins.config.lang.terraform", "format_terraform", "terraform"),
        ):
            with self.subTest(command=command):
                self.format_case(module, method, command, failure=True)

    def test_rust_format_on_save_formats_unsaved_content(self):
        self.format_case("plugins.config.lang.rust", "format_rust", "rustfmt",
                         on_save=True)


    def test_terraform_command_escapes_directory(self):
        directory = self.home / "project space; echo INJECTED"
        directory.mkdir()
        before = f"""
local cmd = vim.cmd
vim.cmd = function(value)
  if value:match('^terminal ') then
    assert(value == 'terminal cd ' .. vim.fn.shellescape({json.dumps(str(directory))})
      .. ' && terraform plan', value)
  end
end
require('plugins.config.lang.terraform').run_terraform_command('plan')
vim.cmd = cmd
"""
        self.format_case("plugins.config.lang.terraform", "format_terraform", "terraform",
                         directory=directory, before=before)

    def test_real_terraform_formats_unsaved_code_not_filename_output(self):
        terraform = shutil.which("terraform")
        if not terraform:
            self.skipTest("Terraform not installed")
        # Use the real formatter only, never init/plan/apply.
        self.mock("terraform", f'exec "{terraform}" "$@"\n')
        path = self.home / "main.tf"
        saved = 'variable "saved" {\ntype=string\n}\n'
        path.write_text(saved)
        lines = self.run_buffer(
            path, ['variable "unsaved" {', 'type=string', '}'],
            "require('plugins.config.lang.terraform').format_terraform()",
        )
        self.assertEqual(lines, ['variable "unsaved" {', '  type = string', '}'])
        self.assertEqual(path.read_text(), saved)
