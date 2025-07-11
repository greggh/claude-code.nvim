#!/usr/bin/env lua

-- Script to fix common markdown formatting issues
-- This script fixes issues identified by our markdown validation tests

local function read_file(path)
    local file = io.open(path, 'r')
    if not file then
        return nil
    end
    local content = file:read('*a')
    file:close()
    return content
end

local function write_file(path, content)
    local file = io.open(path, 'w')
    if not file then
        return false
    end
    file:write(content)
    file:close()
    return true
end

local function find_markdown_files()
    local files = {}
    local handle = io.popen('find . -name "*.md" -type f 2>/dev/null')
    if handle then
        for line in handle:lines() do
            -- Skip certain files that shouldn't be auto-formatted
            if not line:match('node_modules') and not line:match('%.git') then
                table.insert(files, line)
            end
        end
        handle:close()
    end
    return files
end

local function fix_list_formatting(content)
    local lines = {}
    for line in content:gmatch('[^\n]*') do
        table.insert(lines, line)
    end
    
    local fixed_lines = {}
    local in_code_block = false
    
    for i, line in ipairs(lines) do
        local fixed_line = line
        
        -- Track code blocks
        if line:match('^%s*```') then
            in_code_block = not in_code_block
        end
        
        -- Only fix markdown list formatting if we're not in a code block
        if not in_code_block then
            -- Skip lines that are clearly code comments or special syntax
            local is_code_comment = line:match('^%s*%-%-%s') or   -- Lua comments
                                   line:match('^%s*#') or        -- Shell/Python comments
                                   line:match('^%s*//')          -- C-style comments
            
            -- Skip lines that start with ** (bold text)
            local is_bold_text = line:match('^%s*%*%*')
            
            -- Skip lines that look like YAML or configuration
            local is_config_line = line:match('^%s*%-%s*%w+:') or  -- YAML-style
                                  line:match('^%s*%*%s*%w+:')     -- Config-style
            
            -- Skip lines that are horizontal rules or other markdown syntax
            local is_markdown_syntax = line:match('^%s*%-%-%-+%s*$') or  -- Horizontal rules
                                      line:match('^%s*%*%*%*+%s*$')
            
            if not is_code_comment and not is_bold_text and not is_config_line and not is_markdown_syntax then
                -- Fix - without space (but not --)
                if line:match('^%s*%-[^%-]') and not line:match('^%s*%-%s') then
                    -- Only fix if it looks like a list item (followed by text, not special characters)
                    if line:match('^%s*%-[%w%s]') then
                        fixed_line = line:gsub('^(%s*)%-([^%-])', '%1- %2')
                    end
                end
                
                -- Fix * without space
                if line:match('^%s*%*[^%s%*]') and not line:match('^%s*%*%s') then
                    -- Only fix if it looks like a list item (followed by text)
                    if line:match('^%s*%*[%w%s]') then
                        fixed_line = line:gsub('^(%s*)%*([^%s%*])', '%1* %2')
                    end
                end
            end
        end
        
        table.insert(fixed_lines, fixed_line)
    end
    
    return table.concat(fixed_lines, '\n')
end

local function fix_trailing_whitespace(content)
    local lines = {}
    for line in content:gmatch('[^\n]*') do
        table.insert(lines, line)
    end
    
    local fixed_lines = {}
    for _, line in ipairs(lines) do
        -- Remove trailing whitespace
        local fixed_line = line:gsub('%s+$', '')
        table.insert(fixed_lines, fixed_line)
    end
    
    return table.concat(fixed_lines, '\n')
end

local function fix_markdown_file(filepath)
    local content = read_file(filepath)
    if not content then
        print('Error: Could not read ' .. filepath)
        return false
    end
    
    local original_content = content
    
    -- Apply fixes
    content = fix_list_formatting(content)
    content = fix_trailing_whitespace(content)
    
    -- Only write if content changed
    if content ~= original_content then
        if write_file(filepath, content) then
            print('Fixed: ' .. filepath)
            return true
        else
            print('Error: Could not write ' .. filepath)
            return false
        end
    end
    
    return true
end

-- Main execution
local function main()
    print('Claude Code Markdown Formatter')
    print('==============================')
    
    local md_files = find_markdown_files()
    print('Found ' .. #md_files .. ' markdown files')
    
    local fixed_count = 0
    local error_count = 0
    
    for _, filepath in ipairs(md_files) do
        if fix_markdown_file(filepath) then
            fixed_count = fixed_count + 1
        else
            error_count = error_count + 1
        end
    end
    
    print('')
    print('Results:')
    print('  Files processed: ' .. #md_files)
    print('  Files fixed: ' .. fixed_count)
    print('  Errors: ' .. error_count)
    
    if error_count == 0 then
        print('  Status: SUCCESS')
        return 0
    else
        print('  Status: PARTIAL SUCCESS')
        return 1
    end
end

-- Run the script
local exit_code = main()
os.exit(exit_code)