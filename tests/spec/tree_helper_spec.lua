-- Test-Driven Development: Project Tree Helper Tests
-- Written BEFORE implementation to define expected behavior

describe('Project Tree Helper', function()
  local tree_helper

  -- Mock vim functions for testing
  local original_fn = {}
  local mock_files = {}

  before_each(function()
    -- Save original functions
    original_fn.fnamemodify = vim.fn.fnamemodify
    original_fn.glob = vim.fn.glob
    original_fn.isdirectory = vim.fn.isdirectory
    original_fn.filereadable = vim.fn.filereadable

    -- Clear mock files
    mock_files = {}

    -- Load the module fresh each time
    package.loaded['claude-code.tree_helper'] = nil
    tree_helper = require('claude-code.tree_helper')
  end)

  after_each(function()
    -- Restore original functions
    vim.fn.fnamemodify = original_fn.fnamemodify
    vim.fn.glob = original_fn.glob
    vim.fn.isdirectory = original_fn.isdirectory
    vim.fn.filereadable = original_fn.filereadable
  end)

  describe('generate_tree', function()
    it('should generate simple directory tree', function()
      -- Mock file system
      mock_files = {
        ['/project'] = 'directory',
        ['/project/README.md'] = 'file',
        ['/project/src'] = 'directory',
        ['/project/src/main.lua'] = 'file',
      }

      vim.fn.glob = function(pattern)
        local results = {}
        for path, type in pairs(mock_files) do
          if path:match('^' .. pattern:gsub('%*', '.*')) then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return mock_files[path] == 'file' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        elseif modifier == ':h' then
          return path:match('(.+)/')
        end
        return path
      end

      local result = tree_helper.generate_tree('/project', { max_depth = 2 })

      -- Should contain basic tree structure
      assert.is_true(result:find('README%.md') ~= nil)
      assert.is_true(result:find('src/') ~= nil)
      assert.is_true(result:find('main%.lua') ~= nil)
    end)

    it('should respect max_depth parameter', function()
      -- Mock deep directory structure
      mock_files = {
        ['/project'] = 'directory',
        ['/project/level1'] = 'directory',
        ['/project/level1/level2'] = 'directory',
        ['/project/level1/level2/level3'] = 'directory',
        ['/project/level1/level2/level3/deep.txt'] = 'file',
      }

      vim.fn.glob = function(pattern)
        local results = {}
        local dir = pattern:gsub('/%*$', '')
        for path, type in pairs(mock_files) do
          -- Only return direct children of the directory
          local parent = path:match('(.+)/[^/]+$')
          if parent == dir then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        end
        return path
      end

      local result = tree_helper.generate_tree('/project', { max_depth = 2 })

      -- Should not include files deeper than max_depth
      assert.is_true(result:find('deep%.txt') == nil)
      assert.is_true(result:find('level2') ~= nil)
    end)

    it('should exclude files based on ignore patterns', function()
      -- Mock file system with files that should be ignored
      mock_files = {
        ['/project'] = 'directory',
        ['/project/README.md'] = 'file',
        ['/project/.git'] = 'directory',
        ['/project/node_modules'] = 'directory',
        ['/project/src'] = 'directory',
        ['/project/src/main.lua'] = 'file',
        ['/project/build'] = 'directory',
      }

      vim.fn.glob = function(pattern)
        local results = {}
        for path, type in pairs(mock_files) do
          if path:match('^' .. pattern:gsub('%*', '.*')) then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return mock_files[path] == 'file' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        end
        return path
      end

      local result = tree_helper.generate_tree('/project', {
        ignore_patterns = { '.git', 'node_modules', 'build' },
      })

      -- Should exclude ignored directories
      assert.is_true(result:find('%.git') == nil)
      assert.is_true(result:find('node_modules') == nil)
      assert.is_true(result:find('build') == nil)

      -- Should include non-ignored files
      assert.is_true(result:find('README%.md') ~= nil)
      assert.is_true(result:find('main%.lua') ~= nil)
    end)

    it('should limit number of files when max_files is specified', function()
      -- Mock file system with many files
      mock_files = {
        ['/project'] = 'directory',
      }

      -- Add many files
      for i = 1, 100 do
        mock_files['/project/file' .. i .. '.txt'] = 'file'
      end

      vim.fn.glob = function(pattern)
        local results = {}
        for path, type in pairs(mock_files) do
          if path:match('^' .. pattern:gsub('%*', '.*')) then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return mock_files[path] == 'file' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        end
        return path
      end

      local result = tree_helper.generate_tree('/project', { max_files = 10 })

      -- Should contain truncation notice
      assert.is_true(result:find('%.%.%.') ~= nil or result:find('truncated') ~= nil)

      -- Count actual files in output (rough check)
      local file_count = 0
      for line in result:gmatch('[^\r\n]+') do
        if line:find('file%d+%.txt') then
          file_count = file_count + 1
        end
      end
      assert.is_true(file_count <= 12) -- Allow some buffer for tree formatting
    end)

    it('should handle empty directories gracefully', function()
      -- Mock empty directory
      mock_files = {
        ['/project'] = 'directory',
      }

      vim.fn.glob = function(pattern)
        return ''
      end

      vim.fn.isdirectory = function(path)
        return path == '/project' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        end
        return path
      end

      local result = tree_helper.generate_tree('/project')

      -- Should handle empty directory without crashing
      assert.is_string(result)
      assert.is_true(#result > 0)
    end)

    it('should include file size information when show_size is true', function()
      -- Mock file system
      mock_files = {
        ['/project'] = 'directory',
        ['/project/small.txt'] = 'file',
        ['/project/large.txt'] = 'file',
      }

      vim.fn.glob = function(pattern)
        local results = {}
        for path, type in pairs(mock_files) do
          if path:match('^' .. pattern:gsub('%*', '.*')) then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return mock_files[path] == 'file' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        end
        return path
      end

      -- Mock getfsize function
      local original_getfsize = vim.fn.getfsize
      vim.fn.getfsize = function(path)
        if path:find('small') then
          return 1024
        elseif path:find('large') then
          return 1048576
        end
        return 0
      end

      local result = tree_helper.generate_tree('/project', { show_size = true })

      -- Should include size information
      assert.is_true(result:find('1%.0KB') ~= nil or result:find('1024') ~= nil)
      assert.is_true(result:find('1%.0MB') ~= nil or result:find('1048576') ~= nil)

      -- Restore getfsize
      vim.fn.getfsize = original_getfsize
    end)
  end)

  describe('get_project_tree_context', function()
    it('should generate markdown formatted tree context', function()
      -- Mock git module
      package.loaded['claude-code.git'] = {
        get_root = function()
          return '/project'
        end,
      }

      -- Mock simple file system
      mock_files = {
        ['/project'] = 'directory',
        ['/project/README.md'] = 'file',
        ['/project/src'] = 'directory',
        ['/project/src/main.lua'] = 'file',
      }

      vim.fn.glob = function(pattern)
        local results = {}
        for path, type in pairs(mock_files) do
          if path:match('^' .. pattern:gsub('%*', '.*')) then
            table.insert(results, path)
          end
        end
        return table.concat(results, '\n')
      end

      vim.fn.isdirectory = function(path)
        return mock_files[path] == 'directory' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return mock_files[path] == 'file' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        elseif modifier == ':h' then
          return path:match('(.+)/')
        elseif modifier == ':~:.' then
          return path:gsub('^/project/?', './')
        end
        return path
      end

      local result = tree_helper.get_project_tree_context()

      -- Should be markdown formatted
      assert.is_true(result:find('# Project Structure') ~= nil)
      assert.is_true(result:find('```') ~= nil)
      assert.is_true(result:find('README%.md') ~= nil)
      assert.is_true(result:find('main%.lua') ~= nil)
    end)

    it('should handle missing git root gracefully', function()
      -- Mock git module that returns nil
      package.loaded['claude-code.git'] = {
        get_root = function()
          return nil
        end,
      }

      local result = tree_helper.get_project_tree_context()

      -- Should return informative message
      assert.is_string(result)
      assert.is_true(result:find('Project Structure') ~= nil)
    end)
  end)

  describe('create_tree_file', function()
    it('should create temporary file with tree content', function()
      -- Mock git and file system
      package.loaded['claude-code.git'] = {
        get_root = function()
          return '/project'
        end,
      }

      mock_files = {
        ['/project'] = 'directory',
        ['/project/test.lua'] = 'file',
      }

      vim.fn.glob = function(pattern)
        return '/project/test.lua'
      end

      vim.fn.isdirectory = function(path)
        return path == '/project' and 1 or 0
      end

      vim.fn.filereadable = function(path)
        return path == '/project/test.lua' and 1 or 0
      end

      vim.fn.fnamemodify = function(path, modifier)
        if modifier == ':t' then
          return path:match('([^/]+)$')
        elseif modifier == ':~:.' then
          return path:gsub('^/project/?', './')
        end
        return path
      end

      -- Mock tempname and writefile
      local temp_file = '/tmp/tree_context.md'
      local written_content = nil

      local original_tempname = vim.fn.tempname
      local original_writefile = vim.fn.writefile

      vim.fn.tempname = function()
        return temp_file
      end

      vim.fn.writefile = function(lines, filename)
        written_content = table.concat(lines, '\n')
        return 0
      end

      local result_file = tree_helper.create_tree_file()

      -- Should return temp file path
      assert.equals(temp_file, result_file)

      -- Should write content
      assert.is_string(written_content)
      assert.is_true(written_content:find('Project Structure') ~= nil)

      -- Restore functions
      vim.fn.tempname = original_tempname
      vim.fn.writefile = original_writefile
    end)
  end)
end)
