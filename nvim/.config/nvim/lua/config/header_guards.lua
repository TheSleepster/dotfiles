local month_names = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
}

local function make_guard(filename)
    return filename:upper():gsub("[^%w_]", "_")
end

local function get_system_time()
    local year = os.date("%Y")
    local month = month_names[tonumber(os.date("%m"))]
    local day = os.date("%d")
    local hour = tonumber(os.date("%H"))
    local minute = tonumber(os.date("%M"))

    local ampm = "am"
    if hour >= 12 then
        ampm = "pm"
        if hour > 12 then hour = hour - 12 end
    elseif hour == 0 then
        hour = 12
    end

    return string.format("%s %s %s %02d:%02d %s", month, day, year, hour, minute, ampm)
end

local username = "Justin Lewis"

local function insert_metadata()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_line_count(buf) > 1 then return end
    if vim.fn.expand("%") == "" then return end

    local filename = vim.fn.expand("%:t")
    local date = get_system_time()
    local lines = {}

    if filename:match("%.h$") or filename:match("%.hpp$") then
        local guard = make_guard(filename)
        lines = {
            "#if !defined(" .. guard .. ")",
            "/* ========================================================================",
            "   $File: " .. filename .. " $",
            "   $Date: " .. date .. " $",
            "   $Revision: $", 
            "   $Creator: " .. username .. " $",
            "   ======================================================================== */",
            "",
            "#define " .. guard,
            "",
            "#endif // " .. guard
        }
    else
        lines = {
            "/* ========================================================================",
            "   $File: " .. filename .. " $",
            "   $Date: " .. date .. " $",
            "   $Revision: $", 
            "   $Creator: " .. username .. " $",
            "   ======================================================================== */",
            "",
        }
    end

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
end

-- Normal BufNewFile for manual editing
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = {"*.h", "*.hpp", "*.c", "*.cpp", "*.jai", "*.odin", "*.zig", "*.rs"},
    callback = insert_metadata
})

-- BufWritePre for Oil.nvim
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = {"*.h", "*.hpp", "*.c", "*.cpp", "*.jai", "*.odin", "*.zig", "*.rs"},
    callback = insert_metadata
})

