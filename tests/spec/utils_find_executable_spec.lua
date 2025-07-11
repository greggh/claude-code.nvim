local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('utils find_executable enhancements', function()
  local utils
  local original_executable
  local original_popen

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.utils'] = nil
    utils = require('claude-code.utils')

    -- Store originals
    original_executable = vim.fn.executable
    original_popen = io.popen
  end)

  after_each(function()
    -- Restore originals
    vim.fn.executable = original_executable
    io.popen = original_popen
  end)

  describe('find_executable with paths', function()
    it('should find executable from array of paths', function()
      -- Mock vim.fn.executable
      vim.fn.executable = function(path)
        if path == '/usr/bin/git' then
          return 1
        end
        return 0
      end

      local result = utils.find_executable({ '/usr/local/bin/git', '/usr/bin/git', 'git' })
      assert.equals('/usr/bin/git', result)
    end)

    it('should return nil if no executable found', function()
      vim.fn.executable = function()
        return 0
      end

      local result = utils.find_executable({ '/usr/local/bin/git', '/usr/bin/git' })
      assert.is_nil(result)
    end)
  end)

  describe('find_executable_by_name', function()
    it('should find executable by name using which/where', function()
      -- Mock vim.fn.has to ensure we're not on Windows
      local original_has = vim.fn.has
      vim.fn.has = function(feature)
        return 0
      end

      -- Mock vim.fn.shellescape
      local original_shellescape = vim.fn.shellescape
      vim.fn.shellescape = function(str)
        return "'" .. str .. "'"
      end

      -- Mock io.popen for which command
      io.popen = function(cmd)
        if cmd:match("which 'git'") then
          return {
            read = function()
              return '/usr/bin/git'
            end,
            close = function()
              return 0
            end,
          }
        end
        return nil
      end

      -- Mock vim.fn.executable to verify the path
      vim.fn.executable = function(path)
        if path == '/usr/bin/git' then
          return 1
        end
        return 0
      end

      local result = utils.find_executable_by_name('git')
      assert.equals('/usr/bin/git', result)

      -- Restore
      vim.fn.has = original_has
      vim.fn.shellescape = original_shellescape
    end)

    it('should handle Windows where command', function()
      -- Mock vim.fn.has to simulate Windows
      local original_has = vim.fn.has
      vim.fn.has = function(feature)
        if feature == 'win32' or feature == 'win64' then
          return 1
        end
        return 0
      end

      -- Mock vim.fn.shellescape
      local original_shellescape = vim.fn.shellescape
      vim.fn.shellescape = function(str)
        return str -- Windows doesn't need quotes
      end

      -- Mock io.popen for where command
      io.popen = function(cmd)
        if cmd:match('where git') then
          return {
            read = function()
              return 'C:\\Program Files\\Git\\bin\\git.exe'
            end,
            close = function()
              return 0
            end,
          }
        end
        return nil
      end

      -- Mock vim.fn.executable
      vim.fn.executable = function(path)
        if path == 'C:\\Program Files\\Git\\bin\\git.exe' then
          return 1
        end
        return 0
      end

      local result = utils.find_executable_by_name('git')
      assert.equals('C:\\Program Files\\Git\\bin\\git.exe', result)

      -- Restore
      vim.fn.has = original_has
      vim.fn.shellescape = original_shellescape
    end)

    it('should return nil if executable not found', function()
      io.popen = function(cmd)
        if cmd:match('which') or cmd:match('where') then
          return {
            read = function()
              return ''
            end,
            close = function()
              return true, 'exit', 1
            end,
          }
        end
        return nil
      end

      local result = utils.find_executable_by_name('nonexistent')
      assert.is_nil(result)
    end)

    it('should validate path before returning', function()
      -- Mock io.popen to return a path
      io.popen = function(cmd)
        if cmd:match('which git') then
          return {
            read = function()
              return '/usr/bin/git\n'
            end,
            close = function()
              return true, 'exit', 0
            end,
          }
        end
        return nil
      end

      -- Mock vim.fn.executable to reject the path
      vim.fn.executable = function()
        return 0
      end

      local result = utils.find_executable_by_name('git')
      assert.is_nil(result)
    end)
  end)
end)
