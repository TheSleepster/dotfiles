local ok, alpha = pcall(require, "alpha")
if not ok then return end
local dashboard = require("alpha.themes.dashboard")

local has_pick, pick = pcall(require, "mini.pick")
if has_pick then pick.setup() end

if has_pick then
    vim.api.nvim_create_user_command("PickOldfiles", function()
        local mp = require("mini.pick")
        local old = vim.v.oldfiles or {}
        if #old == 0 then
            vim.notify("No recent files", vim.log.levels.INFO)
            return
        end
        mp.start({
            source = {
                name = "Oldfiles",
                items = old,
                choose = function(item)
                    if type(item) == "string" and item ~= "" then
                        vim.schedule(function()
                            vim.cmd("edit " .. vim.fn.fnameescape(item))
                        end)
                    end
                end,
            },
        })
    end, {})
else
  vim.api.nvim_create_user_command("PickOldfiles", function()
    vim.notify("mini.pick not installed", vim.log.levels.WARN)
  end, {})
end

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
  dashboard.button("f", "  > Find File",     ":cd ~<CR>:Pick files<CR>"),
  dashboard.button("r", "  > Recent Files",  ":PickOldfiles<CR>"),
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


