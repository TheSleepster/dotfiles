local M = {}

M.config = {
    build_command = nil,
    window_height = 15,
    auto_close_on_success = false,
    focus_on_compile = false,
    root_markers = { 'build.sh', 'build.bat', '.git', 'Makefile', 'compile_commands.json' },
}

local compile_bufnr = nil
local compile_winid = nil
local compile_job_id = nil
local last_command = nil
local has_jumped_to_first = false

---### 1. Root Detection
local function get_start_dir()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_file = vim.api.nvim_buf_get_name(current_buf)
    if current_file and current_file ~= "" and vim.loop.fs_stat(current_file) then
        return vim.fs.dirname(current_file)
    end
    return vim.fn.getcwd()
end

local function get_project_root()
    local start_dir = get_start_dir()
    local root_file = vim.fs.find(M.config.root_markers, { path = start_dir, upward = true })[1]
    if root_file then return vim.fs.dirname(root_file) end
    return vim.fn.getcwd()
end

---### 2. UI & Highlights
local function setup_highlights()
    vim.api.nvim_set_hl(0, 'CompileSuccess', { fg = '#00ff00', bold = true })
    vim.api.nvim_set_hl(0, 'CompileFailed', { fg = '#ff0000', bold = true })
    vim.api.nvim_set_hl(0, 'CompileError', { fg = '#ff0000' })
    vim.api.nvim_set_hl(0, 'CompileWarning', { fg = '#ffff00' })
end

local function get_compile_buffer()
    if compile_bufnr and vim.api.nvim_buf_is_valid(compile_bufnr) then return compile_bufnr end
    compile_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(compile_bufnr, '*compilation*')
    vim.api.nvim_buf_set_option(compile_bufnr, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(compile_bufnr, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(compile_bufnr, 'swapfile', false)

    local opts = { buffer = compile_bufnr, noremap = true, silent = true }
    vim.keymap.set('n', 'q', function() M.close_compile_window() end, opts)
    vim.keymap.set('n', 'gr', function() M.recompile() end, opts)
    vim.keymap.set('n', '<CR>', function() M.goto_error() end, opts)
    vim.keymap.set('n', 'gn', function() M.next_error() end, opts)
    vim.keymap.set('n', 'gp', function() M.prev_error() end, opts)
    return compile_bufnr
end

local function open_compile_window()
    local bufnr = get_compile_buffer()
    local original_win = vim.api.nvim_get_current_win()
    if not (compile_winid and vim.api.nvim_win_is_valid(compile_winid)) then
        vim.cmd('botright ' .. M.config.window_height .. 'split')
        compile_winid = vim.api.nvim_get_current_win()
    end
    vim.api.nvim_win_set_buf(compile_winid, bufnr)
    vim.api.nvim_win_set_option(compile_winid, 'number', false)
    vim.api.nvim_win_set_option(compile_winid, 'relativenumber', false)
    vim.api.nvim_win_set_option(compile_winid, 'wrap', false)
    if not M.config.focus_on_compile then vim.api.nvim_set_current_win(original_win) end
end

---### 3. Output Logic
local function write_to_buffer(data)
    if not data or #data == 0 then return end
    local bufnr = get_compile_buffer()
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1] or ""
    local lines = {}
    for i, line in ipairs(data) do lines[i] = line:gsub('\r', '') end
    lines[1] = last_line .. lines[1]
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, lines)
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
    if compile_winid and vim.api.nvim_win_is_valid(compile_winid) then
        vim.api.nvim_win_set_cursor(compile_winid, { vim.api.nvim_buf_line_count(bufnr), 0 })
    end
end

local function apply_syntax_highlighting(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
        local l = line:lower()
        if l:match('error[:%s]') or l:match('^error') then
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'CompileError', i - 1, 0, -1)
        elseif l:match('warning[:%s]') or l:match('^warning') then
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'CompileWarning', i - 1, 0, -1)
        end
        if line:match('Compilation Finished') then
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'CompileSuccess', i - 1, 0, -1)
        elseif line:match('Compilation Failed') then
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'CompileFailed', i - 1, 0, -1)
        end
    end
end

