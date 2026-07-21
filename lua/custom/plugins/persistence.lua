-- File: lua/custom/plugins/persistence.lua
-- folke/persistence.nvim: automatically save a session per working directory.
-- Sessions are NOT auto-restored (to avoid surprises); load one on demand from
-- the <leader>Q (Session) group.

return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  keys = {
    {
      '<leader>Qs',
      function()
        require('persistence').load()
      end,
      desc = 'Restore session (this dir)',
    },
    {
      '<leader>Ql',
      function()
        require('persistence').load { last = true }
      end,
      desc = 'Restore last session',
    },
    {
      '<leader>Qd',
      function()
        require('persistence').stop()
      end,
      desc = "Don't save current session",
    },
  },
}
