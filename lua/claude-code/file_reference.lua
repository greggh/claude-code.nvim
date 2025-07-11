local M = {}

local function get_file_reference()
  local fname = vim.fn.expand('%:t')
  local start_line, end_line
  if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
    start_line = vim.fn.line('v')
    end_line = vim.fn.line('.')
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
  else
    start_line = vim.fn.line('.')
    end_line = start_line
  end
  if start_line == end_line then
    return string.format('@%s#L%d', fname, start_line)
  else
    return string.format('@%s#L%d-%d', fname, start_line, end_line)
  end
end

function M.insert_file_reference()
  local ref = get_file_reference()
  -- Insert into Claude prompt input buffer (assume require('claude-code').insert_into_prompt exists)
  if pcall(require, 'claude-code') and require('claude-code').insert_into_prompt then
    require('claude-code').insert_into_prompt(ref)
  else
    -- fallback: put on command line
    vim.api.nvim_feedkeys(ref, 'n', false)
  end
end

return M
