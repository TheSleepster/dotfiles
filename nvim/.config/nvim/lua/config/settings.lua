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

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.cindent = true
vim.opt.backupcopy = "yes"

-- vim.cmd("highlight link TodoKeyword DiagnosticWarn")
-- vim.cmd("highlight link AuthorKeyword DiagnosticInfo")
--
-- -- Matches TODO, FIXME, NOTE, IMPORTANT, HACK, WARN, WARNING, INFO, and optional (Name)
-- local PAT = [[\v<(TODO|FIXME|FIX|NOTE|IMPORTANT|HACK|WARN|WARNING|INFO)(\([^)]*\))?:]]
--
-- local function add_todo_match()
--   if vim.w.todo_match_id then
--     pcall(vim.fn.matchdelete, vim.w.todo_match_id)
--   end
--   vim.w.todo_match_id = vim.fn.matchadd("TodoKeyword", PAT, 1000)
-- end
--
-- vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "ColorScheme" }, {
--   callback = add_todo_match,
-- })
-- vim.api.nvim_create_autocmd({ "BufWinLeave", "WinLeave", "BufWipeout", "BufUnload" }, {
--   callback = function()
--     if vim.w.todo_match_id then
--       pcall(vim.fn.matchdelete, vim.w.todo_match_id)
--       vim.w.todo_match_id = nil
--     end
--   end,
-- })

-- Special C indent options...
local my_cinoptions = "(:s,W4,t0,l1,g0,=0,b1,+0"
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    local bo = vim.bo
    bo.cindent = true
    bo.expandtab = true
    bo.tabstop = 4
    bo.shiftwidth = 4
    bo.softtabstop = 4
    bo.cinoptions = my_cinoptions
  end,
})

-- Mode based cursor + border colors
vim.opt.guicursor = "n-v-c:block-CursorNormal,i:block-CursorInsert,v:block-CursorVisual"
vim.api.nvim_set_hl(0, "MyActiveBorder", {fg = "#5fff5f"})
local function set_mode_highlights(mode)
    if mode == "n" then
        -- Cursor
        vim.opt.guicursor = "n-v-c:block-CursorNormal"
        vim.api.nvim_set_hl(0, "CursorNormal", { fg = "NONE", bg = "#ff0000" })
        vim.api.nvim_set_hl(0, "Cursor",       { fg = "NONE", bg = "#ff0000" })

        -- Borders (all sides red)
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ff0000" }) 
        vim.api.nvim_set_hl(0, "WinBar",       { bg = "#ff0000", fg = "#000000" })
        vim.api.nvim_set_hl(0, "StatusLine",   { bg = "#ff0000", fg = "#000000" })

    elseif mode == "i" then
        -- Cursor only (green)
        vim.opt.guicursor = "i:block-CursorInsert"
        vim.api.nvim_set_hl(0, "CursorInsert", { fg = "NONE", bg = "#5fff5f" })
        vim.api.nvim_set_hl(0, "Cursor",       { fg = "NONE", bg = "#5fff5f" })

        -- Borders = inactive look (clear overrides)
        vim.cmd("highlight clear WinSeparator")
        vim.cmd("highlight clear WinBar")
        vim.cmd("highlight clear StatusLine")

    elseif mode:match("v") or mode:match("V") or mode:match("\22") then
        -- Cursor (blue for visual, visual-line, visual-block)
        vim.opt.guicursor = "v:block-CursorVisual"
        vim.api.nvim_set_hl(0, "CursorVisual", { fg = "NONE", bg = "#5f87ff" })
        vim.api.nvim_set_hl(0, "Cursor",       { fg = "NONE", bg = "#5f87ff" })

        -- Borders (all sides blue)
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5f87ff" })
        vim.api.nvim_set_hl(0, "WinBar",       { bg = "#5f87ff", fg = "#000000" })
        vim.api.nvim_set_hl(0, "StatusLine",   { bg = "#5f87ff", fg = "#000000" })
    end
end

-- Initialize
set_mode_highlights("n")

-- Autocommand to update highlights on mode switch
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    set_mode_highlights(vim.fn.mode())
    vim.api.nvim_set_hl(0, "CursorLine", {bg = "#191970"});
  end,
})

-- Enable vim cursor_line no matter what
vim.cmd[[
    augroup cursorline
        autocmd!
        autocmd WinEnter,BufEnter * lua vim.wo.cursorline = true
        autocmd WinLeave,BufLeave * lua vim.wo.cursorline = false
    augroup END
]]