---### 4. Compilation Core
function M.compile(command)
    vim.cmd('silent! wall')

    local root
    local start_dir = get_start_dir()
    local build_script_path = vim.fs.find({'build.sh', 'build.bat'}, { path = start_dir, upward = true })[1]

    if not command then
        if build_script_path then
            root = vim.fs.dirname(build_script_path)
            local script_name = vim.fs.basename(build_script_path)
            if script_name == 'build.sh' then command = './build.sh' else command = 'build.bat' end
        else
            root = get_project_root()
            command = 'make'
        end
    else
        root = get_project_root()
    end

    last_command = command
    has_jumped_to_first = false

    if compile_job_id then vim.fn.jobstop(compile_job_id) end

    setup_highlights()
    open_compile_window()

    local bufnr = get_compile_buffer()
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })

    -- Updated ErrorFormat: Ignores Headers/Footers
    local efm = table.concat({
        '%-G-*- mode: compilation%.%#',
        '%-GCompilation started at%.%#',
        '%-GCompilation Finished%.%#',
        '%-GCompilation Failed%.%#',
        '%-GRoot:%.%#',
        '%-GRunning:%.%#',
        '%-G-%.%#',
        '%f:%l:%c: %trror: %m',
        '%f:%l:%c: %tarning: %m',
        '%f:%l: %trror: %m',
        '%f:%l: %tarning: %m',
        '%f(%l): %trror %m',
        '%f(%l): %tarning %m',
        '%f:%l: %m',
    }, ',')

    vim.api.nvim_buf_set_option(bufnr, 'errorformat', efm)

    local cmd_to_run = command .. ' 2>&1'
    write_to_buffer({
        '-*- mode: compilation; -*-',
        'Compilation started at ' .. os.date('%c'),
        '',
        'Root: ' .. root,
        'Running: ' .. cmd_to_run,
        string.rep('-', 80),
        ''
    })

    local start_time = vim.loop.hrtime()

    compile_job_id = vim.fn.jobstart(cmd_to_run, {
        cwd = root,
        on_stdout = function(_, data) write_to_buffer(data) end,
        on_exit = function(_, exit_code)
            compile_job_id = nil
            local elapsed = (vim.loop.hrtime() - start_time) / 1e9
            local status = (exit_code == 0) and 'Compilation Finished' or 'Compilation Failed'

            write_to_buffer({
                '',
                string.rep('-', 80),
                string.format('%s at %s (%.2fs)', status, os.date('%c'), elapsed)
            })

            vim.schedule(function()
                local b = get_compile_buffer()
                apply_syntax_highlighting(b)

                -- FIXED: Use setqflist with explicit CWD to resolve relative paths
                local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
                vim.fn.setqflist({}, 'r', {
                    title = 'Compile Output',
                    lines = lines,
                    efm = efm,
                    cwd = root -- THIS LINE FIXES THE EMPTY BUFFER JUMP
                })

                local qf_list = vim.fn.getqflist()
                local actual_errors = 0
                for _, item in ipairs(qf_list) do if item.valid == 1 then actual_errors = actual_errors + 1 end end

                if exit_code ~= 0 or actual_errors > 0 then
                    vim.notify(actual_errors .. " errors found", vim.log.levels.ERROR)
                else
                    vim.notify("Compilation Succeeded", vim.log.levels.INFO)
                    if M.config.auto_close_on_success then M.close_compile_window() end
                end
            end)
        end,
    })
end

---### 5. Interface
function M.recompile() M.compile(last_command) end
function M.next_error()
    local cmd = has_jumped_to_first and 'cnext' or 'cfirst'
    has_jumped_to_first = true
    pcall(vim.cmd, cmd)
end
function M.prev_error() pcall(vim.cmd, 'cprev') end
function M.goto_error()
    local line = vim.api.nvim_get_current_line()
    -- Try to match relative to buffer logic (if user clicks directly)
    local patterns = { '([^:]+):(%d+):(%d+)', '([^:]+):(%d+)', '([^%(]+)%((%d+)%)' }
    for _, p in ipairs(patterns) do
        local file, lnum, col = line:match(p)
        if file then
            -- Try finding file relative to root first (most likely)
            local root = get_project_root() -- Or store the last compiled root globally if needed
            local full_path = root .. '/' .. file
            if vim.fn.filereadable(full_path) == 1 then
                vim.cmd('wincmd p')
                vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
                vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col or 0) })
                return
            end
            -- Fallback to standard check
            if vim.fn.filereadable(file) == 1 then
                vim.cmd('wincmd p')
                vim.cmd('edit ' .. vim.fn.fnameescape(file))
                vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col or 0) })
                return
            end
        end
    end
end
function M.close_compile_window()
    if compile_winid and vim.api.nvim_win_is_valid(compile_winid) then
        vim.api.nvim_win_close(compile_winid, false)
        compile_winid = nil
    end
end
function M.toggle_compile_window()
    if compile_winid and vim.api.nvim_win_is_valid(compile_winid) then M.close_compile_window() else open_compile_window() end
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
    vim.api.nvim_create_user_command('Compile', function(a) M.compile(a.args ~= '' and a.args or nil) end, { nargs = '?' })
    vim.keymap.set('n', '<F5>', M.compile)
    vim.keymap.set('n', '<M-m>', M.compile)
    vim.keymap.set('n', '<M-`>', M.toggle_compile_window)
    vim.keymap.set('n', '<M-e>', M.next_error)
end

return M
