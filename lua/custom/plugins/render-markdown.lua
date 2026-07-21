-- File: lua/custom/plugins/render-markdown.lua
-- In-buffer rendering of Markdown (headings, lists, tables, code blocks, LaTeX
-- math) while you edit. Toggle with <leader>tm.

return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown', 'markdown_inline' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {},
  keys = {
    { '<leader>tm', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = '[T]oggle [M]arkdown render' },
  },
}
