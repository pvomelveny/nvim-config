-- File: lua/custom/plugins/diffview.lua
-- sindrets/diffview.nvim: review diffs and file/branch history in-editor, and
-- resolve merge conflicts. Complements gitsigns (gutter) and lazygit (staging).

return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {},
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diffview: open (working tree)' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diffview: current file history' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'Diffview: repo history' },
    { '<leader>gc', '<cmd>DiffviewClose<cr>', desc = 'Diffview: close' },
  },
}
