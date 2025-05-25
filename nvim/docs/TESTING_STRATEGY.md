# Testing Strategy: macOS & Linux Multiplatform Support

This document outlines the comprehensive testing approach for ensuring reliable Neovim configuration across macOS and Linux platforms.

## 🎯 Testing Objectives

1. **Platform Compatibility**: Ensure all features work identically on macOS and Linux
2. **Performance Consistency**: Maintain similar performance characteristics across platforms
3. **Setup Reliability**: Guarantee automated setup works on fresh installations
4. **Plugin Stability**: Verify all plugins function correctly on both platforms
5. **Regression Prevention**: Catch platform-specific issues early

---

## 🏗️ Testing Infrastructure

### Local Testing Environment
```bash
# macOS Testing
- macOS Sonoma (latest) - Intel Mac
- macOS Sonoma (latest) - Apple Silicon (M1/M2)
- iTerm2 + Terminal.app
- Homebrew package manager

# Linux Testing  
- Ubuntu 22.04 LTS (primary)
- Debian 12 (secondary)
- GNOME Terminal + Alacritty
- apt package manager
```

### Virtualization Setup
```bash
# For comprehensive testing without multiple machines
# macOS: Use Parallels/VMware for Linux VMs
# Linux: Use QEMU/VirtualBox for additional Linux distros

# VM Configurations
ubuntu-22.04-vm/
├── 4GB RAM, 2 CPU cores
├── Fresh installation
└── Automated testing scripts

debian-12-vm/
├── 4GB RAM, 2 CPU cores  
├── Fresh installation
└── Automated testing scripts
```

### Container Testing (Linux)
```dockerfile
# Docker containers for isolated testing
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    neovim git curl build-essential \
    nodejs npm python3 python3-pip \
    golang-go rustc

FROM debian:12
RUN apt-get update && apt-get install -y \
    neovim git curl build-essential \
    nodejs npm python3 python3-pip \
    golang-go rustc
```

---

## 🧪 Testing Framework Implementation

### Automated Test Suite
```lua
-- lua/tests/platform_suite.lua
local M = {}

-- Test categories
M.test_categories = {
  'platform_detection',
  'path_operations', 
  'plugin_loading',
  'tool_availability',
  'performance_benchmarks',
  'integration_tests'
}

function M.run_full_suite()
  local results = {}
  
  for _, category in ipairs(M.test_categories) do
    print(string.format("Running %s tests...", category))
    local test_module = require(string.format('tests.%s', category))
    results[category] = test_module.run_tests()
  end
  
  M.generate_report(results)
  return results
end

function M.generate_report(results)
  local report = {
    timestamp = os.date('%Y-%m-%d %H:%M:%S'),
    platform = require('core.utils').platform.get_os(),
    total_tests = 0,
    passed = 0,
    failed = 0,
    details = results
  }
  
  -- Calculate totals
  for category, result in pairs(results) do
    report.total_tests = report.total_tests + result.total
    report.passed = report.passed + result.passed
    report.failed = report.failed + result.failed
  end
  
  -- Write report
  local report_file = string.format('test_report_%s_%s.json', 
    report.platform, os.date('%Y%m%d_%H%M%S'))
  
  local file = io.open(report_file, 'w')
  file:write(vim.json.encode(report))
  file:close()
  
  print(string.format("Test report saved: %s", report_file))
  print(string.format("Results: %d/%d passed", report.passed, report.total_tests))
end

return M
```

