require("mason-lspconfig").setup {
    ensure_installed = {"lua_ls", "glsl_analyzer", "slangd", "clangd"},
}

vim.lsp.enable({
    "lua_ls",
    "glsl_analyzer",
    "ols",
    "slangd",
    "clangd"
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            telemetry = {enable = false},
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.api.nvim_get_runtime_file("", true),
                    "${3rd}/love2d/library",
                }
            },
            diagnostics = {
                globals = {'love', 'vim'},
            },
        }
    }
})

local lspconfig = require("lspconfig")
local project_root = vim.fn.getcwd()

local capabilities = vim.lsp.protocol.make_client_capabilities()

local on_attach = function(client, bufnr)
    local opts = { buffer = bufnr }
    client.server_capabilities.semanticTokensProvider = nil

    local bufmap = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, opts)
    end
    bufmap("n", "gd", vim.lsp.buf.definition)
    bufmap("n", "K", vim.lsp.buf.hover)
    bufmap("n", "<leader>rn", vim.lsp.buf.rename)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=never",
        "--pch-storage=memory",
        "--fallback-style=none",
        "--header-insertion-decorators=0",
        "--log=error",
        "-j=12",
        "--offset-encoding=utf-16",
        "--compile-commands-dir=" .. vim.fs.joinpath(project_root, "../misc")
    },
    filetypes = { "c", "h", "hpp", "cpp", "objc", "objcpp" },
    root_dir = project_root,
    on_attach = on_attach,
    capabilities = capabilities,
})

vim.lsp.config("slangd", {
    cmd = { "slangd" },
    filetypes = { "slang" },
    on_attach = on_attach,
    capabilities = capabilities,
})

vim.diagnostic.config({
  virtual_false = true,
  virtual_text  = true,
})
