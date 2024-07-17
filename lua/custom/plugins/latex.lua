-- File: lua/custom/plugins/autopairs.lua

return {
  {
    'lervag/vimtex',
    lazy = false, -- lazy-loading will disable inverse search
    config = function()
      vim.g.vimtex_mappings_disable = { ['n'] = { 'K' } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_method = vim.fn.executable 'pplatex' == 1 and 'pplatex' or 'latexlog'

      -- Setup for Skim PDF viewer on Mac
      -- TODO: Make this adaptable to either mac or linux
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = true

      -- Some Personal Modifications
      vim.g.vimtex_env_toggle_math_map = {

        ['\\('] = '\\[',
        ['\\['] = 'equation',
        equation = '\\(',
        ['$$'] = '\\[',
        ['$'] = '\\(',
      }
    end,
  },
}
