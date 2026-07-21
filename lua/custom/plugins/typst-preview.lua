-- File: lua/custom/plugins/typst-preview.lua
-- Live browser preview for Typst documents that scrolls in sync with the
-- buffer -- the Typst analogue of your VimTeX + Skim setup for LaTeX.
--
-- Commands: :TypstPreview, :TypstPreviewStop, :TypstPreviewToggle.
-- The `build` step downloads the small preview backend on install/update.

return {
  'chomosuke/typst-preview.nvim',
  ft = 'typst', -- only load when editing a Typst file
  version = '1.*',
  build = function()
    require('typst-preview').update()
  end,
  opts = {},
  keys = {
    { '<leader>tp', '<cmd>TypstPreviewToggle<cr>', ft = 'typst', desc = '[T]ypst [P]review toggle' },
  },
}