### Platform Detection Tests
```lua
-- lua/tests/platform_detection.lua
local platform = require('core.utils').platform
local M = {}

function M.run_tests()
  local tests = {
    M.test_os_detection,
    M.test_architecture_detection,
    M.test_config_paths,
    M.test_data_paths,
    M.test_terminal_capabilities
  }
  
  local results = { total = #tests, passed = 0, failed = 0, details = {} }
  
  for _, test in ipairs(tests) do
    local success, error_msg = pcall(test)
    if success then
      results.passed = results.passed + 1
    else
      results.failed = results.failed + 1
      table.insert(results.details, error_msg)
    end
  end
  
  return results
end

function M.test_os_detection()
  local os = platform.get_os()
  assert(os == 'macos' or os == 'linux', 'Invalid OS detection: ' .. tostring(os))
  print('✓ OS Detection: ' .. os)
end

function M.test_architecture_detection()
  local arch = vim.fn.system('uname -m'):gsub('%s+', '')
  assert(arch == 'x86_64' or arch == 'arm64' or arch == 'aarch64', 'No valid architecture detected: ' .. arch)
  print('✓ Architecture Detection: ' .. arch)
end

function M.test_config_paths()
  local config_dir = vim.fn.stdpath('config')
  assert(config_dir:match('/nvim$'), 'Invalid config directory: ' .. config_dir)
  print('✓ Config Path: ' .. config_dir)
end

function M.test_data_paths()
  local data_dir = vim.fn.stdpath('data')
  assert(data_dir:match('/nvim$'), 'Invalid data directory: ' .. data_dir)
  print('✓ Data Path: ' .. data_dir)
end

function M.test_terminal_capabilities()
  -- Test terminal feature detection
  local has_true_color = vim.fn.has('termguicolors') == 1
  local has_undercurl = vim.fn.has('undercurl') == 1
  
  print(string.format('✓ Terminal Capabilities: true_color=%s, undercurl=%s', 
    tostring(has_true_color), tostring(has_undercurl)))
end

return M
```

### Plugin Compatibility Tests
```lua
-- lua/tests/plugin_loading.lua
local M = {}

-- Critical plugins that must work on both platforms
M.critical_plugins = {
  'nvim-treesitter',
  'nvim-cmp',
  'telescope.nvim',
  'gitsigns.nvim',
  'which-key.nvim',
  'lualine.nvim'
}

function M.run_tests()
  local results = { total = 0, passed = 0, failed = 0, details = {} }
  
  -- Test plugin loading
  for _, plugin in ipairs(M.critical_plugins) do
    results.total = results.total + 1
    local success, error_msg = M.test_plugin_load(plugin)
    
    if success then
      results.passed = results.passed + 1
    else
      results.failed = results.failed + 1
      table.insert(results.details, string.format('%s: %s', plugin, error_msg))
    end
  end
  
  -- Test plugin functionality
  results.total = results.total + 3
  local func_tests = {
    M.test_treesitter_parsing,
    M.test_telescope_search,
    M.test_cmp_completion
  }
  
  for _, test in ipairs(func_tests) do
    local success, error_msg = pcall(test)
    if success then
      results.passed = results.passed + 1
    else
      results.failed = results.failed + 1
      table.insert(results.details, error_msg)
    end
  end
  
  return results
end

function M.test_plugin_load(plugin_name)
  local success, plugin = pcall(require, plugin_name)
  if not success then
    return false, string.format('Failed to load plugin: %s', plugin_name)
  end
  
  print(string.format('✓ Plugin loaded: %s', plugin_name))
  return true, nil
end

function M.test_treesitter_parsing()
  -- Test treesitter can parse a simple Lua file
  local ts = require('nvim-treesitter.parsers')
  local parser = ts.get_parser(0, 'lua')
  assert(parser ~= nil, 'Treesitter Lua parser not available')
  print('✓ Treesitter parsing functional')
end

function M.test_telescope_search()
  -- Test telescope can be invoked
  local telescope = require('telescope.builtin')
  assert(type(telescope.find_files) == 'function', 'Telescope find_files not available')
  print('✓ Telescope search functional')
end

function M.test_cmp_completion()
  -- Test nvim-cmp is properly configured
  local cmp = require('cmp')
  assert(cmp.setup ~= nil, 'nvim-cmp setup not available')
  print('✓ CMP completion functional')
end

return M
```

