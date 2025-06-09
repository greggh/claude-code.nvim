" Minimal init.vim for running tests
" Load only the required plugins and settings

" Clear any existing autocommands
autocmd!

" Set up Lua path to include the test directory
let &runtimepath = getcwd() . ',' . &runtimepath

" Basic settings
set noswapfile
set nobackup
set nowritebackup
set noundofile
set nocompatible

" Only load plugins needed for testing
lua << EndOfLua
-- Set up paths properly for testing
local current_dir = vim.fn.getcwd()
vim.opt.runtimepath:append(current_dir)
vim.opt.runtimepath:append(current_dir .. "/lua")

-- Make sure we can find our modules
package.path = package.path .. ";" .. current_dir .. "/lua/?.lua;" .. current_dir .. "/lua/?/init.lua"

-- Set minimal debug information
print("Runtime path: " .. vim.o.runtimepath)
print("Current directory: " .. current_dir)
print("Package path: " .. package.path)

-- We don't load the module here - we'll do it in the test script
EndOfLua