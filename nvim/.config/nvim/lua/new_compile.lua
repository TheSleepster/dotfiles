-- compile.lua — Emacs-style async compilation for Neovim
-- Supports GCC/Clang/G++/Clang++, MSVC, Rust, Zig, Odin and most other compilers.
local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- § Config
-- ─────────────────────────────────────────────────────────────────────────────
M.config = {
    build_command         = nil,     -- fallback command when no build script found
    window_height         = 15,
    auto_close_on_success = false,
    auto_open_on_error    = false,   -- re-open compile window when errors are found
    focus_on_compile      = false,
    root_markers          = { 'build.sh', 'build.bat', '.git', 'Makefile', 'compile_commands.json' },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- § State  (all mutable state lives here)
-- ─────────────────────────────────────────────────────────────────────────────
local S = {
    bufnr       = nil,   -- the *compilation* buffer
    winid       = nil,   -- the compile split window
    job_id      = nil,   -- currently running job
    command     = nil,   -- last command compiled
    root        = nil,   -- last project root compiled in
    qf_index    = 0,     -- quickfix navigation cursor (1-based, 0 = before first)
    partial_raw = "",    -- raw (ANSI) accumulator for the current incomplete line
    ansi_ns     = nil,   -- nvim namespace for ANSI colour extmarks
    syntax_ns   = nil,   -- nvim namespace for semantic (error/warning) highlights
}

-- ─────────────────────────────────────────────────────────────────────────────
-- § 1  Utilities
-- ─────────────────────────────────────────────────────────────────────────────
local function get_start_dir()
    local f = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    if f and f ~= "" and vim.loop.fs_stat(f) then return vim.fs.dirname(f) end
    return vim.fn.getcwd()
end

local function get_project_root()
    local m = vim.fs.find(M.config.root_markers, { path = get_start_dir(), upward = true })[1]
    return m and vim.fs.dirname(m) or vim.fn.getcwd()
end

-- Resolve a compiler-reported path to an absolute readable path.
-- Tries: absolute, relative to root, relative to cwd, then glob search.
local function resolve_path(raw, root)
    if not raw or raw == "" then return nil end
    local path = raw:gsub("^%s+", ""):gsub("%s+$", "")   -- trim whitespace
    path = path:gsub("\\", "/")                           -- normalise separators

    -- Already absolute
    if path:sub(1, 1) == "/" or path:match("^%a:/") then
        return vim.fn.filereadable(path) == 1 and path or nil
    end

    -- Relative to root or cwd
    for _, base in ipairs({ root or "", vim.fn.getcwd() }) do
        if base ~= "" then
            local c = base .. "/" .. path
            if vim.fn.filereadable(c) == 1 then return c end
        end
    end

    -- Glob fallback: search for the basename anywhere under root, then verify
    -- the suffix matches (avoids picking the wrong file with the same name).
    local base = vim.fn.fnamemodify(path, ":t")
    if base ~= "" then
        local anchor = root or vim.fn.getcwd()
        -- Search progressively shallower: one level, two levels, unlimited
        for _, pat in ipairs({ "/" .. base, "/*/" .. base, "/**/" .. base }) do
            local hits = vim.fn.glob(anchor .. pat, true, true)
            for _, hit in ipairs(hits) do
                local norm = hit:gsub("\\", "/")
                -- Check the tail of the resolved path matches our relative path
                if norm:sub(-#path):gsub("\\", "/") == path then return hit end
            end
            -- Unambiguous match at this depth: take it
            if #hits == 1 then return hits[1] end
        end
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 2  ANSI Escape Parsing
-- ─────────────────────────────────────────────────────────────────────────────
-- SGR colour-code → highlight group attributes.
local ANSI_ATTRS = {
    [1]  = { bold   = true },
    [3]  = { italic = true },
    [31] = { fg = "#cc5555" }, [91] = { fg = "#ff8888" },
    [32] = { fg = "#55aa55" }, [92] = { fg = "#88dd88" },
    [33] = { fg = "#aaaa00" }, [93] = { fg = "#ffff55" },
    [34] = { fg = "#5577cc" }, [94] = { fg = "#8899ff" },
    [35] = { fg = "#aa55aa" }, [95] = { fg = "#ff88ff" },
    [36] = { fg = "#00aaaa" }, [96] = { fg = "#55ffff" },
    [37] = { fg = "#aaaaaa" }, [97] = { fg = "#ffffff" },
    [90] = { fg = "#666666" },
}

local function setup_ansi_hls()
    for code, attrs in pairs(ANSI_ATTRS) do
        vim.api.nvim_set_hl(0, ("CompileAnsi%d"):format(code), attrs)
    end
end

-- Strips ANSI escape sequences from `raw`, returns:
--   clean   – the visible text with no escape codes
--   spans   – list of { col_start, col_end, hl_group } for extmarks
local function parse_ansi(raw)
    local ESC = "\027"
    local out, spans, active, col, pos = {}, {}, {}, 0, 1

    while pos <= #raw do
        local es = raw:find(ESC .. "[", pos, true)   -- plain search for ESC[
        if not es then
            local chunk = raw:sub(pos)
            if #chunk > 0 then
                for _, hl in ipairs(active) do
                    spans[#spans + 1] = { col, col + #chunk, hl }
                end
                out[#out + 1] = chunk
                col = col + #chunk
            end
            break
        end
        -- Flush any text before the escape sequence
        if es > pos then
            local chunk = raw:sub(pos, es - 1)
            for _, hl in ipairs(active) do
                spans[#spans + 1] = { col, col + #chunk, hl }
            end
            out[#out + 1] = chunk
            col = col + #chunk
        end
        -- Find the SGR terminator 'm'
        local me = raw:find("m", es + 2, true)
        if not me then pos = es + 2; break end

        -- Parse the semicolon-separated SGR codes
        local codes = raw:sub(es + 2, me - 1)
        if codes == "" then codes = "0" end
        active = {}
        for c in (codes .. ";"):gmatch("(%d*);") do
            local n = tonumber(c) or 0
            if n == 0 then
                active = {}
            elseif ANSI_ATTRS[n] then
                active[#active + 1] = ("CompileAnsi%d"):format(n)
            end
        end
        pos = me + 1
    end

    return table.concat(out), spans
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 3  Compiler Error / Warning Parsing
-- ─────────────────────────────────────────────────────────────────────────────
-- Each entry: { lua_pattern, error_type, file_cap, line_cap, col_cap|nil, msg_cap }
local PATTERNS = {
    -- GCC / Clang / G++ / Clang++ / Zig — file:line:col: severity: msg
    { "^(.+):(%d+):(%d+):%s*error:%s*(.+)$",          "E", 1, 2, 3, 4 },
    { "^(.+):(%d+):(%d+):%s*fatal error:%s*(.+)$",    "E", 1, 2, 3, 4 },
    { "^(.+):(%d+):(%d+):%s*warning:%s*(.+)$",        "W", 1, 2, 3, 4 },
    { "^(.+):(%d+):(%d+):%s*note:%s*(.+)$",           "I", 1, 2, 3, 4 },
    -- Without column
    { "^(.+):(%d+):%s*error:%s*(.+)$",                "E", 1, 2, nil, 3 },
    { "^(.+):(%d+):%s*warning:%s*(.+)$",              "W", 1, 2, nil, 3 },
    -- MSVC — file(line,col): error CXXXX: msg
    { "^(.-)%((%d+),(%d+)%):%s*error%s+(.+)$",        "E", 1, 2, 3, 4 },
    { "^(.-)%((%d+),(%d+)%):%s*warning%s+(.+)$",      "W", 1, 2, 3, 4 },
    { "^(.-)%((%d+)%):%s*error%s+(.+)$",              "E", 1, 2, nil, 3 },
    { "^(.-)%((%d+)%):%s*warning%s+(.+)$",            "W", 1, 2, nil, 3 },
    -- Odin — file(line:col) Error: msg
    { "^(.-)%((%d+):(%d+)%)%s*[Ee]rror:%s*(.+)$",    "E", 1, 2, 3, 4 },
    { "^(.-)%((%d+):(%d+)%)%s*[Ww]arning:%s*(.+)$",  "W", 1, 2, 3, 4 },
    { "^(.-)%((%d+)%)%s*[Ee]rror:%s*(.+)$",          "E", 1, 2, nil, 3 },
}

-- Rust uses a two-line format:  error[Exxxx]: msg  /  --> file:line:col
local RUST_ERR  = "^error%[E%d+%]:%s*(.+)"
local RUST_WARN = "^warning%[.-%]:%s*(.+)"
local RUST_LOC  = "^%s*%-%->%s+(.-)%s*:(%d+):(%d+)"

local function parse_errors(lines, root)
    local items = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local done = false

        -- Rust multi-line detection
        local msg   = line:match(RUST_ERR)
        local etype = msg and "E"
        if not msg then msg, etype = line:match(RUST_WARN), "W" end
        if msg then
            local nxt        = lines[i + 1] or ""
            local rf, rl, rc = nxt:match(RUST_LOC)
            if rf then
                local resolved = resolve_path(rf, root)
                if resolved then
                    items[#items + 1] = {
                        filename = resolved,
                        lnum  = tonumber(rl),
                        col   = math.max(0, (tonumber(rc) or 1) - 1),
                        type  = etype,
                        text  = msg,
                        valid = 1,
                    }
                    i = i + 2; done = true
                end
            end
        end

        -- Standard single-line patterns
        if not done then
            for _, p in ipairs(PATTERNS) do
                local pat, et, fi, li, ci, mi = p[1], p[2], p[3], p[4], p[5], p[6]
                local caps = { line:match(pat) }
                if caps[fi] then
                    local resolved = resolve_path(caps[fi], root)
                    -- Only add to quickfix if the file actually exists on disk.
                    -- This is the core heuristic that eliminates false positives
                    -- from plain-text build output that happens to contain colons.
                    if resolved then
                        items[#items + 1] = {
                            filename = resolved,
                            lnum  = tonumber(caps[li]),
                            col   = ci and math.max(0, (tonumber(caps[ci]) or 1) - 1) or 0,
                            type  = et,
                            text  = caps[mi] or "",
                            valid = 1,
                        }
                        done = true; break
                    end
                end
            end
            i = i + 1
        end
    end
    return items
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 4  Highlight Setup
-- ─────────────────────────────────────────────────────────────────────────────
local function setup_highlights()
    vim.api.nvim_set_hl(0, "CompileSuccess", { fg = "#77dd77", bold   = true })
    vim.api.nvim_set_hl(0, "CompileFailed",  { fg = "#ff6b6b", bold   = true })
    vim.api.nvim_set_hl(0, "CompileError",   { fg = "#ff6b6b" })
    vim.api.nvim_set_hl(0, "CompileWarning", { fg = "#ffdd57" })
    vim.api.nvim_set_hl(0, "CompileInfo",    { fg = "#74b9ff" })
    vim.api.nvim_set_hl(0, "CompileHeader",  { fg = "#636e72", italic = true })
    setup_ansi_hls()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 5  Buffer Management
-- ─────────────────────────────────────────────────────────────────────────────
local function get_buf()
    if S.bufnr and vim.api.nvim_buf_is_valid(S.bufnr) then return S.bufnr end

    S.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(S.bufnr, "*compilation*")
    vim.bo[S.bufnr].buftype   = "nofile"
    vim.bo[S.bufnr].bufhidden = "hide"
    vim.bo[S.bufnr].swapfile  = false

    S.ansi_ns   = S.ansi_ns   or vim.api.nvim_create_namespace("compile_ansi")
    S.syntax_ns = S.syntax_ns or vim.api.nvim_create_namespace("compile_syntax")

    local o = { buffer = S.bufnr, noremap = true, silent = true }
    vim.keymap.set("n", "q",    M.close_compile_window,  o)
    vim.keymap.set("n", "gr",   M.recompile,              o)
    vim.keymap.set("n", "<CR>", M.goto_error_at_cursor,   o)
    vim.keymap.set("n", "gn",   M.next_error,             o)
    vim.keymap.set("n", "gp",   M.prev_error,             o)

    return S.bufnr
end

function M.open_compile_window()
    local bufnr = get_buf()
    local orig  = vim.api.nvim_get_current_win()

    if not (S.winid and vim.api.nvim_win_is_valid(S.winid)) then
        vim.cmd("botright " .. M.config.window_height .. "split")
        S.winid = vim.api.nvim_get_current_win()
    end
    vim.api.nvim_win_set_buf(S.winid, bufnr)
    vim.wo[S.winid].number         = false
    vim.wo[S.winid].relativenumber = false
    vim.wo[S.winid].wrap           = false
    vim.wo[S.winid].signcolumn     = "no"

    if not M.config.focus_on_compile then
        vim.api.nvim_set_current_win(orig)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 6  Output Writing  (ANSI-aware, line-by-line)
-- ─────────────────────────────────────────────────────────────────────────────
-- The buffer always ends with one "tail" line (the current incomplete line).
-- buf_write() replaces that tail with `entries`, each being {clean_text, spans}.
-- entries[1..n-1] are newly completed lines; entries[n] is the new tail.
local function buf_write(entries)
    if not entries or #entries == 0 then return end
    local bufnr = get_buf()
    local ns    = S.ansi_ns

    vim.bo[bufnr].modifiable = true
    local lc       = vim.api.nvim_buf_line_count(bufnr)
    local tail_idx = lc - 1   -- 0-indexed

    local text = {}
    for _, e in ipairs(entries) do text[#text + 1] = e[1] end

    -- Clear old ANSI highlights on the tail line before replacing it
    vim.api.nvim_buf_clear_namespace(bufnr, ns, tail_idx, tail_idx + 1)
    vim.api.nvim_buf_set_lines(bufnr, tail_idx, tail_idx + 1, false, text)
    vim.bo[bufnr].modifiable = false

    -- Re-apply ANSI highlights for each new line
    for i, e in ipairs(entries) do
        for _, s in ipairs(e[2]) do
            -- s = { col_start, col_end, hl_group }
            vim.api.nvim_buf_add_highlight(bufnr, ns, s[3], tail_idx + i - 1, s[1], s[2])
        end
    end

    -- Scroll the compile window to the latest output
    if S.winid and vim.api.nvim_win_is_valid(S.winid) then
        vim.api.nvim_win_set_cursor(S.winid, { vim.api.nvim_buf_line_count(bufnr), 0 })
    end
end

-- Feed raw job output chunks into the buffer.
-- chunks[1] continues S.partial_raw; chunks[#] becomes the new partial.
-- Everything in between is a complete line.
-- Called directly (no vim.schedule) from job callbacks to guarantee ordering.
local function feed_output(chunks)
    if not chunks or #chunks == 0 then return end

    local entries = {}

    if #chunks == 1 then
        -- Single element: just extends the current partial line
        S.partial_raw = S.partial_raw .. chunks[1]:gsub("\r", "")
        local c, s = parse_ansi(S.partial_raw)
        entries = { { c, s } }
    else
        -- First element completes the partial
        local c1, s1 = parse_ansi(S.partial_raw .. chunks[1]:gsub("\r", ""))
        entries[#entries + 1] = { c1, s1 }

        -- Middle elements are standalone complete lines
        for k = 2, #chunks - 1 do
            local c, s = parse_ansi(chunks[k]:gsub("\r", ""))
            entries[#entries + 1] = { c, s }
        end

        -- Last element begins the new partial
        S.partial_raw = (chunks[#chunks] or ""):gsub("\r", "")
        local pc, ps  = parse_ansi(S.partial_raw)
        entries[#entries + 1] = { pc, ps }
    end

    buf_write(entries)
end

-- Write the header lines (no ANSI) and reset all per-compilation state.
-- Clears both namespaces so every compile starts from a clean slate.
local function write_header(lines)
    local bufnr = get_buf()
    S.partial_raw = ""
    vim.api.nvim_buf_clear_namespace(bufnr, S.ansi_ns,   0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, S.syntax_ns, 0, -1)
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
    for i = 1, #lines do
        vim.api.nvim_buf_add_highlight(bufnr, S.syntax_ns, "CompileHeader", i - 1, 0, -1)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 7  Post-compile Semantic Highlighting
-- ─────────────────────────────────────────────────────────────────────────────
-- Overlays error/warning/success line colours on top of the ANSI highlights.
-- Uses a separate namespace so ANSI colours are never destroyed.
local function apply_syntax(bufnr)
    local ns = S.syntax_ns
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local lo  = line:lower()
        local idx = i - 1
        local hl

        if     line:find("Compilation Finished", 1, true) then hl = "CompileSuccess"
        elseif line:find("Compilation Failed",   1, true) then hl = "CompileFailed"
        elseif line:find("-*- mode:",             1, true)
            or line:sub(1, 5)  == "Root:"
            or line:sub(1, 8)  == "Running:"
            or line:sub(1, 19) == "Compilation started"    then hl = "CompileHeader"
        elseif lo:match("[%s%(]error[:%s%(]") or lo:match("^error[:%s%(]")       then hl = "CompileError"
        elseif lo:match("[%s%(]warning[:%s%(]") or lo:match("^warning[:%s%(]")   then hl = "CompileWarning"
        elseif lo:match("[%s%(]note[:%s]") or lo:match("^note[:%s]")             then hl = "CompileInfo"
        end

        if hl then vim.api.nvim_buf_add_highlight(bufnr, ns, hl, idx, 0, -1) end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 8  Compilation Core
-- ─────────────────────────────────────────────────────────────────────────────
function M.compile(command)
    vim.cmd("silent! wall")

    local root
    local bs = vim.fs.find({ "build.sh", "build.bat" },
        { path = get_start_dir(), upward = true })[1]

    if not command then
        if bs then
            root    = vim.fs.dirname(bs)
            local n = vim.fs.basename(bs)
            command = (n == "build.sh") and "./build.sh" or "build.bat"
        else
            root    = get_project_root()
            command = M.config.build_command or "make"
        end
    else
        root = get_project_root()
    end

    S.command  = command
    S.root     = root
    S.qf_index = 0

    -- Kill any in-flight job without waiting
    if S.job_id then vim.fn.jobstop(S.job_id); S.job_id = nil end

    setup_highlights()
    get_buf()   -- ensure the buffer exists even though we don't open the window

    local cmd = command .. " 2>&1"
    write_header({
        "-*- mode: compilation; default-directory: " .. root .. " -*-",
        "Compilation started at " .. os.date("%c"),
        "",
        "Root:    " .. root,
        "Running: " .. cmd,
        string.rep("-", 80),
        "",   -- ← initial tail / partial-line slot
    })

    local t0 = vim.loop.hrtime()

    S.job_id = vim.fn.jobstart(cmd, {
        cwd       = root,
        -- feed_output is called directly (no vim.schedule) so S.partial_raw
        -- is always current by the time on_exit runs.
        on_stdout = function(_, data) feed_output(data) end,
        on_exit   = function(_, code)
            S.job_id  = nil
            local dt  = (vim.loop.hrtime() - t0) / 1e9
            local ok  = code == 0
            local lbl = ok and "Compilation Finished" or "Compilation Failed"

            -- Write the footer synchronously so it lands before on_exit returns.
            feed_output({
                "",
                string.rep("-", 80),
                ("%s at %s (%.2fs)"):format(lbl, os.date("%c"), dt),
                "",   -- complete the footer line
            })

            -- Defer the heavier analysis so the event loop stays responsive.
            -- Because feed_output above is synchronous, all buffer content is
            -- already present when this callback fires.
            vim.schedule(function()
                local b     = get_buf()
                apply_syntax(b)

                local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
                local items = parse_errors(lines, S.root)
                vim.fn.setqflist({}, "r", { title = "Compilation", items = items })

                local nerr, nwrn = 0, 0
                for _, it in ipairs(items) do
                    if     it.type == "E" then nerr = nerr + 1
                    elseif it.type == "W" then nwrn = nwrn + 1
                    end
                end

                local function plural(n, w)
                    return n .. " " .. w .. (n ~= 1 and "s" or "")
                end

                if nerr > 0 then
                    local msg = plural(nerr, "error")
                    if nwrn > 0 then msg = msg .. ", " .. plural(nwrn, "warning") end
                    vim.notify(msg, vim.log.levels.ERROR)
                    if M.config.auto_open_on_error then M.open_compile_window() end
                elseif nwrn > 0 then
                    vim.notify(plural(nwrn, "warning"), vim.log.levels.WARN)
                    if ok and M.config.auto_close_on_success then M.close_compile_window() end
                elseif ok then
                    vim.notify("Compilation succeeded", vim.log.levels.INFO)
                    if M.config.auto_close_on_success then M.close_compile_window() end
                else
                    -- Non-zero exit but no recognised error lines; script itself failed.
                    vim.notify(
                        ("Compilation failed (exit %d, no errors parsed)"):format(code),
                        vim.log.levels.WARN
                    )
                end
            end)
        end,
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 9  Navigation
-- ─────────────────────────────────────────────────────────────────────────────
function M.recompile()
    M.compile(S.command)
end

function M.next_error()
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("No errors in compilation output", vim.log.levels.INFO)
        return
    end
    if S.qf_index >= #qf then
        vim.notify(
            ("Already at last entry (%d/%d) — use gp to go back"):format(S.qf_index, #qf),
            vim.log.levels.WARN
        )
        return
    end
    S.qf_index = S.qf_index + 1
    -- pcall guards against the (rare) case where the buffer was wiped
    local ok, err = pcall(vim.cmd, "cc " .. S.qf_index)
    if not ok then
        vim.notify("Error jumping to entry: " .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.prev_error()
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("No errors in compilation output", vim.log.levels.INFO)
        return
    end
    if S.qf_index <= 1 then
        vim.notify("Already at first entry", vim.log.levels.INFO)
        S.qf_index = 1
    else
        S.qf_index = S.qf_index - 1
    end
    local ok, err = pcall(vim.cmd, "cc " .. S.qf_index)
    if not ok then
        vim.notify("Error jumping to entry: " .. tostring(err), vim.log.levels.ERROR)
    end
end

-- Press <CR> inside the compile window to jump directly to the error under
-- the cursor, using the same path-resolution logic as the error parser.
function M.goto_error_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local root = S.root or get_project_root()

    -- Reuse the same patterns as parse_errors for consistency.
    -- Try Rust --> location first
    local rf, rl, rc = line:match(RUST_LOC)
    if rf then
        local resolved = resolve_path(rf, root)
        if resolved then
            vim.cmd("wincmd p")
            vim.cmd("edit " .. vim.fn.fnameescape(resolved))
            vim.api.nvim_win_set_cursor(0, { tonumber(rl), math.max(0, tonumber(rc) - 1) })
            return
        end
    end

    -- Standard patterns
    for _, p in ipairs(PATTERNS) do
        local pat, fi, li, ci, mi = p[1], p[3], p[4], p[5], p[6]
        local caps = { line:match(pat) }
        if caps[fi] then
            local resolved = resolve_path(caps[fi], root)
            if resolved then
                local lnum = tonumber(caps[li])
                local col  = ci and math.max(0, (tonumber(caps[ci]) or 1) - 1) or 0
                vim.cmd("wincmd p")
                vim.cmd("edit " .. vim.fn.fnameescape(resolved))
                vim.api.nvim_win_set_cursor(0, { lnum, col })
                return
            end
        end
    end

    vim.notify("No file reference found on this line", vim.log.levels.INFO)
end

function M.close_compile_window()
    if S.winid and vim.api.nvim_win_is_valid(S.winid) then
        vim.api.nvim_win_close(S.winid, false)
        S.winid = nil
    end
end

function M.toggle_compile_window()
    if S.winid and vim.api.nvim_win_is_valid(S.winid) then
        M.close_compile_window()
    else
        M.open_compile_window()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- § 10  Setup
-- ─────────────────────────────────────────────────────────────────────────────
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    vim.api.nvim_create_user_command("Compile", function(a)
        M.compile(a.args ~= "" and a.args or nil)
    end, { nargs = "?" })

    -- <M-m> / <F5>  — compile silently (no window pop-up)
    -- <M-`>         — toggle the compile split
    -- <M-e>         — jump to next error
    vim.keymap.set("n", "<F5>",  M.compile,               { desc = "Compile" })
    vim.keymap.set("n", "<M-m>", M.compile,               { desc = "Compile" })
    vim.keymap.set("n", "<M-`>", M.toggle_compile_window, { desc = "Toggle compile window" })
    vim.keymap.set("n", "<M-e>", M.next_error,            { desc = "Next compile error" })
end

return M
