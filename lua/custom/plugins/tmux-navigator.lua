-- File: lua/custom/plugins/tmux-navigator.lua
-- Seamless navigation between Neovim splits and tmux panes with <C-h/j/k/l>:
-- hit the edge of your splits and the same key crosses into the adjacent tmux
-- pane (e.g. your Claude Code pane), and back. Outside tmux these just move
-- between Neovim windows, so it's safe everywhere.
--
-- Requires the matching bindings in ~/.tmux.conf (vim-tmux-navigator section).

return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
  },
  keys = {
    { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate left (split/pane)' },
    { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate down (split/pane)' },
    { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate up (split/pane)' },
    { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate right (split/pane)' },
  },
}
