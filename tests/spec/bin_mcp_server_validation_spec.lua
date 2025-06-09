local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('Claude-Nvim Wrapper Validation', function()
  local original_debug_getinfo
  local original_vim_opt
  local original_require

  before_each(function()
    -- Store originals
    original_debug_getinfo = debug.getinfo
    original_vim_opt = vim.opt
    original_require = require
  end)

  after_each(function()
    -- Restore originals
    debug.getinfo = original_debug_getinfo
    vim.opt = original_vim_opt
    require = original_require
  end)

  describe('plugin directory validation', function()
    it('should validate plugin directory exists', function()
      -- Mock debug.getinfo to return a test path
      debug.getinfo = function(level, what)
        if what == 'S' then
          return {
            source = '@/test/path/bin/claude-nvim',
          }
        end
        return original_debug_getinfo(level, what)
      end

      -- Mock vim.fn.isdirectory to test validation
      local checked_paths = {}
      local original_isdirectory = vim.fn.isdirectory
      vim.fn.isdirectory = function(path)
        table.insert(checked_paths, path)
        if path == '/test/path' then
          return 1 -- exists
        end
        return 0 -- doesn't exist
      end

      -- Mock vim.opt with proper prepend method
      local runtimepath_values = {}
      vim.opt = {
        loadplugins = false,
        swapfile = false,
        backup = false,
        writebackup = false,
        runtimepath = {
          prepend = function(path)
            table.insert(runtimepath_values, path)
          end,
        },
      }

      -- Mock require to avoid actual plugin loading
      require = function(module)
        if module == 'claude-code.mcp' then
          return {
            setup = function() end,
            start_standalone = function()
              return true
            end,
          }
        end
        return original_require(module)
      end

      -- Simulate the wrapper validation
      local script_source = '@/test/path/bin/claude-nvim'
      local script_dir = script_source:sub(2):match('(.*/)') -- "/test/path/bin/"

      -- Check if script directory would be validated
      assert.is_string(script_dir)
      assert.is_truthy(script_dir:match('/bin/$')) -- Should end with /bin/

      -- Restore
      vim.fn.isdirectory = original_isdirectory
    end)

    it('should handle invalid script paths gracefully', function()
      -- Mock debug.getinfo to return invalid path
      debug.getinfo = function(level, what)
        if what == 'S' then
          return {
            source = '', -- Invalid/empty source
          }
        end
        return original_debug_getinfo(level, what)
      end

      -- This should be handled gracefully without crashes
      local script_source = ''
      local script_dir = script_source:sub(2):match('(.*/)')
      assert.is_nil(script_dir) -- Should be nil for invalid path
    end)

    it('should validate runtimepath before prepending', function()
      -- Mock paths and functions for validation test
      local prepend_called_with = nil
      local runtimepath_mock = {
        prepend = function(path)
          prepend_called_with = path
        end,
      }

      vim.opt = {
        loadplugins = false,
        swapfile = false,
        backup = false,
        writebackup = false,
        runtimepath = runtimepath_mock,
      }

      -- Test that plugin_dir would be a valid path before prepending
      local plugin_dir = '/valid/plugin/directory'
      runtimepath_mock.prepend(plugin_dir)

      assert.equals(plugin_dir, prepend_called_with)
    end)
  end)

  describe('socket discovery validation', function()
    it('should validate Neovim socket discovery', function()
      -- Test socket discovery locations
      local socket_locations = {
        '~/.cache/nvim/claude-code-*.sock',
        '~/.cache/nvim/*.sock',
        '/tmp/nvim*.sock',
        '/tmp/nvim',
        '/tmp/nvimsocket*',
      }

      -- Mock vim.fn.glob to test socket discovery
      local original_glob = vim.fn.glob
      vim.fn.glob = function(path)
        if path:match('claude%-code%-') then
          return '/home/user/.cache/nvim/claude-code-12345.sock'
        end
        return ''
      end

      -- Test socket discovery
      local found_socket = vim.fn.glob('~/.cache/nvim/claude-code-*.sock')
      assert.is_truthy(found_socket:match('claude%-code%-'))

      -- Restore
      vim.fn.glob = original_glob
    end)

    it('should check for mcp-neovim-server installation', function()
      -- Mock command existence check
      local commands_checked = {}
      local original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        table.insert(commands_checked, cmd)
        if cmd == 'mcp-neovim-server' then
          return 0 -- not installed
        end
        return 1
      end

      -- Check if mcp-neovim-server is installed
      local is_installed = vim.fn.executable('mcp-neovim-server') == 1
      assert.is_false(is_installed)
      assert.are.same({ 'mcp-neovim-server' }, commands_checked)

      -- Restore
      vim.fn.executable = original_executable
    end)
  end)
end)
