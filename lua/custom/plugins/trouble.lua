-- File: lua/custom/plugins/trouble.lua
-- folke/trouble.nvim: a navigable panel for diagnostics, LSP references, and
-- the quickfix/location lists. Keymaps live under the <leader>x group.

return {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  opts = {},
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer diagnostics (Trouble)' },
    { '<leader>xs', '<cmd>Trouble symbols toggle<cr>', desc = 'Symbols (Trouble)' },
    { '<leader>xr', '<cmd>Trouble lsp toggle<cr>', desc = 'LSP references/defs (Trouble)' },
    { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location list (Trouble)' },
    { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix list (Trouble)' },
  },
}
