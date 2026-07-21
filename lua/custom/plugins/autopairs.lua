-- File: lua/custom/plugins/autopairs.lua
-- Automatically close brackets, quotes, etc.
--
-- NOTE: This config uses blink.cmp (not nvim-cmp) for completion, and blink
-- handles inserting function-call parens on its own. So nvim-autopairs only
-- needs its standalone setup here -- no completion-engine integration.

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    require('nvim-autopairs').setup {}
  end,
}
