-- Tests for the config module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local config = require('claude-code.config')

describe('config', function()
  describe('parse_config', function()
    it('should return default config when no user config is provided', function()
      local result = config.parse_config(nil, true) -- silent mode
      assert.are.same(config.default_config, result)
    end)

    it('should merge user config with default config', function()
      local user_config = {
        window = {
          height_ratio = 0.5,
        },
      }
      local result = config.parse_config(user_config, true) -- silent mode
      assert.are.equal(0.5, result.window.height_ratio)

      -- Other values should be set to defaults
      assert.are.equal('botright', result.window.position)
      assert.are.equal(true, result.window.enter_insert)
    end)

    it('should validate config values', function()
      -- This config has an invalid height_ratio (should be between 0 and 1)
      local invalid_config = {
        window = {
          height_ratio = 2,
        },
      }

      -- When validation fails, it should return the default config
      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.height_ratio, result.window.height_ratio)
    end)
  end)
end)
