local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('Deprecated API Replacement', function()
  local resources
  local tools
  local original_nvim_buf_get_option
  local original_nvim_get_option_value

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.mcp.resources'] = nil
    package.loaded['claude-code.mcp.tools'] = nil

    -- Store original functions
    original_nvim_buf_get_option = vim.api.nvim_buf_get_option
    original_nvim_get_option_value = vim.api.nvim_get_option_value

    -- Load modules
    resources = require('claude-code.mcp.resources')
    tools = require('claude-code.mcp.tools')
  end)

  after_each(function()
    -- Restore original functions
    vim.api.nvim_buf_get_option = original_nvim_buf_get_option
    vim.api.nvim_get_option_value = original_nvim_get_option_value
  end)

  describe('nvim_get_option_value usage', function()
    it('should use nvim_get_option_value instead of nvim_buf_get_option in resources', function()
      -- Mock vim.api.nvim_get_option_value
      local get_option_value_called = false
      vim.api.nvim_get_option_value = function(option, opts)
        get_option_value_called = true
        if option == 'filetype' then
          return 'lua'
        elseif option == 'modified' then
          return false
        elseif option == 'buflisted' then
          return true
        end
        return nil
      end

      -- Mock vim.api.nvim_buf_get_option to detect if it's still being used
      local deprecated_api_called = false
      vim.api.nvim_buf_get_option = function()
        deprecated_api_called = true
        return 'deprecated'
      end

      -- Mock other required functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_lines = function()
        return { 'line1', 'line2' }
      end
      vim.api.nvim_buf_get_name = function()
        return 'test.lua'
      end
      vim.api.nvim_list_bufs = function()
        return { 1 }
      end
      vim.api.nvim_buf_is_loaded = function()
        return true
      end
      vim.api.nvim_buf_line_count = function()
        return 2
      end

      -- Test current buffer resource
      local result = resources.current_buffer.handler()
      assert.is_string(result)
      assert.is_true(get_option_value_called)
      assert.is_false(deprecated_api_called)

      -- Reset flags
      get_option_value_called = false
      deprecated_api_called = false

      -- Test buffer list resource
      local buffer_result = resources.buffer_list.handler()
      assert.is_string(buffer_result)
      assert.is_true(get_option_value_called)
      assert.is_false(deprecated_api_called)
    end)

    it('should use nvim_get_option_value instead of nvim_buf_get_option in tools', function()
      -- Mock vim.api.nvim_get_option_value
      local get_option_value_called = false
      vim.api.nvim_get_option_value = function(option, opts)
        get_option_value_called = true
        if option == 'modified' then
          return false
        elseif option == 'filetype' then
          return 'lua'
        end
        return nil
      end

      -- Mock vim.api.nvim_buf_get_option to detect if it's still being used
      local deprecated_api_called = false
      vim.api.nvim_buf_get_option = function()
        deprecated_api_called = true
        return 'deprecated'
      end

      -- Mock other required functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function()
        return 'test.lua'
      end
      vim.api.nvim_buf_get_lines = function()
        return { 'line1', 'line2' }
      end

      -- Test buffer read tool
      if tools.read_buffer then
        local result = tools.read_buffer.handler({ buffer = 1 })
        assert.is_true(get_option_value_called)
        assert.is_false(deprecated_api_called)
      end
    end)
  end)

  describe('option value extraction', function()
    it('should handle buffer-scoped options correctly', function()
      local options_requested = {}

      vim.api.nvim_get_option_value = function(option, opts)
        table.insert(options_requested, { option = option, opts = opts })
        if option == 'filetype' then
          return 'lua'
        elseif option == 'modified' then
          return false
        elseif option == 'buflisted' then
          return true
        end
        return nil
      end

      -- Mock other functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_lines = function()
        return { 'line1' }
      end
      vim.api.nvim_buf_get_name = function()
        return 'test.lua'
      end

      resources.current_buffer.handler()

      -- Check that buffer-scoped options are requested correctly
      local found_buffer_option = false
      for _, req in ipairs(options_requested) do
        if req.opts and req.opts.buf then
          found_buffer_option = true
          break
        end
      end

      assert.is_true(found_buffer_option, 'Should request buffer-scoped options')
    end)
  end)
end)
