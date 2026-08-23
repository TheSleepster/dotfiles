local ok, alpha = pcall(require, "alpha")
if not ok then return end
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
	[[                                                                       ]],
	[[                                                                     ]],
	[[       ████ ██████           █████      ██                     ]],
	[[      ███████████             █████                             ]],
	[[      █████████ ███████████████████ ███   ███████████   ]],
	[[     █████████  ███    █████████████ █████ ██████████████   ]],
	[[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
	[[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
	[[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
	[[                                                                       ]],

}

dashboard.section.buttons.val = {
  dashboard.button("f", "  > Find File",     ":cd ~<CR>:Telescope find_files<CR>"),
  dashboard.button("r", "  > Recent Files",  ":Telescope oldfiles<CR>"),
  dashboard.button("c", "  > Configuration", ":edit $MYVIMRC<CR>"),
  dashboard.button("q", "  > Quit NVIM",     ":qa<CR>"),
}

vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "DashboardButton", { fg = "#98c379" })
vim.api.nvim_set_hl(0, "DashboardFooter", { fg = "#5c6370" })

dashboard.section.header.opts.hl = "DashboardHeader"
dashboard.section.buttons.opts.hl = "DashboardButton"
dashboard.section.footer.opts.hl = "DashboardFooter"

local function footer()
  return " v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch ..
         "  •  " .. os.date("%A, %B %d")
end

dashboard.section.footer.val = footer()
alpha.setup(dashboard.config)

vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function() vim.opt_local.foldenable = false end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "AlphaReady",
  callback = function()
    local cur = vim.api.nvim_get_current_win()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= cur then
        vim.api.nvim_set_current_win(w)
        vim.cmd.enew()
      end
    end
    vim.api.nvim_set_current_win(cur)
  end,
})