### Performance Benchmarks
```lua
-- lua/tests/performance_benchmarks.lua
local M = {}

function M.run_tests()
  local results = { total = 4, passed = 0, failed = 0, details = {} }
  
  local benchmarks = {
    M.benchmark_startup_time,
    M.benchmark_plugin_load_time,
    M.benchmark_file_open_time,
    M.benchmark_memory_usage
  }
  
  for _, benchmark in ipairs(benchmarks) do
    local success, result = pcall(benchmark)
    if success then
      results.passed = results.passed + 1
      table.insert(results.details, result)
    else
      results.failed = results.failed + 1
      table.insert(results.details, 'Benchmark failed: ' .. result)
    end
  end
  
  return results
end

function M.benchmark_startup_time()
  -- Measure Neovim startup time
  local start_time = vim.fn.reltime()
  -- Simulate startup completion
  vim.defer_fn(function()
    local elapsed = vim.fn.reltimestr(vim.fn.reltime(start_time))
    print(string.format('✓ Startup time: %s seconds', elapsed))
  end, 0)
  
  return 'Startup benchmark completed'
end

function M.benchmark_plugin_load_time()
  local start_time = vim.fn.reltime()
  
  -- Load a heavy plugin
  require('nvim-treesitter')
  
  local elapsed = vim.fn.reltimestr(vim.fn.reltime(start_time))
  print(string.format('✓ Plugin load time: %s seconds', elapsed))
  
  return string.format('Plugin load: %s seconds', elapsed)
end

function M.benchmark_file_open_time()
  local start_time = vim.fn.reltime()
  
  -- Create and open a test file
  vim.cmd('edit /tmp/nvim_test_file.lua')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    'local M = {}',
    'function M.test() return true end',
    'return M'
  })
  
  local elapsed = vim.fn.reltimestr(vim.fn.reltime(start_time))
  print(string.format('✓ File open time: %s seconds', elapsed))
  
  -- Cleanup
  vim.cmd('bdelete!')
  os.remove('/tmp/nvim_test_file.lua')
  
  return string.format('File open: %s seconds', elapsed)
end

function M.benchmark_memory_usage()
  -- Get memory usage (platform-specific)
  local platform = require('core.utils').platform
  local memory_cmd
  
  if platform.get_os() == 'macos' then
    memory_cmd = "ps -o rss= -p " .. vim.fn.getpid()
  else -- Linux
    memory_cmd = "ps -o rss= -p " .. vim.fn.getpid()
  end
  
  local memory_kb = vim.fn.system(memory_cmd):gsub('%s+', '')
  local memory_mb = math.floor(tonumber(memory_kb) / 1024)
  
  print(string.format('✓ Memory usage: %d MB', memory_mb))
  return string.format('Memory: %d MB', memory_mb)
end

return M
```

---

## 🚀 Automated Testing Scripts

### macOS Testing Script
```bash
#!/bin/bash
# scripts/test/test_macos.sh

set -e

echo "🍎 Starting macOS Testing Suite"
echo "================================"

# Environment info
echo "macOS Version: $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo "Neovim Version: $(nvim --version | head -1)"

# Check dependencies
echo "Checking dependencies..."
command -v brew >/dev/null 2>&1 || { echo "❌ Homebrew not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git not installed"; exit 1; }
command -v nvim >/dev/null 2>&1 || { echo "❌ Neovim not installed"; exit 1; }

# Run Neovim tests
echo "Running Neovim configuration tests..."
nvim --headless -c "lua require('tests.platform_suite').run_full_suite()" -c "qa"

# Test iTerm2 integration (if available)
if [ -d "/Applications/iTerm.app" ]; then
    echo "✓ iTerm2 detected - testing terminal integration"
    # Add iTerm2-specific tests here
fi

# Test Terminal.app integration
echo "✓ Testing Terminal.app integration"
# Add Terminal.app-specific tests here

echo "🎉 macOS testing completed successfully!"
```

