-- 4coder theme for Neovim with full Treesitter and LSP semantic token support
-- Based on Allen Webster's 4coder default theme
-- Place in ~/.config/nvim/colors/4coder.lua

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.g.colors_name = 'four_coder'
vim.o.background = 'dark'

-- Core 4coder color palette (ARGB format from 4coder converted to #RRGGBB)
local colors = {
  -- Base colors
  bg = '#0C0C0C',          -- defcolor_back
  fg = '#90B080',          -- defcolor_text_default (greenish-gray text)
  fg_dim = '#708060',      -- Dimmed version of default text
  
  -- Syntax colors
  keyword = '#D08F20',     -- defcolor_keyword (orange/amber)
  string = '#50FF30',      -- defcolor_str_constant (bright green)
  number = '#30E0B0',      -- defcolor_int_constant (cyan/teal)
  comment = '#2090F0',     -- defcolor_comment (blue)
  comment_keyword = '#00A000', -- TODO, NOTE, etc.
  comment_error = '#F04040', -- HACK, FIXME, etc.
  preproc = '#D08F20',     -- defcolor_preproc (same as keyword in 4coder)
  
  -- UI colors
  cursor = '#40FF40',      -- defcolor_cursor (bright green)
  cursor_alt = '#EE7700',  -- Alternate cursor color
  selection = '#104010',   -- Selection background
  line_number = '#404040', -- Line numbers
  line_number_active = '#808080', -- Active line number
  visual = '#1A4D1A',      -- Visual selection
  
  -- Editor chrome
  gutter = '#0C0C0C',      -- Same as background
  border = '#202020',      -- Borders and separators
  statusline = '#1A1A1A',  -- Status line background
  statusline_fg = '#808080', -- Status line text
  
  -- Semantic highlighting (based on 4coder's code indexer)
  type = '#90B080',        -- Types - same as default text in 4coder
  function_name = '#D08F20', -- Functions - same as keywords (orange/amber)
  macro = '#60D0A0',       -- Macros - cyan-green
  
  -- Diagnostics
  error = '#FF4040',
  warning = '#FFB020',
  info = '#40B0FF',
  hint = '#60D080',
  
  -- Diff colors
  diff_add = '#00FF00',
  diff_delete = '#FF0000',
  diff_change = '#FFB000',
  
  -- Special
  special = '#FF60A0',     -- Special characters
  ghost = '#404040',       -- Ghost/faded text
  
  -- Whitespace and non-text
  nontext = '#303030',
  whitespace = '#282828',
}

local function hi(group, opts)
  -- Skip if opts is empty (used to avoid overriding)
  if vim.tbl_isempty(opts) then
    return
  end
  
  local cmd = 'highlight ' .. group
  if opts.fg then cmd = cmd .. ' guifg=' .. opts.fg end
  if opts.bg then cmd = cmd .. ' guibg=' .. opts.bg end
  if opts.bold then cmd = cmd .. ' gui=bold' end
  if opts.italic then cmd = cmd .. ' gui=italic' end
  if opts.underline then cmd = cmd .. ' gui=underline' end
  if opts.undercurl then cmd = cmd .. ' gui=undercurl guisp=' .. (opts.sp or opts.fg) end
  if opts.reverse then cmd = cmd .. ' gui=reverse' end
  if opts.strikethrough then cmd = cmd .. ' gui=strikethrough' end
  if opts.link then cmd = cmd .. ' link=' .. opts.link end
  vim.cmd(cmd)
end

-- Editor UI
hi('Normal', { fg = colors.fg, bg = colors.bg })
hi('NormalFloat', { fg = colors.fg, bg = colors.statusline })
hi('NormalNC', { fg = colors.fg_dim, bg = colors.bg })
hi('Cursor', { fg = colors.bg, bg = colors.cursor })
hi('CursorLine', { bg = '#0E0E0E' })
hi('CursorLineNr', { fg = colors.line_number_active, bold = true })
hi('LineNr', { fg = colors.line_number })
hi('SignColumn', { bg = colors.gutter })
hi('ColorColumn', { bg = '#1A0000' })
hi('Visual', { bg = colors.visual })
hi('VisualNOS', { bg = colors.visual })
hi('Search', { fg = colors.bg, bg = '#FFB000' })
hi('IncSearch', { fg = colors.bg, bg = colors.cursor })
hi('MatchParen', { fg = colors.cursor, bold = true })
hi('NonText', { fg = colors.nontext })
hi('Whitespace', { fg = colors.whitespace })
hi('SpecialKey', { fg = colors.nontext })
hi('EndOfBuffer', { fg = colors.border })

-- Statusline & Tabline
hi('StatusLine', { fg = colors.statusline_fg, bg = colors.statusline })
hi('StatusLineNC', { fg = colors.fg_dim, bg = colors.bg })
hi('TabLine', { fg = colors.fg_dim, bg = colors.statusline })
hi('TabLineSel', { fg = colors.fg, bg = colors.bg, bold = true })
hi('TabLineFill', { bg = colors.border })

-- Pmenu (completion menu)
hi('Pmenu', { fg = colors.fg, bg = colors.statusline })
hi('PmenuSel', { fg = colors.bg, bg = colors.cursor })
hi('PmenuSbar', { bg = colors.border })
hi('PmenuThumb', { bg = colors.fg_dim })

-- Splits and windows
hi('VertSplit', { fg = colors.border, bg = colors.bg })
hi('WinSeparator', { fg = colors.border })
hi('Folded', { fg = colors.fg_dim, bg = colors.statusline })
hi('FoldColumn', { fg = colors.fg_dim, bg = colors.gutter })

-- Messages
hi('ErrorMsg', { fg = colors.error })
hi('WarningMsg', { fg = colors.warning })
hi('ModeMsg', { fg = colors.info })
hi('MoreMsg', { fg = colors.hint })
hi('Question', { fg = colors.hint })

-- ============================================================================
-- Syntax Highlighting (fallback for non-Treesitter)
-- ============================================================================
hi('Comment', { fg = colors.comment })
hi('Constant', { fg = colors.number })
hi('String', { fg = colors.string })
hi('Character', { fg = colors.string })
hi('Number', { fg = colors.number })
hi('Boolean', { fg = colors.number })
hi('Float', { fg = colors.number })
hi('Identifier', { fg = colors.fg })
hi('Function', { fg = colors.function_name })
hi('Statement', { fg = colors.keyword })
hi('Conditional', { fg = colors.keyword })
hi('Repeat', { fg = colors.keyword })
hi('Label', { fg = colors.keyword })
hi('Operator', { fg = colors.fg })
hi('Keyword', { fg = colors.keyword })
hi('Exception', { fg = colors.keyword })
hi('PreProc', { fg = colors.preproc })
hi('Include', { fg = colors.preproc })
hi('Define', { fg = colors.preproc })
hi('Macro', { fg = colors.macro })
hi('PreCondit', { fg = colors.preproc })
hi('Type', { fg = colors.type })
hi('StorageClass', { fg = colors.keyword })
hi('Structure', { fg = colors.type })
hi('Typedef', { fg = colors.type })
hi('Special', { fg = colors.special })
hi('SpecialChar', { fg = colors.special })
hi('Tag', { fg = colors.type })
hi('Delimiter', { fg = colors.fg })
hi('SpecialComment', { fg = colors.comment_keyword })
hi('Debug', { fg = colors.special })
hi('Underlined', { fg = colors.info, underline = true })
hi('Ignore', { fg = colors.ghost })
hi('Error', { fg = colors.error })
hi('Todo', { fg = colors.comment_keyword, bold = true })

-- ============================================================================
-- Treesitter Syntax Highlighting
-- ============================================================================
-- Comments
hi('@comment', { fg = colors.comment })
hi('@comment.documentation', { fg = colors.comment })
hi('@comment.error', { fg = colors.comment_error, bold = true })
hi('@comment.warning', { fg = colors.warning, bold = true })
hi('@comment.todo', { fg = colors.comment_keyword, bold = true })
hi('@comment.note', { fg = colors.comment_keyword, bold = true })

-- Constants
hi('@constant', { fg = colors.fg })
hi('@constant.builtin', { fg = colors.keyword })
hi('@constant.macro', { fg = colors.macro })
hi('@string', { fg = colors.string })
hi('@string.escape', { fg = colors.string})
hi('@string.special', { fg = colors.special })
hi('@character', { fg = colors.string })
hi('@character.special', { fg = colors.special })
hi('@number', { fg = colors.string })
hi('@boolean', { fg = colors.string })
hi('@float', { fg = colors.number })

-- Functions
hi('@function', { fg = colors.fg })
hi('@function.builtin', { fg = colors.function_name })
hi('@function.call', { fg = colors.fg })
hi('@function.macro', { fg = colors.macro })
hi('@method', { fg = colors.function_name })
hi('@method.call', { fg = colors.function_name })
hi('@constructor', { fg = colors.type })
hi('@parameter', { fg = colors.fg })

-- Keywords
hi('@keyword', { fg = colors.keyword })
hi('@keyword.function', { fg = colors.keyword })
hi('@keyword.operator', { fg = colors.keyword })
hi('@keyword.return', { fg = colors.keyword })
hi('@keyword.import', { fg = colors.preproc })
hi('@conditional', { fg = colors.keyword })
hi('@repeat', { fg = colors.keyword })
hi('@label', { fg = colors.keyword })
hi('@operator', { fg = colors.fg })
hi('@exception', { fg = colors.keyword })
hi('@keyword.directive', { fg = colors.preproc })
hi('@keyword.directive.define', { fg = colors.preproc })

-- Types
hi('@type', { fg = colors.type })
hi('@type.builtin', { fg = colors.keyword })
hi('@type.definition', { fg = colors.type })
hi('@type.qualifier', { fg = colors.keyword })
hi('@storageclass', { fg = colors.keyword })
hi('@attribute', { fg = colors.preproc })
hi('@field', { fg = colors.fg })
hi('@property', { fg = colors.fg })

-- Identifiers
hi('@variable', { fg = colors.fg })
hi('@variable.builtin', { fg = colors.keyword })
hi('@variable.parameter', { fg = colors.fg })
hi('@variable.member', { fg = colors.fg })

-- Text
hi('@text', { fg = colors.fg })
hi('@text.strong', { bold = true })
hi('@text.emphasis', { italic = true })
hi('@text.underline', { underline = true })
hi('@text.strike', { fg = colors.ghost })
hi('@text.title', { fg = colors.type, bold = true })
hi('@text.literal', { fg = colors.string })
hi('@text.uri', { fg = colors.info, underline = true })
hi('@text.math', { fg = colors.number })
hi('@text.reference', { fg = colors.function_name })
hi('@text.environment', { fg = colors.macro })
hi('@text.environment.name', { fg = colors.type })
hi('@text.note', { fg = colors.comment_keyword })
hi('@text.warning', { fg = colors.warning })
hi('@text.danger', { fg = colors.error })

-- Tags (HTML, XML, etc.)
hi('@tag', { fg = colors.function_name })
hi('@tag.attribute', { fg = colors.fg })
hi('@tag.delimiter', { fg = colors.fg })

-- Misc
hi('@punctuation', { fg = colors.fg })
hi('@punctuation.delimiter', { fg = colors.fg })
hi('@punctuation.bracket', { fg = colors.fg })
hi('@punctuation.special', { fg = colors.special })

hi('@macro', { fg = colors.macro })
hi('@namespace', { fg = colors.type })
hi('@symbol', { fg = colors.fg })

-- ============================================================================
-- LSP Semantic Tokens
-- This is critical to override Treesitter for accurate semantic highlighting
-- ============================================================================
hi('@lsp.type.namespace', { fg = colors.fg })
hi('@lsp.type.type', { fg = colors.fg })
hi('@lsp.type.class', { fg = colors.fg })
hi('@lsp.type.enum', { fg = colors.fg })
hi('@lsp.type.interface', { fg = colors.fg })
hi('@lsp.type.struct', { fg = colors.fg })
hi('@lsp.type.typeParameter', { fg = colors.fg })
hi('@lsp.type.parameter', { fg = colors.fg })
hi('@lsp.type.variable', { fg = colors.fg })
hi('@lsp.type.property', { fg = colors.fg })
hi('@lsp.type.enumMember', { fg = colors.fg })
hi('@lsp.type.event', { fg = colors.function_name })
hi('@lsp.type.function', { fg = colors.function_name })
hi('@lsp.type.method', { fg = colors.function_name })
hi('@lsp.type.macro', { fg = colors.macro })
hi('@lsp.type.keyword', { fg = colors.keyword })
hi('@lsp.type.modifier', { fg = colors.keyword })
hi('@lsp.type.comment', { fg = colors.comment })
hi('@lsp.type.string', { fg = colors.string })
hi('@lsp.type.number', { fg = colors.fg })
hi('@lsp.type.regexp', { fg = colors.string })
hi('@lsp.type.operator', { fg = colors.fg })
hi('@lsp.type.decorator', { fg = colors.keyword })

-- LSP modifiers (only set the ones that need specific styling)
hi('@lsp.mod.deprecated', { fg = colors.ghost, strikethrough = true })

-- Specific language semantic tokens
hi('@lsp.typemod.function.defaultLibrary', { fg = colors.function_name })
hi('@lsp.typemod.method.defaultLibrary', { fg = colors.function_name })
hi('@lsp.typemod.variable.defaultLibrary', { fg = colors.keyword })
hi('@lsp.typemod.variable.readonly', { fg = colors.fg })
hi('@lsp.typemod.variable.globalScope', { fg = colors.fg })
hi('@lsp.typemod.variable.fileScope', { fg = colors.fg })

-- C/C++ specific - types use default text color like in 4coder
hi('@lsp.type.type.c', { fg = colors.fg })
hi('@lsp.type.type.cpp', { fg = colors.fg })
hi('@lsp.typemod.type.defaultLibrary.cpp', { fg = colors.keyword })

-- ============================================================================
-- Diagnostics
-- ============================================================================
hi('DiagnosticError', { fg = colors.error })
hi('DiagnosticWarn', { fg = colors.warning })
hi('DiagnosticInfo', { fg = colors.info })
hi('DiagnosticHint', { fg = colors.hint })

hi('DiagnosticUnderlineError', { undercurl = true, sp = colors.error })
hi('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.warning })
hi('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.info })
hi('DiagnosticUnderlineHint', { undercurl = true, sp = colors.hint })

hi('DiagnosticVirtualTextError', { fg = colors.error, bg = '#1A0000' })
hi('DiagnosticVirtualTextWarn', { fg = colors.warning, bg = '#1A1000' })
hi('DiagnosticVirtualTextInfo', { fg = colors.info, bg = '#001010' })
hi('DiagnosticVirtualTextHint', { fg = colors.hint, bg = '#001000' })

hi('DiagnosticSignError', { fg = colors.error })
hi('DiagnosticSignWarn', { fg = colors.warning })
hi('DiagnosticSignInfo', { fg = colors.info })
hi('DiagnosticSignHint', { fg = colors.hint })

-- ============================================================================
-- LSP References & Definitions
-- ============================================================================
hi('LspReferenceText', { bg = '#1A1A1A' })
hi('LspReferenceRead', { bg = '#1A1A1A' })
hi('LspReferenceWrite', { bg = '#1A1A1A', bold = true })
hi('LspSignatureActiveParameter', { fg = colors.cursor, bold = true })

-- ============================================================================
-- Diff
-- ============================================================================
hi('DiffAdd', { fg = colors.diff_add, bg = '#001A00' })
hi('DiffChange', { fg = colors.diff_change, bg = '#1A1000' })
hi('DiffDelete', { fg = colors.diff_delete, bg = '#1A0000' })
hi('DiffText', { fg = colors.diff_change, bg = '#2A2000', bold = true })

-- ============================================================================
-- Git Signs
-- ============================================================================
hi('GitSignsAdd', { fg = colors.diff_add })
hi('GitSignsChange', { fg = colors.diff_change })
hi('GitSignsDelete', { fg = colors.diff_delete })

-- ============================================================================
-- Telescope
-- ============================================================================
hi('TelescopeNormal', { fg = colors.fg, bg = colors.statusline })
hi('TelescopeBorder', { fg = colors.border, bg = colors.statusline })
hi('TelescopePromptPrefix', { fg = colors.cursor })
hi('TelescopeSelection', { fg = colors.bg, bg = colors.cursor })
hi('TelescopeMatching', { fg = colors.string, bold = true })

-- ============================================================================
-- nvim-cmp
-- ============================================================================
hi('CmpItemAbbrDeprecated', { fg = colors.ghost, strikethrough = true })
hi('CmpItemAbbrMatch', { fg = colors.cursor, bold = true })
hi('CmpItemAbbrMatchFuzzy', { fg = colors.cursor })
hi('CmpItemKindFunction', { fg = colors.function_name })
hi('CmpItemKindMethod', { fg = colors.function_name })
hi('CmpItemKindVariable', { fg = colors.fg })
hi('CmpItemKindKeyword', { fg = colors.keyword })
hi('CmpItemKindText', { fg = colors.fg })
hi('CmpItemKindClass', { fg = colors.type })
hi('CmpItemKindInterface', { fg = colors.type })
hi('CmpItemKindStruct', { fg = colors.type })
hi('CmpItemKindModule', { fg = colors.type })
hi('CmpItemKindProperty', { fg = colors.fg })
hi('CmpItemKindUnit', { fg = colors.number })
hi('CmpItemKindValue', { fg = colors.number })
hi('CmpItemKindEnum', { fg = colors.type })
hi('CmpItemKindConstant', { fg = colors.fg })
hi('CmpItemKindConstructor', { fg = colors.type })
hi('CmpItemKindOperator', { fg = colors.fg })
hi('CmpItemKindSnippet', { fg = colors.string })

-- ============================================================================
-- Treesitter Context
-- ============================================================================
hi('TreesitterContext', { bg = '#0E0E0E' })
hi('TreesitterContextLineNumber', { fg = colors.line_number_active, bg = '#0E0E0E' })

-- ============================================================================
-- Indent Blankline
-- ============================================================================
hi('IndentBlanklineChar', { fg = colors.border })
hi('IndentBlanklineContextChar', { fg = colors.fg_dim })

print('4coder theme loaded with Treesitter and LSP semantic token support')
