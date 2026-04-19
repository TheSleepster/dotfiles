-- colors/nvim_dark.lua
-- Converted from the Emacs `nvim_dark` theme provided by the user.

local vim = vim
local cmd = vim.cmd
local api = vim.api

-- Clear any existing highlights and set background
if vim.fn.exists("syntax_on") == 1 then
  cmd("syntax reset")
end
vim.opt.background = "dark"
vim.g.colors_name = "nvim_dark"

local C = {
  bg           = "#040404",
  fg           = "#dab98f",

  cursor       = "#00fc5f",
  region       = "#2f363d",
  line         = "#191970",
  fringe       = "#161616",
  modeline_bg  = "#5c6370",
  modeline_inactive_fg = "#5c6370",

  keyword      = "#CD950C",
  type         = "#CD950C",
  string       = "#f4C430",
  function_fg  = "#ff5900",
  variable     = "#dab98f",
  constant     = "#00FF00",
  preproc      = "#ff7a7b",
  comment      = "#5c6370",
  builtin      = "#ff5900",

  escape_glyph = "#6b8e23",
  special_char = "#f4C430",

  operator     = "#FF0000",
  enum_member  = "#1BFC06",
  number       = "#CD950C",

  -- diagnostics underline colors (converted from flymake waves)
  diag_error   = "#fc0505",
  diag_warn    = "#dbc900",
  diag_info    = "#41c101",
}

-- Helper
local function hl(group, props)
  api.nvim_set_hl(0, group, props)
end

-- Basic editor
hl("Normal",            { fg = C.fg, bg = C.bg })
hl("Cursor",            { bg = C.cursor })
hl("Visual",            { bg = C.region })
hl("CursorLine",        { bg = C.line })
hl("LineNr",            { fg = C.modeline_inactive_fg })
hl("CursorLineNr",      { fg = C.keyword, bold = true })
hl("ColorColumn",       { bg = "#1a1a1a" })

-- Statusline / mode-line (map Emacs faces to Vim)
hl("StatusLine",        { fg = C.fg, bg = C.modeline_bg })
hl("StatusLineNC",      { fg = C.modeline_inactive_fg, bg = C.fringe })
hl("WinSeparator",      { fg = C.fringe, bg = C.bg })

-- Basic syntax groups (Vim & Treesitter/modern groups)
hl("Comment",           { fg = C.comment, italic = true })
hl("Constant",          { fg = C.constant })
hl("String",            { fg = C.string })
hl("Character",         { fg = C.string })
hl("Number",            { fg = C.number })
hl("Boolean",           { fg = C.constant })
hl("Float",             { fg = C.number })

hl("Identifier",        { fg = C.variable })
hl("Function",          { fg = C.function_fg })
hl("Statement",         { fg = C.keyword })
hl("Keyword",           { fg = C.keyword })
hl("Operator",          { fg = C.operator })
hl("Type",              { fg = C.type })
hl("StorageClass",      { fg = C.type })
hl("Structure",         { fg = C.type })
hl("Typedef",           { fg = C.type })

hl("PreProc",           { fg = C.preproc })
hl("Special",           { fg = C.special_char })
hl("SpecialChar",       { fg = C.escape_glyph })
hl("Underlined",        { underline = true })

-- Emulate Emacs-specific faces as custom groups (useful for TODO plugins)
hl("NvimDarkImportant", { fg = C.keyword, bold = true, underline = true })
hl("NvimDarkNote",      { fg = C.escape_glyph, bold = true, underline = true })
hl("NvimDarkTodo",      { fg = C.constant, bold = true, underline = true })
-- link builtin Todo to NvimDarkTodo for editors/plugins that use Todo
hl("Todo", { link = "NvimDarkTodo" })