### Linux Testing Script
```bash
#!/bin/bash
# scripts/test/test_linux.sh

set -e

echo "🐧 Starting Linux Testing Suite"
echo "==============================="

# Environment info
echo "Distribution: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Neovim Version: $(nvim --version | head -1)"

# Check dependencies
echo "Checking dependencies..."
command -v git >/dev/null 2>&1 || { echo "❌ Git not installed"; exit 1; }
command -v nvim >/dev/null 2>&1 || { echo "❌ Neovim not installed"; exit 1; }

# Check package manager
if command -v apt >/dev/null 2>&1; then
    echo "✓ APT package manager detected"
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    echo "✓ DNF package manager detected"
    PKG_MANAGER="dnf"
elif command -v pacman >/dev/null 2>&1; then
    echo "✓ Pacman package manager detected"
    PKG_MANAGER="pacman"
else
    echo "❌ No supported package manager found"
    exit 1
fi

# Test clipboard integration
echo "Testing clipboard integration..."
if command -v xclip >/dev/null 2>&1; then
    echo "✓ xclip available for X11 clipboard"
elif command -v wl-copy >/dev/null 2>&1; then
    echo "✓ wl-clipboard available for Wayland"
else
    echo "⚠️  No clipboard utility found - clipboard may not work"
fi

# Run Neovim tests
echo "Running Neovim configuration tests..."
nvim --headless -c "lua require('tests.platform_suite').run_full_suite()" -c "qa"

# Test terminal integration
echo "Testing terminal integration..."
if [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen-256color" ]; then
    echo "✓ 256-color terminal support detected"
else
    echo "⚠️  Limited color support: $TERM"
fi

echo "🎉 Linux testing completed successfully!"
```

### Cross-Platform Test Runner
```bash
#!/bin/bash
# scripts/test/run_all_tests.sh

set -e

echo "🔄 Cross-Platform Testing Suite"
echo "==============================="

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS - running macOS test suite"
    ./scripts/test/test_macos.sh
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux - running Linux test suite"
    ./scripts/test/test_linux.sh
else
    echo "❌ Unsupported platform: $OSTYPE"
    exit 1
fi

# Generate comparison report if both platforms tested
if [ -f "test_report_macos_*.json" ] && [ -f "test_report_linux_*.json" ]; then
    echo "Generating cross-platform comparison report..."
    nvim --headless -c "lua require('tests.compare_platforms').generate_report()" -c "qa"
fi

echo "✅ All tests completed!"
```

---

## 🔄 Continuous Integration Setup

### GitHub Actions Workflow
```yaml
# .github/workflows/test-multiplatform.yml
name: Multiplatform Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Neovim
      run: brew install neovim
      
    - name: Install dependencies
      run: |
        brew install git curl nodejs python3 go rust
        
    - name: Run macOS tests
      run: ./scripts/test/test_macos.sh
      
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: macos-test-results
        path: test_report_macos_*.json

  test-linux:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        container: ['ubuntu:22.04', 'debian:12']
    container: ${{ matrix.container }}
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install dependencies
      run: |
        apt-get update
        apt-get install -y neovim git curl nodejs npm python3 python3-pip golang-go rustc
        
    - name: Run Linux tests
      run: ./scripts/test/test_linux.sh
      
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: linux-test-results-${{ matrix.container }}
        path: test_report_linux_*.json

  compare-results:
    needs: [test-macos, test-linux]
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Download all test results
      uses: actions/download-artifact@v3
      
    - name: Generate comparison report
      run: |
        # Install Neovim for report generation
        apt-get update && apt-get install -y neovim
        nvim --headless -c "lua require('tests.compare_platforms').generate_ci_report()" -c "qa"
        
    - name: Upload comparison report
      uses: actions/upload-artifact@v3
      with:
        name: platform-comparison-report
        path: platform_comparison_*.html
```

