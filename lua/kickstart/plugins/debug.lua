-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
    -- Highly recommended for inline variable evaluation during debugging
    'theHamsta/nvim-dap-virtual-text',
  },
  keys = function(_, keys)
    local dap = require 'dap'
    local dapui = require 'dapui'
    return {
      { '<F5>',      dap.continue,          desc = 'Debug: Start/Continue' },
      { '<F1>',      dap.step_into,         desc = 'Debug: Step Into' },
      { '<F2>',      dap.step_over,         desc = 'Debug: Step Over' },
      { '<F3>',      dap.step_out,          desc = 'Debug: Step Out' },
      { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>B',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
      { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Initialize virtual text
    require('nvim-dap-virtual-text').setup()

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve',
        'coreclr', -- Instructs mason-nvim-dap to provision netcoredbg
      },
    }

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- [[ C# / ASP.NET Configuration ]]

    -- 1. Define the Debug Adapter Protocol (DAP) client
    dap.adapters.coreclr = {
      type = 'executable',
      command = 'netcoredbg',
      args = { '--interpreter=vscode' }
    }

    -- 2. Define the execution profiles for C#
    dap.configurations.cs = {
      {
        type = "coreclr",
        name = "launch - netcoredbg",
        request = "launch",
        program = function()
          -- Automatically build the project before starting the debug session
          vim.fn.system('dotnet build')

          -- Dynamically find the compiled .dll.
          -- Note: The 'find' command assumes a Unix-like environment (macOS/Linux/WSL).
          local dll_path = vim.fn.system("find ./bin/Debug/ -name '*.dll' | head -n 1"):gsub("\n", "")

          if dll_path == "" then
            return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
          end
          return vim.fn.getcwd() .. '/' .. dll_path
        end,
        env = {
          -- Standard ASP.NET Core environment variables
          ASPNETCORE_ENVIRONMENT = "Development",
          ASPNETCORE_URLS = "http://localhost:5000"
        },
        cwd = '${workspaceFolder}',
      },
    }
  end,
}
