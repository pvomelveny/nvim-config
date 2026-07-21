-- File: lua/custom/plugins/snacks.lua
-- folke/snacks.nvim: a collection of small QoL modules. We enable the ones that
-- don't overlap with plugins you already run -- telescope (picker), neo-tree
-- (explorer) and indent-blankline (indent) are kept, so those snacks modules
-- stay off to avoid duplication.

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false, -- snacks is foundational (bigfile/quickfile run before other plugins)
  opts = {
    bigfile = { enabled = true }, -- disable heavy features on very large files
    quickfile = { enabled = true }, -- render a file before plugins finish loading
    notifier = { enabled = true }, -- a nicer vim.notify() with history
    input = { enabled = true }, -- floating vim.ui.input() (e.g. LSP rename)
    dashboard = { enabled = true }, -- start screen when opening `nvim` with no file
    zen = { enabled = true }, -- distraction-free focus mode
    dim = { enabled = true }, -- dim code outside the current scope (twilight-like)
    lazygit = { enabled = true }, -- lazygit in a float (requires the `lazygit` binary)
    gitbrowse = { enabled = true }, -- open the current line on the remote (GitHub, etc.)
  },
  keys = {
    {
      '<leader>z',
      function()
        Snacks.zen()
      end,
      desc = '[Z]en mode',
    },
    {
      '<leader>td',
      function()
        -- Toggle scope dimming. Track state ourselves so this works regardless
        -- of snacks internals.
        if vim.g.snacks_dim_on then
          Snacks.dim.disable()
          vim.g.snacks_dim_on = false
        else
          Snacks.dim()
          vim.g.snacks_dim_on = true
        end
      end,
      desc = '[T]oggle [D]im',
    },
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazy[g]it',
    },
    {
      '<leader>gB',
      function()
        Snacks.gitbrowse()
      end,
      mode = { 'n', 'v' },
      desc = 'Git [B]rowse (open on remote)',
    },
    {
      '<leader>n',
      function()
        Snacks.notifier.show_history()
      end,
      desc = '[N]otification history',
    },
  },
}