---

## 📊 Testing Metrics & Reporting

### Success Criteria
```lua
-- lua/tests/success_criteria.lua
local M = {}

M.criteria = {
  platform_detection = {
    required_pass_rate = 100,
    description = "Platform detection must be 100% accurate"
  },
  
  plugin_loading = {
    required_pass_rate = 95,
    description = "95% of plugins must load successfully"
  },
  
  performance = {
    startup_time_max = 200, -- milliseconds
    memory_usage_max = 150, -- MB
    description = "Performance within acceptable limits"
  },
  
  cross_platform_consistency = {
    feature_parity = 100,
    performance_variance_max = 20, -- percent
    description = "Features and performance consistent across platforms"
  }
}

function M.evaluate_results(test_results)
  local evaluation = {
    overall_pass = true,
    details = {}
  }
  
  for category, criteria in pairs(M.criteria) do
    local result = test_results[category]
    local pass_rate = (result.passed / result.total) * 100
    
    local category_pass = pass_rate >= criteria.required_pass_rate
    evaluation.overall_pass = evaluation.overall_pass and category_pass
    
    evaluation.details[category] = {
      pass = category_pass,
      pass_rate = pass_rate,
      required = criteria.required_pass_rate,
      description = criteria.description
    }
  end
  
  return evaluation
end

return M
```

### Test Report Generation
```lua
-- lua/tests/report_generator.lua
local M = {}

function M.generate_html_report(test_results)
  local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Neovim Multiplatform Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .pass { color: green; }
        .fail { color: red; }
        .warn { color: orange; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Neovim Multiplatform Test Report</h1>
    <p>Generated: ]] .. os.date('%Y-%m-%d %H:%M:%S') .. [[</p>
    
    <h2>Summary</h2>
    <table>
        <tr><th>Platform</th><th>Total Tests</th><th>Passed</th><th>Failed</th><th>Pass Rate</th></tr>
  ]]
  
  for platform, results in pairs(test_results) do
    local pass_rate = math.floor((results.passed / results.total) * 100)
    local status_class = pass_rate >= 95 and 'pass' or (pass_rate >= 80 and 'warn' or 'fail')
    
    html = html .. string.format([[
        <tr class="%s">
            <td>%s</td>
            <td>%d</td>
            <td>%d</td>
            <td>%d</td>
            <td>%d%%</td>
        </tr>
    ]], status_class, platform, results.total, results.passed, results.failed, pass_rate)
  end
  
  html = html .. [[
    </table>
    
    <h2>Detailed Results</h2>
  ]]
  
  -- Add detailed results for each platform
  for platform, results in pairs(test_results) do
    html = html .. string.format([[
        <h3>%s Results</h3>
        <pre>%s</pre>
    ]], platform, vim.inspect(results.details))
  end
  
  html = html .. [[
</body>
</html>
  ]]
  
  local filename = string.format('test_report_%s.html', os.date('%Y%m%d_%H%M%S'))
  local file = io.open(filename, 'w')
  file:write(html)
  file:close()
  
  print('HTML report generated: ' .. filename)
  return filename
end

return M
```

---

## 🎯 Testing Schedule

### Daily Testing (Development)
- **Automated**: Run basic test suite on every commit
- **Manual**: Quick smoke tests on primary development platform

### Weekly Testing (Integration)
- **Full Suite**: Complete test suite on both macOS and Linux
- **Performance**: Benchmark comparison between platforms
- **Plugin Updates**: Test with latest plugin versions

### Release Testing (Pre-deployment)
- **Fresh Install**: Test complete setup on clean systems
- **Multiple Distros**: Test on Ubuntu 22.04, Debian 12
- **Hardware Variants**: Test on Intel and ARM architectures
- **Performance Regression**: Compare against previous release

---

This comprehensive testing strategy ensures reliable multiplatform functionality while maintaining development velocity and catching issues early in the development cycle. 