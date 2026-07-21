-- File: lua/custom/plugins/flash.lua
-- folke/flash.nvim: jump anywhere on screen with a few keystrokes.
--
-- NOTE: flash's default `s`/`S` maps are intentionally NOT used here, because
-- mini.surround owns the `s` prefix in this config. flash still enhances
-- `f`/`t`/`F`/`T` and `/` search automatically (loaded via VeryLazy); the
-- explicit jump/treesitter motions are on <leader>j / <leader>J.

return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  opts = {},
  keys = {
    {
      '<leader>j',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump()
      end,
      desc = 'Flash [J]ump',
    },
    {
      '<leader>J',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').treesitter()
      end,
      desc = 'Flash Treesitter',
    },
  },
}
