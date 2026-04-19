local M = {}

local groups = {
  TodoNote   = { fg = "#00FF00" }, -- green
  TodoInfo   = { fg = "#00CED1" }, -- teal
  TodoTodo   = { fg = "#FF0000" }, -- red
  TodoWarn   = { fg = "#FFFF00" }, -- yellow
  TodoFix    = { fg = "#FF0000" }, -- red
  TodoAuthor = { fg = "#FFD700" }, -- gold
}

local patterns = {
  TodoNote = [[\v<(NOTE)\ze(\(|:)]],
  TodoInfo = [[\v<(INFO)\ze(\(|:)]],
  TodoTodo = [[\v<(TODO)\ze(\(|:)]],
  TodoWarn = [[\v<(WARN|WARNING|IMPORTANT)\ze(\(|:)]],
  TodoFix  = [[\v<(FIX|FIXME|HACK)\ze(\(|:)]],

  TodoAuthor = [[\v\((Sleepster)\)]],
}

local match_ids = {}

local function apply_highlights()
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end

  local win = vim.api.nvim_get_current_win()
  match_ids[win] = match_ids[win] or {}

  for _, id in ipairs(match_ids[win]) do
    pcall(vim.fn.matchdelete, id, win)
  end
  match_ids[win] = {}

  for group, pat in pairs(patterns) do
    local id = vim.fn.matchadd(group, pat, 1000, -1, { window = win })
    table.insert(match_ids[win], id)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "ColorScheme" }, {
    callback = apply_highlights,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "BufWinLeave", "BufWipeout", "BufUnload" }, {
    callback = function(ev)
      local ids = match_ids[ev.win]
      if ids then
        for _, id in ipairs(ids) do
          pcall(vim.fn.matchdelete, id, ev.win)
        end
        match_ids[ev.win] = nil
      end
    end,
  })
end

return M

