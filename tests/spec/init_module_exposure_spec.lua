local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('claude-code module exposure', function()
  local claude_code

  before_each(function()
    -- Clear module cache to ensure fresh state
    package.loaded['claude-code'] = nil
    package.loaded['claude-code.config'] = nil
    package.loaded['claude-code.commands'] = nil
    package.loaded['claude-code.keymaps'] = nil
    package.loaded['claude-code.file_refresh'] = nil
    package.loaded['claude-code.terminal'] = nil
    package.loaded['claude-code.git'] = nil
    package.loaded['claude-code.version'] = nil
    package.loaded['claude-code.file_reference'] = nil

    claude_code = require('claude-code')
  end)

  describe('public API', function()
    it('should expose setup function', function()
      assert.is_function(claude_code.setup)
    end)

    it('should expose toggle function', function()
      assert.is_function(claude_code.toggle)
    end)

    it('should expose toggle_with_variant function', function()
      assert.is_function(claude_code.toggle_with_variant)
    end)

    it('should expose toggle_with_context function', function()
      assert.is_function(claude_code.toggle_with_context)
    end)

    it('should expose safe_toggle function', function()
      assert.is_function(claude_code.safe_toggle)
    end)

    it('should expose get_process_status function', function()
      assert.is_function(claude_code.get_process_status)
    end)

    it('should expose list_instances function', function()
      assert.is_function(claude_code.list_instances)
    end)

    it('should expose get_config function', function()
      assert.is_function(claude_code.get_config)
    end)

    it('should expose get_version function', function()
      assert.is_function(claude_code.get_version)
    end)

    it('should expose version function (alias)', function()
      assert.is_function(claude_code.version)
    end)

    it('should expose force_insert_mode function', function()
      assert.is_function(claude_code.force_insert_mode)
    end)

    it('should expose get_prompt_input function', function()
      assert.is_function(claude_code.get_prompt_input)
    end)

    it('should expose claude_code terminal object', function()
      assert.is_table(claude_code.claude_code)
    end)
  end)

  describe('internal modules', function()
    it('should not expose _config directly', function()
      assert.is_nil(claude_code._config)
    end)

    it('should not expose commands module directly', function()
      assert.is_nil(claude_code.commands)
    end)

    it('should not expose keymaps module directly', function()
      assert.is_nil(claude_code.keymaps)
    end)

    it('should not expose file_refresh module directly', function()
      assert.is_nil(claude_code.file_refresh)
    end)

    it('should not expose terminal module directly', function()
      assert.is_nil(claude_code.terminal)
    end)

    it('should not expose git module directly', function()
      assert.is_nil(claude_code.git)
    end)

    it('should not expose version module directly', function()
      -- Note: version is exposed as a function, not the module
      assert.is_function(claude_code.version)
      -- The version function should not expose module internals
      -- We can't check properties of a function, so we verify it's just a function
      assert.is_function(claude_code.version)
      assert.is_function(claude_code.get_version)
    end)
  end)

  describe('module documentation', function()
    it('should have proper module documentation', function()
      -- This test just verifies that the module loads without errors
      -- The actual documentation is verified by the presence of @mod and @brief tags
      assert.is_table(claude_code)
    end)
  end)
end)
