-- File: lua/custom/plugins/treesitter-context.lua
-- Sticky header showing the current function / section / theorem at the top of
-- the window as you scroll through a long file.

return {
  'nvim-treesitter/nvim-treesitter-context',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = { max_lines = 3 },
  keys = {
    { '<leader>tx', '<cmd>TSContextToggle<cr>', desc = '[T]oggle Treesitter conte[x]t' },
  },
}
