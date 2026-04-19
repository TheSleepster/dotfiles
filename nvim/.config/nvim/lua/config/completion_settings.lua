-- define kind_icons array like above
local cmp_kinds = {
  Text = "",
  Method = "󰆧",
  Function = "",
  Constructor = "",
  Field = "󰇽",
  Variable = "󰂡",
  Class = "󰠱",
  Interface = "",
  Module = "",
  Property = "󰜢",
  Unit = "",
  Value = "󰎠",
  Enum = "",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "󰏿",
  Struct = "",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰅲",
}

local cmp = require('cmp')
  cmp.setup({
    autocomplete = false,
    sources = {
        {name = 'nvim_lsp', keyword_length = 4, max_item_count = 10},
        {name = 'buffer', keyword_length = 2, max_tiem_count = 10},
        {name = 'path'},
    },

    snippet = {
        expand = function(args)
        vim.snippet.expand(args.body)
      end,
    },

    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<TAB>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),

        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-y>'] = cmp.mapping.confirm({select = true}),
        ['<CR>'] = cmp.mapping.confirm({select = false}),

        ['<Tab>'] = cmp.mapping(function(fallback)
          local col = vim.fn.col('.') - 1

          if cmp.visible() then
            cmp.select_next_item(select_opts)
          elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
            fallback()
          else
            cmp.complete()
          end
        end, {'i', 's'}),

        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item(select_opts)
          else
            fallback()
          end
        end, {'i', 's'}),
    },

    window = {
        completion = cmp.config.window.bordered({
            border = 'rounded',
            winhighlight = "Normal:Normal,FloatBorder:Normal,Search:None",
            col_offset = -2,
            side_padding = 1,
        }),
        documentation = cmp.config.window.bordered({
            border = 'rounded',
            winhighlight = "Normal:Normal,FloatBorder:Normal,Search:None",
            col_offset = -2,
            side_padding = 1,
        }),
    },

    formatting = {
        format = function(entry, vim_item)
            if type(entry.completion_item.description) ~= "string" then
                entry.completion_item.description = ""
            end

            local kind = vim_item.kind
            vim_item.kind = cmp_kinds[vim_item.kind] or "?"

            vim_item.menu = ({
                buffer = "[Buffer]",
                nvim_lsp = "[LSP]",
                nvim_lua = "[Lua]",
                latex_symbols = "[LaTeX]",
            })[entry.source.name]

            return vim_item
        end,
    },

    view = {
        -- custom
        --entries = {name = 'wildmenu', seperator = '|'},
        entries = {name = 'custom', selection_order = 'near_cursor' }
    },

    experimental = {
        ghost_text = false,
    },
})


