-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
  },
  config = function()
    require('mason').setup()
    require('mason-lspconfig').setup({
      ensure_installed = {
        'lua_ls',
        'gopls',
        'ts_ls',
        'rust_analyzer',
      },
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    -- Common keymaps via LspAttach autocmd
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
      end,
    })

    -- Server configurations using vim.lsp.config
    vim.lsp.config('lua_ls', {
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { 'vim' } },
          workspace = { checkThirdParty = false },
        },
      },
    })

    vim.lsp.config('gopls', {
      capabilities = capabilities,
    })

    vim.lsp.config('ts_ls', {
      capabilities = capabilities,
    })

    vim.lsp.config('rust_analyzer', {
      capabilities = capabilities,
    })

    -- Enable the servers
    vim.lsp.enable({ 'lua_ls', 'gopls', 'ts_ls', 'rust_analyzer' })
  end,
}
