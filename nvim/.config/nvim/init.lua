vim.pack.add({
    {src = "https://github.com/vague2k/vague.nvim"},
    {src = "https://github.com/stevearc/oil.nvim"},
    {src = "https://github.com/neovim/nvim-lspconfig"},
    {src = "https://github.com/mason-org/mason.nvim"},
    {src = "https://github.com/mason-org/mason-lspconfig.nvim"},
    {src = "https://github.com/nvim-treesitter/nvim-treesitter"},
    {src = "https://github.com/nvim-mini/mini.pick"},
    {src = "https://github.com/hrsh7th/nvim-cmp"},
    {src = "https://github.com/hrsh7th/cmp-nvim-lsp"},
    {src = "https://github.com/hrsh7th/cmp-path"},
    {src = "https://github.com/hrsh7th/cmp-buffer"},
    {src = "https://github.com/goolord/alpha-nvim"},
    {src = "https://github.com/neanias/everforest-nvim"},
    {src = "https://github.com/folke/tokyonight.nvim"},
    {src = "https://github.com/shaunsingh/nord.nvim"},
    {src = "https://github.com/rose-pine/neovim"},
    {src = "https://github.com/ellisonleao/gruvbox.nvim"},
    {src = "https://github.com/projekt0n/github-nvim-theme"},
    {src = "https://github.com/aikhe/fleur.nvim.git"},
    {src = "https://github.com/gmr458/vscode_modern_theme.nvim.git"},
    {src = "https://github.com/catppuccin/nvim"},
    {src = "https://github.com/rluba/jai.vim"},
    {src = "https://github.com/mbbill/undotree"},
    --{src = "https://github.com/S1M0N38/love2d.nvim"},
})

require("nvim-treesitter.configs").setup({
    ensure_installed = { "lua", "c", "cpp", "rust", "glsl", "slang"},
    highlight = { enable = true }
})

require("mini.pick").setup()
require("mason").setup()

require("config.bindings")
require("config.settings")
require("config.lsp_settings")
require("config.header_guards")
require("config.completion_settings")
require("config.tasks")
require("config.todo_highlighting").setup()
--require("config.welcome_screen")

require('compile').setup({
    build_command = nil,  -- Will auto-detect based on OS
    window_height = 15,   -- Height of compilation window
    auto_close_on_success = false,  -- Auto-close on successful compile
    focus_on_compile = false,  -- Stay in current window when compiling
})

vim.cmd[[
    augroup cursorline
        autocmd!
        autocmd WinEnter,BufEnter * lua vim.wo.cursorline = true
        autocmd WinLeave,BufLeave * lua vim.wo.cursorline = false
    augroup END
]]

vim.cmd(":hi statusline guibg=NONE")
vim.cmd("set wildmenu")
--vim.cmd([[:vsplit]])

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.cindent = true

local my_cinoptions = "(:s,W4,t0,l1,g0,=0,b1,+0"

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
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

-- Autocommand to update highlights on mode switch
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    set_mode_highlights(vim.fn.mode())
    vim.api.nvim_set_hl(0, "CursorLine", {bg = "#191970"});
  end,
})

-- Initialize
set_mode_highlights("n")

if vim.g.neovide then
    vim.o.guifont = "LiterationMono Nerd Font Propo:h6"
    vim.g.neovide_refresh_rate = 60
    vim.g.neovide_scroll_animation_length = 0.0
    vim.g.neovide_cusor_animation_length = 0.0
    vim.g.neovide_cursor_short_animation_length = 0.0
    vim.g.neovide_cursor_trail_size = 0.0
    vim.g.neovide_cursor_trail_length = 0.0
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_fullscreen = true
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_position_animation_length  = 0
    vim.g.neovide_scroll_animation_far_lines = 0

    vim.api.nvim_set_keymap('v', '<sc-c>', '"+y', {noremap = true})
    vim.api.nvim_set_keymap('n', '<sc-v>', 'l"+P', {noremap = true})
    vim.api.nvim_set_keymap('v', '<sc-v>', '"+P', {noremap = true})
    vim.api.nvim_set_keymap('c', '<sc-v>', '<C-o>l<C-o>"+<C-o>P<C-o>l', {noremap = true})
    vim.api.nvim_set_keymap('i', '<sc-v>', '<ESC>l"+Pli', {noremap = true})
    vim.api.nvim_set_keymap('t', '<sc-v>', '<C-\\><C-n>"+Pi', {noremap = true})
end

vim.cmd("colorscheme retrobox")
vim.cmd("packloadall")
