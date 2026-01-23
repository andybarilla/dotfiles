-- ~/.config/nvim/lua/plugins/jdtls.lua
return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  config = function()
    local jdtls = require('jdtls')
    local mason_registry = require('mason-registry')

    local jdtls_path = mason_registry.get_package('jdtls'):get_install_path()
    local java_debug_path = mason_registry.get_package('java-debug-adapter'):get_install_path()
    local java_test_path = mason_registry.get_package('java-test'):get_install_path()

    local bundles = {
      vim.fn.glob(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
    }
    vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. '/extension/server/*.jar', true), '\n'))

    local function get_workspace_dir()
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      return vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name
    end

    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr }
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

      -- Java-specific
      vim.keymap.set('n', '<leader>oi', jdtls.organize_imports, opts)
      vim.keymap.set('n', '<leader>ev', jdtls.extract_variable, opts)
      vim.keymap.set('v', '<leader>ev', function() jdtls.extract_variable(true) end, opts)
      vim.keymap.set('n', '<leader>ec', jdtls.extract_constant, opts)
      vim.keymap.set('v', '<leader>ec', function() jdtls.extract_constant(true) end, opts)
      vim.keymap.set('v', '<leader>em', function() jdtls.extract_method(true) end, opts)

      -- Debug/test
      vim.keymap.set('n', '<leader>tc', jdtls.test_class, opts)
      vim.keymap.set('n', '<leader>tm', jdtls.test_nearest_method, opts)

      jdtls.setup_dap({ hotcodereplace = 'auto' })
    end

    local config = {
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-jar', vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration', jdtls_path .. '/config_linux',
        '-data', get_workspace_dir(),
      },
      root_dir = require('jdtls.setup').find_root({ '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }),
      settings = {
        java = {
          signatureHelp = { enabled = true },
          contentProvider = { preferred = 'fernflower' },
          completion = {
            favoriteStaticMembers = {
              'org.junit.jupiter.api.Assertions.*',
              'org.mockito.Mockito.*',
              'io.restassured.RestAssured.*',
            },
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
            },
            useBlocks = true,
          },
          configuration = {
            runtimes = {
              {
                name = 'JavaSE-21',
                path = '/usr/lib/jvm/java-21-openjdk',
              },
              {
                name = 'JavaSE-17',
                path = '/usr/lib/jvm/java-17-openjdk',
              },
            },
          },
        },
      },
      on_attach = on_attach,
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
      init_options = {
        bundles = bundles,
      },
    }

    -- Start jdtls when opening Java files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'java',
      callback = function()
        jdtls.start_or_attach(config)
      end,
    })
  end,
}