-- Link Vim/standard groups to our colors for consistency
api.nvim_set_hl(0, "Identifier", { link = "Normal" }) -- keep variables same as Normal fg if desired
-- (Above is optional; comment/remove if you'd prefer distinct look)

-- Treesitter highlight groups (nvim-treesitter)
hl("@comment",          { fg = C.comment, italic = true })
hl("@constant",         { fg = C.constant })
hl("@constant.builtin", { fg = C.constant })
hl("@constructor.cpp",  { fg = C.function_fg })
hl("@string",           { fg = C.string })
hl("@number",           { fg = C.number })
hl("@boolean",          { fg = C.constant })
hl("@function",         { fg = C.function_fg })
hl("@function.call",    { fg = C.function_fg })
hl("@function.builtin", { fg = C.builtin })
hl("@method",           { fg = C.function_fg })
hl("@keyword",          { fg = C.keyword })
hl("@operator",         { fg = C.operator })
hl("@type",             { fg = C.type })
hl("@type.builtin",     { fg = C.type })
hl("@variable",         { fg = C.variable })
hl("@property",         { fg = C.variable })
hl("@parameter",        { fg = C.variable })
hl("@preproc",          { fg = C.preproc })
hl("@namespace",        { fg = C.type })
hl("@label",            { fg = C.keyword })
hl("@attribute",        { fg = C.preproc })
hl("@macro",            { fg = C.preproc })
hl("@punctuation",      { fg = C.fg })

-- LSP / diagnostics
hl("DiagnosticError",        { fg = C.diag_error })  -- text color for errors
hl("DiagnosticWarn",         { fg = C.diag_warn })
hl("DiagnosticInfo",         { fg = C.diag_info })
hl("DiagnosticHint",         { fg = C.fg })

-- Underline/undercurl style for diagnostics (similar to flymake waves)
hl("DiagnosticUnderlineError", { undercurl = true, sp = C.diag_error })
hl("DiagnosticUnderlineWarn",  { undercurl = true, sp = C.diag_warn })
hl("DiagnosticUnderlineInfo",  { undercurl = true, sp = C.diag_info })
hl("DiagnosticUnderlineHint",  { undercurl = true, sp = C.diag_info })

-- LSP reference highlight (when reading/writing)
hl("LspReferenceText", { bg = "#1f2226" })
hl("LspReferenceRead", { bg = "#1f2226" })
hl("LspReferenceWrite",{ bg = "#1f2226" })

-- Search and matchparen
hl("Search",          { fg = C.bg, bg = C.keyword, bold = true })
hl("IncSearch",       { fg = C.bg, bg = C.cursor })
hl("MatchParen",      { fg = C.function_fg, bold = true })

-- Git signs & diff
hl("DiffAdd",         { fg = "#cdebb0", bg = nil })
hl("DiffChange",      { fg = "#ffd580", bg = nil })
hl("DiffDelete",      { fg = "#ff9b9b", bg = nil })

-- Airline / Lualine integrations (common groups)
hl("StatusLine",      { fg = C.fg, bg = C.modeline_bg })
hl("StatusLineNC",    { fg = C.modeline_inactive_fg, bg = C.fringe })

hl("@keyword.import.cpp", { fg = "#ff7a7b" })  -- import keywords
hl("@constant.macro.cpp", { fg = "#2898c7" })  -- macros

-- Terminal colors (optional; helps when using built-in terminal)
vim.g.terminal_color_0  = "#101010"
vim.g.terminal_color_1  = "#ff5900"
vim.g.terminal_color_2  = "#1BFC06"
vim.g.terminal_color_3  = "#CD950C"
vim.g.terminal_color_4  = "#00FF00"
vim.g.terminal_color_5  = "#ff7a7b"
vim.g.terminal_color_6  = "#6b8e23"
vim.g.terminal_color_7  = "#dab98f"
vim.g.terminal_color_8  = "#5c6370"
vim.g.terminal_color_9  = "#ff5900"
vim.g.terminal_color_10 = "#1BFC06"
vim.g.terminal_color_11 = "#CD950C"
vim.g.terminal_color_12 = "#00FF00"
vim.g.terminal_color_13 = "#ff7a7b"
vim.g.terminal_color_14 = "#6b8e23"
vim.g.terminal_color_15 = "#ffffff"

hl("StatusLine",   { fg = C.fg, bg = "none" })
hl("StatusLineNC", { fg = C.modeline_inactive_fg, bg = "none" })

-- Done
return vim.g.colors_name

