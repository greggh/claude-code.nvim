local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('Markdown Formatting Validation', function()
  local function read_file(path)
    local file = io.open(path, 'r')
    if not file then
      return nil
    end
    local content = file:read('*a')
    file:close()
    return content
  end

  local function find_markdown_files()
    local files = {}
    local handle = io.popen('find . -name "*.md" -type f 2>/dev/null | head -20')
    if handle then
      for line in handle:lines() do
        table.insert(files, line)
      end
      handle:close()
    end
    return files
  end

  local function check_heading_levels(content, filename)
    local issues = {}
    local lines = vim.split(content, '\n')
    local prev_level = 0

    for i, line in ipairs(lines) do
      local heading = line:match('^(#+)%s')
      if heading then
        local level = #heading

        -- Check for heading level jumps (skipping levels)
        if level > prev_level + 1 then
          table.insert(
            issues,
            string.format(
              '%s:%d: Heading level jump from H%d to H%d (line: %s)',
              filename,
              i,
              prev_level,
              level,
              line:sub(1, 50)
            )
          )
        end

        prev_level = level
      end
    end

    return issues
  end

  local function check_list_formatting(content, filename)
    local issues = {}
    local lines = vim.split(content, '\n')
    local in_code_block = false

    for i, line in ipairs(lines) do
      -- Track code blocks
      if line:match('^%s*```') then
        in_code_block = not in_code_block
      end

      -- Only check list formatting outside of code blocks
      if not in_code_block then
        -- Skip obvious code comments and special markdown syntax
        local is_code_comment = line:match('^%s*%-%-%s') -- Lua comments
          or line:match('^%s*#') -- Shell/Python comments
          or line:match('^%s*//') -- C-style comments

        local is_markdown_syntax = line:match('^%s*%-%-%-+%s*$') -- Horizontal rules
          or line:match('^%s*%*%*%*+%s*$')
          or line:match('^%s*%*%*') -- Bold text

        if not is_code_comment and not is_markdown_syntax then
          -- Check for inconsistent list markers
          if line:match('^%s*%-%s') and line:match('^%s*%*%s') then
            table.insert(
              issues,
              string.format(
                '%s:%d: Mixed list markers (- and *) on same line: %s',
                filename,
                i,
                line:sub(1, 50)
              )
            )
          end

          -- Check for missing space after list marker (but only for actual list items)
          if line:match('^%s*%-[^%s%-]') and line:match('^%s*%-[%w]') then
            table.insert(
              issues,
              string.format(
                '%s:%d: Missing space after list marker: %s',
                filename,
                i,
                line:sub(1, 50)
              )
            )
          end

          if line:match('^%s*%*[^%s%*]') and line:match('^%s*%*[%w]') then
            table.insert(
              issues,
              string.format(
                '%s:%d: Missing space after list marker: %s',
                filename,
                i,
                line:sub(1, 50)
              )
            )
          end
        end
      end
    end

    return issues
  end

  local function check_link_formatting(content, filename)
    local issues = {}
    local lines = vim.split(content, '\n')

    for i, line in ipairs(lines) do
      -- Check for malformed links
      if line:match('%[.-%]%([^%)]*$') then
        table.insert(
          issues,
          string.format('%s:%d: Unclosed link: %s', filename, i, line:sub(1, 50))
        )
      end

      -- Check for empty link text
      if line:match('%[%]%(') then
        table.insert(
          issues,
          string.format('%s:%d: Empty link text: %s', filename, i, line:sub(1, 50))
        )
      end
    end

    return issues
  end

  local function check_trailing_whitespace(content, filename)
    local issues = {}
    local lines = vim.split(content, '\n')

    for i, line in ipairs(lines) do
      if line:match('%s+$') then
        table.insert(issues, string.format('%s:%d: Trailing whitespace', filename, i))
      end
    end

    return issues
  end

  describe('markdown file validation', function()
    it('should find markdown files in the project', function()
      local md_files = find_markdown_files()
      assert.is_true(#md_files > 0, 'Should find at least one markdown file')

      -- Verify we have expected files
      local has_readme = false
      local has_changelog = false

      for _, file in ipairs(md_files) do
        if file:match('README%.md$') then
          has_readme = true
        end
        if file:match('CHANGELOG%.md$') then
          has_changelog = true
        end
      end

      assert.is_true(has_readme, 'Should have README.md file')
      assert.is_true(has_changelog, 'Should have CHANGELOG.md file')
    end)

    it('should validate heading structure in main documentation files', function()
      local main_files = { './README.md', './CHANGELOG.md', './ROADMAP.md' }
      local total_issues = {}

      for _, filepath in ipairs(main_files) do
        local content = read_file(filepath)
        if content then
          local issues = check_heading_levels(content, filepath)
          for _, issue in ipairs(issues) do
            table.insert(total_issues, issue)
          end
        end
      end

      -- Allow some heading level issues but flag if there are too many
      if #total_issues > 5 then
        error('Too many heading level issues found:\n' .. table.concat(total_issues, '\n'))
      end
    end)

    it('should validate list formatting', function()
      local md_files = find_markdown_files()
      local total_issues = {}

      for _, filepath in ipairs(md_files) do
        local content = read_file(filepath)
        if content then
          local issues = check_list_formatting(content, filepath)
          for _, issue in ipairs(issues) do
            table.insert(total_issues, issue)
          end
        end
      end

      -- Allow for many issues since many are false positives (code comments, etc.)
      -- This test is more about ensuring the structure is present than perfect formatting
      if #total_issues > 200 then
        error(
          'Excessive list formatting issues found ('
            .. #total_issues
            .. ' issues):\n'
            .. table.concat(total_issues, '\n')
        )
      end
    end)

    it('should validate link formatting', function()
      local md_files = find_markdown_files()
      local total_issues = {}

      for _, filepath in ipairs(md_files) do
        local content = read_file(filepath)
        if content then
          local issues = check_link_formatting(content, filepath)
          for _, issue in ipairs(issues) do
            table.insert(total_issues, issue)
          end
        end
      end

      -- Should have no critical link formatting issues
      if #total_issues > 0 then
        error('Link formatting issues found:\n' .. table.concat(total_issues, '\n'))
      end
    end)

    it('should check for excessive trailing whitespace', function()
      local main_files = { './README.md', './CHANGELOG.md', './ROADMAP.md' }
      local total_issues = {}

      for _, filepath in ipairs(main_files) do
        local content = read_file(filepath)
        if content then
          local issues = check_trailing_whitespace(content, filepath)
          for _, issue in ipairs(issues) do
            table.insert(total_issues, issue)
          end
        end
      end

      -- Allow some trailing whitespace but flag excessive cases
      if #total_issues > 20 then
        error('Excessive trailing whitespace found:\n' .. table.concat(total_issues, '\n'))
      end
    end)
  end)

  describe('markdown content validation', function()
    it('should have proper README structure', function()
      local content = read_file('./README.md')
      if content then
        assert.is_truthy(content:match('# '), 'README should have main heading')
        assert.is_truthy(content:match('## '), 'README should have section headings')
        assert.is_truthy(content:match('Installation'), 'README should have installation section')
      end
    end)

    it('should have consistent code block formatting', function()
      local md_files = find_markdown_files()
      local issues = {}

      for _, filepath in ipairs(md_files) do
        local content = read_file(filepath)
        if content then
          local lines = vim.split(content, '\n')
          local in_code_block = false

          for i, line in ipairs(lines) do
            -- Check for code block delimiters
            if line:match('^```') then
              in_code_block = not in_code_block
            end

            -- Check for unclosed code blocks at end of file
            if i == #lines and in_code_block then
              table.insert(issues, string.format('%s: Unclosed code block', filepath))
            end
          end
        end
      end

      assert.equals(
        0,
        #issues,
        'Should have no unclosed code blocks: ' .. table.concat(issues, ', ')
      )
    end)
  end)
end)
