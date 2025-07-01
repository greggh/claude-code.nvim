-- Tests for the config module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local config = require('rovo-dev.config')

describe('config', function()
  describe('parse_config', function()
    it('should return default config when no user config is provided', function()
      local result = config.parse_config(nil, true) -- silent mode
      assert.are.same(config.default_config, result)
    end)

    it('should merge user config with default config', function()
      local user_config = {
        window = {
          split_ratio = 0.5,
        },
      }
      local result = config.parse_config(user_config, true) -- silent mode
      assert.are.equal(0.5, result.window.split_ratio)

      -- Other values should be set to defaults
      assert.are.equal('botright', result.window.position)
      assert.are.equal(true, result.window.enter_insert)
    end)

    it('should validate config values', function()
      -- This config has an invalid split_ratio (should be between 0 and 1)
      local invalid_config = {
        window = {
          split_ratio = 2,
        },
      }

      -- When validation fails, it should return the default config
      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.split_ratio, result.window.split_ratio)
    end)
    
    it('should maintain backward compatibility with height_ratio', function()
      -- Config using the legacy height_ratio instead of split_ratio
      local legacy_config = {
        window = {
          height_ratio = 0.7,
          -- split_ratio not specified
        },
      }

      local result = config.parse_config(legacy_config, true) -- silent mode
      
      -- split_ratio should be set to the height_ratio value
      assert.are.equal(0.7, result.window.split_ratio)
    end)

    it('should accept float configuration when position is float', function()
      local float_config = {
        window = {
          position = 'float',
          float = {
            width = 80,
            height = 20,
            relative = 'editor',
            border = 'rounded',
          },
        },
      }

      local result = config.parse_config(float_config, true) -- silent mode
      
      assert.are.equal('float', result.window.position)
      assert.are.equal(80, result.window.float.width)
      assert.are.equal(20, result.window.float.height)
      assert.are.equal('editor', result.window.float.relative)
      assert.are.equal('rounded', result.window.float.border)
    end)

    it('should accept float with percentage dimensions', function()
      local float_config = {
        window = {
          position = 'float',
          float = {
            width = '80%',
            height = '50%',
            relative = 'editor',
          },
        },
      }

      local result = config.parse_config(float_config, true) -- silent mode
      
      assert.are.equal('80%', result.window.float.width)
      assert.are.equal('50%', result.window.float.height)
    end)

    it('should accept float with center positioning', function()
      local float_config = {
        window = {
          position = 'float',
          float = {
            width = 60,
            height = 20,
            row = 'center',
            col = 'center',
            relative = 'editor',
          },
        },
      }

      local result = config.parse_config(float_config, true) -- silent mode
      
      assert.are.equal('center', result.window.float.row)
      assert.are.equal('center', result.window.float.col)
    end)

    it('should provide default float configuration', function()
      local float_config = {
        window = {
          position = 'float',
          -- No float config provided
        },
      }

      local result = config.parse_config(float_config, true) -- silent mode
      
      -- Should have default float configuration
      assert.is_not_nil(result.window.float)
      assert.are.equal('80%', result.window.float.width)
      assert.are.equal('80%', result.window.float.height)
      assert.are.equal('center', result.window.float.row)
      assert.are.equal('center', result.window.float.col)
      assert.are.equal('editor', result.window.float.relative)
      assert.are.equal('rounded', result.window.float.border)
    end)
  end)
end)
