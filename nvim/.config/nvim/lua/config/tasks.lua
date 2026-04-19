function Sleepster_GetCorrespondingFile()
    local CurrentFile = vim.fn.expand("%:t")
    local CurrentDir  = vim.fn.expand("%:p:h")
    local CurrentFileExtension = vim.fn.expand("%:e")

    local CorrespondingFile = ""

    if CurrentFileExtension == "cpp" or CurrentFileExtension == "c" then
        local HeaderFile = CurrentFile:gsub("%.cpp", ".h"):gsub("%.c", ".h")
        local HeaderFileHpp = CurrentFile:gsub("%.cpp", ".hpp"):gsub("%.c", ".hpp")

        if vim.fn.filereadable(CurrentDir .. "/" .. HeaderFile) == 1 then
            CorrespondingFile = HeaderFile
        elseif vim.fn.filereadable(CurrentDir .. "/" .. HeaderFileHpp) == 1 then
            CorrespondingFile = HeaderFileHpp
        end
    elseif CurrentFileExtension == "h" or CurrentFileExtension == "hpp" then
        local SourceFileCpp = CurrentFile:gsub("%.h", ".cpp"):gsub("%.hpp", ".cpp")
        local SourceFileC = CurrentFile:gsub("%.h", ".c"):gsub("%.hpp", ".c")

        if vim.fn.filereadable(CurrentDir .. "/" .. SourceFileCpp) == 1 then
            CorrespondingFile = SourceFileCpp
        elseif vim.fn.filereadable(CurrentDir .. "/" .. SourceFileC) == 1 then
            CorrespondingFile = SourceFileC
        end
    else
        vim.api.nvim_err_writeln("Unsupported file type.")
        return nil
    end

    return CorrespondingFile
end


function Sleepster_DisplayCorrespondingFileSameBuffer()
    local File = Sleepster_GetCorrespondingFile()

    vim.api.nvim_command("edit " .. File)
end


function Sleepster_DisplayCorrespondingFileOppositeBuffer()
    local File = Sleepster_GetCorrespondingFile()

    vim.api.nvim_command("wincmd w")
    vim.api.nvim_command("edit " .. File)
end


local function build()
  vim.o.errorformat = "%f:%l:%c: %m,%f:%l: %m"

  vim.cmd(":w")
  vim.o.makeprg = "./build.sh"
  vim.cmd("make")
end

local function toggle_qf()
  local wininfo = vim.fn.getwininfo()
  for _, win in ipairs(wininfo) do
    if win.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("copen")
end



local previous_bg_colors = {}
local function get_bg_color(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and type(hl) == "table" and hl.background then
    return string.format("#%06x", hl.background)
  end

  local ok_exec, out = pcall(vim.api.nvim_exec, "highlight " .. group, true)
  if ok_exec and out then
    local guibg = out:match("guibg=([^%s]+)")
    if guibg then
      return guibg
    end
  end

  return "NONE"
end

local function set_bg_color(group, color)
  if not color or color == "" then color = "NONE" end
  vim.cmd(("highlight %s guibg=%s"):format(group, color))
end

function ToggleTransparency()
  local groups = {
    "Normal", "NormalFloat", "NormalNC", "VertSplit",
    "SignColumn", "EndOfBuffer",
    "StatusLineNC",
  }

  if previous_bg_colors["Normal"] then
    for _, group in ipairs(groups) do
      set_bg_color(group, previous_bg_colors[group] or "#1e1e1e")
    end
    previous_bg_colors = {}
  else
    -- Backup and clear
    for _, group in ipairs(groups) do
      previous_bg_colors[group] = get_bg_color(group)
      set_bg_color(group, "NONE")
    end
  end
end

function SetCursorColor()
    vim.api.nvim_set_hl(0, "CursorLine", {bg = "#191970"});
end

vim.keymap.set('n', '<leader>tb', ToggleTransparency, { noremap = true, silent = true })
vim.keymap.set("n", "<A-`>", toggle_qf, { noremap = true, silent = true })

vim.api.nvim_create_user_command("ColorMyLine", SetCursorColor, {})
vim.api.nvim_create_user_command("Build", build, {})
vim.api.nvim_create_user_command("DisplaySB", Sleepster_DisplayCorrespondingFileSameBuffer, {})
vim.api.nvim_create_user_command("DisplayOB", Sleepster_DisplayCorrespondingFileOppositeBuffer, {})

