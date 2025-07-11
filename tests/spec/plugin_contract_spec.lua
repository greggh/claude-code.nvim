local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('Plugin Contract: claude-code.nvim (call version functions)', function()
  it('plugin.version and plugin.get_version should be functions and callable', function()
    package.loaded['claude-code'] = nil -- Clear cache to force fresh load
    local plugin = require('claude-code')
    print('DEBUG: plugin table keys:')
    for k, v in pairs(plugin) do
      print('  ', k, '(', type(v), ')')
    end
    print('DEBUG: plugin.version:', plugin.version)
    print('DEBUG: plugin.get_version:', plugin.get_version)
    print('DEBUG: plugin.version type is', type(plugin.version))
    print('DEBUG: plugin.get_version type is', type(plugin.get_version))
    local ok1, res1 = pcall(plugin.version)
    local ok2, res2 = pcall(plugin.get_version)
    print('DEBUG: plugin.version() call ok:', ok1, 'result:', res1)
    print('DEBUG: plugin.get_version() call ok:', ok2, 'result:', res2)
    if type(plugin.version) ~= 'function' then
      error(
        'plugin.version is not a function, got: '
          .. tostring(plugin.version)
          .. ' (type: '
          .. type(plugin.version)
          .. ')'
      )
    end
    if type(plugin.get_version) ~= 'function' then
      error(
        'plugin.get_version is not a function, got: '
          .. tostring(plugin.get_version)
          .. ' (type: '
          .. type(plugin.get_version)
          .. ')'
      )
    end
    assert.is_true(ok1)
    assert.is_true(ok2)
  end)
end)
