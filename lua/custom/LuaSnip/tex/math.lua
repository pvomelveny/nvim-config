-- Abbreviations used in this article and the LuaSnip docs
local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep

-- Include this `in_mathzone` function at the start of a snippets file...
local in_mathzone = function()
  -- The `in_mathzone` function requires the VimTeX plugin
  return vim.fn['vimtex#syntax#in_mathzone']() == 1
end
-- Then pass the table `{condition = in_mathzone}` to any snippet you want to
-- expand only in math contexts.

return {

  -- Letters and Symbols
  --  Greek Letters
  s({ trig = ';a', snippetType = 'autosnippet' }, {
    t '\\alpha',
  }),
  s({ trig = ';b', snippetType = 'autosnippet' }, {
    t '\\beta',
  }),
  s({ trig = ';d', snippetType = 'autosnippet' }, {
    t '\\delta',
  }),
  s({ trig = ';e', snippetType = 'autosnippet' }, {
    t '\\varepsilon',
  }),
  s({ trig = ';f', snippetType = 'autosnippet' }, {
    t '\\varphi',
  }),
  s({ trig = ';g', snippetType = 'autosnippet' }, {
    t '\\gamma',
  }),
  s({ trig = ';l', snippetType = 'autosnippet' }, {
    t '\\lambda',
  }),
  s({ trig = ';p', snippetType = 'autosnippet' }, {
    t '\\pi',
  }),
  s({ trig = ';t', snippetType = 'autosnippet' }, {
    t '\\tau',
  }),
  s({ trig = ';w', snippetType = 'autosnippet' }, {
    t '\\omega',
  }),

  -- Trigger fractions automatically in mathmode
  s(
    { trig = 'ff', snippetType = 'autosnippet' },
    fmta('\\frac{<>}{<>}', {
      i(1),
      i(2),
    }),
    { condition = in_mathzone } -- `condition` option passed in the snippet `opts` table
  ),
}
