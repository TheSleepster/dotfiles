vim.o.guicursor = "a:block-Cursor"
vim.o.guicursor = blinkon0

vim.o.clipboard = "unnamedplus"
vim.o.nu = false
vim.o.relativenumber = false

vim.o.wrap = false

vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true

vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.termguicolors = true
vim.o.autochdir = true;

vim.o.scrolloff = 8
vim.o.signcolumn = "no"
vim.opt.isfname:append("@-@")
vim.api.nvim_set_hl(0, "CInactiveRegion", {})

vim.cmd("highlight link TodoKeyword DiagnosticWarn")
vim.cmd("highlight link AuthorKeyword DiagnosticInfo")

-- Matches TODO, FIXME, NOTE, IMPORTANT, HACK, WARN, WARNING, INFO, and optional (Name)
local PAT = [[\v<(TODO|FIXME|FIX|NOTE|IMPORTANT|HACK|WARN|WARNING|INFO)(\([^)]*\))?:]]

local function add_todo_match()
  if vim.w.todo_match_id then
    pcall(vim.fn.matchdelete, vim.w.todo_match_id)
  end
  vim.w.todo_match_id = vim.fn.matchadd("TodoKeyword", PAT, 1000)
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "ColorScheme" }, {
  callback = add_todo_match,
})
vim.api.nvim_create_autocmd({ "BufWinLeave", "WinLeave", "BufWipeout", "BufUnload" }, {
  callback = function()
    if vim.w.todo_match_id then
      pcall(vim.fn.matchdelete, vim.w.todo_match_id)
      vim.w.todo_match_id = nil
    end
  end,
})

