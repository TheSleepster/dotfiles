vim.pack.add({
    {src = "https://github.com/vague2k/vague.nvim"},
    {src = "https://github.com/stevearc/oil.nvim"},
    {src = "https://github.com/neovim/nvim-lspconfig"},
    {src = "https://github.com/mason-org/mason.nvim"},
    {src = "https://github.com/mason-org/mason-lspconfig.nvim"},
    {src = "https://github.com/nvim-treesitter/nvim-treesitter", version = vim.version.range("main"), build = ":TSUpdate"},
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
    {src = "https://github.com/casey/tree-sitter-just.git"},
    {src = "https://github.com/nvim-lua/plenary.nvim"},
    {src = "https://github.com/nvim-telescope/telescope.nvim"},
    --{src = "https://github.com/nvim-mini/mini.pick"},
    --{src = "https://github.com/S1M0N38/love2d.nvim"},
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { '<filetype>' },
  callback = function() vim.treesitter.start() end,
})

--require("mini.pick").setup()
require("mason").setup()

require("config.bindings")
require("config.settings")
require("config.treesitter")
require("config.lsp_settings")
require("config.header_guards")
require("config.completion_settings")
require("config.tasks")
require("config.todo_highlighting").setup()
require("config.welcome_screen")

require('new_compile').setup({
    build_command = nil,  -- Will auto-detect based on OS
    window_height = 15,   -- Height of compilation window
    auto_close_on_success = false,  -- Auto-close on successful compile
    focus_on_compile = false,  -- Stay in current window when compiling
})

vim.cmd(":hi statusline guibg=NONE")
vim.cmd("set wildmenu")
--vim.cmd([[:vsplit]])

if vim.g.neovide then
    vim.o.guifont = "LiterationMono Nerd Font Propo:h10"
    vim.g.neovide_refresh_rate = 144.0
    vim.g.neovide_scroll_animation_length = 0.0
    vim.g.neovide_cusor_animation_length = 0.0
    vim.g.neovide_cursor_short_animation_length = 0.0
    vim.g.neovide_cursor_trail_size = 0.0
    vim.g.neovide_cursor_trail_length = 0.0
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_fullscreen = true
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_position_animation_length  = 0.0
    vim.g.neovide_scroll_animation_far_lines = 0.0

    vim.api.nvim_set_keymap('v', '<sc-c>', '"+y', {noremap = true})
    vim.api.nvim_set_keymap('n', '<sc-v>', 'l"+P', {noremap = true})
    vim.api.nvim_set_keymap('v', '<sc-v>', '"+P', {noremap = true})
    vim.api.nvim_set_keymap('c', '<sc-v>', '<C-o>l<C-o>"+<C-o>P<C-o>l', {noremap = true})
    vim.api.nvim_set_keymap('i', '<sc-v>', '<ESC>l"+Pli', {noremap = true})
    vim.api.nvim_set_keymap('t', '<sc-v>', '<C-\\><C-n>"+Pi', {noremap = true})
end

vim.cmd("colorscheme nvim_dark")
vim.cmd("packloadall")
