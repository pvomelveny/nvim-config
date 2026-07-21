-- File: lua/custom/plugins/filetree.lua
-- neo-tree: a file explorer sidebar. Toggle/reveal with `\`.

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
    -- NOTE: '3rd/image.nvim' (image preview) was removed: it requires
    -- ImageMagick + a compatible terminal and otherwise surfaces health
    -- warnings. Add it back if you want in-tree image previews.
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
