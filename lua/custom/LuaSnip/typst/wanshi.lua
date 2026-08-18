-- Snippets for wanshi note forests.
--
-- Every snippet here is gated on `in_wanshi`, so they only expand inside a
-- directory holding `Wanshi.toml`. Plain Typst documents are unaffected —
-- `#definition(...)` and friends come from wanshi's bundled library and would
-- be undefined anywhere else.
--
-- Loaded automatically by the `from_lua` loader in init.lua, which keys files
-- by filetype (this is `typst/`).

local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local fmta = require('luasnip.extras.fmt').fmta

--- Only expand inside a wanshi forest.
local function in_wanshi()
  return require('wanshi').find_project() ~= nil
end

--- Today, in the `YYYY-MM-DD` form wanshi sorts most reliably.
local function today()
  return os.date '%Y-%m-%d'
end

local snippets = {}

--- A whole note: import, show rule, metadata. What `wanshi new post` writes,
--- for when a note is created in the editor rather than from the shell.
---
--- The import is root-absolute on purpose — it resolves at any depth in the
--- tree, where a relative one breaks as soon as the note moves.
table.insert(
  snippets,
  s(
    { trig = 'note', desc = 'wanshi: full note skeleton' },
    fmta(
      [[
        #import "/_lib/wanshi.typ": *

        #show: wanshi

        #metadata((
          "title": "<>",
          "taxon": "<>",
          "date": "<>",
          "description": "<>",
        ))

        <>
      ]],
      { i(1, 'Title'), i(2, 'note'), i(3, today()), i(4, 'One sentence.'), i(0) }
    ),
    { condition = in_wanshi }
  )
)

--- The metadata block alone, for a file that already has its preamble.
table.insert(
  snippets,
  s(
    { trig = 'meta', desc = 'wanshi: metadata block' },
    fmta(
      [[
        #metadata((
          "title": "<>",
          "taxon": "<>",
          "date": "<>",
          "description": "<>",
        ))
      ]],
      { i(1, 'Title'), i(2, 'note'), i(3, today()), i(4, 'One sentence.') }
    ),
    { condition = in_wanshi }
  )
)

--- Links and embeds.
---
--- Both take a *slug*, and a leading `/` matters: without it the target
--- resolves relative to the containing directory, so `#local("boolean/x")`
--- inside `boolean/index` looks for `boolean/boolean/x`. The snippets include
--- the slash so that mistake is not available by default.
---
--- Note also that a directory index is linked by its slug, not its URL:
--- `/notes/index`, even though the page is served at `/notes/`.
table.insert(
  snippets,
  s(
    { trig = 'ln', desc = 'wanshi: link another note' },
    fmta([[#local("/<>")<>]], { i(1, 'slug'), i(0) }),
    { condition = in_wanshi }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'lnt', desc = 'wanshi: link with custom text' },
    fmta([[#local("/<>", text: [<>])<>]], { i(1, 'slug'), i(2, 'text'), i(0) }),
    { condition = in_wanshi }
  )
)

--- `title` is a required positional argument, not an option; `#embed("/x")`
--- alone does not compile.
table.insert(
  snippets,
  s(
    { trig = 'embed', desc = 'wanshi: embed another note' },
    fmta([[#embed("/<>", "<>")<>]], { i(1, 'slug'), i(2, 'Title'), i(0) }),
    { condition = in_wanshi }
  )
)

--- Subtree helpers. Each is sugar for `subtree` with a preset taxon, and each
--- named one gets its own slug, page, and place in the graph.
---
--- Omitting `slug:` makes an anonymous subtree: no page of its own and absent
--- from the graph, which is what a proof attached to the statement above it
--- usually wants — hence the separate `prf` trigger below.
local subtrees = {
  { trig = 'def', helper = 'definition', label = 'definition' },
  { trig = 'thm', helper = 'theorem', label = 'theorem' },
  { trig = 'lem', helper = 'lemma', label = 'lemma' },
  { trig = 'cor', helper = 'corollary', label = 'corollary' },
  { trig = 'prop', helper = 'proposition', label = 'proposition' },
  { trig = 'rem', helper = 'remark', label = 'remark' },
  { trig = 'exa', helper = 'example', label = 'example' },
  { trig = 'conj', helper = 'conjecture', label = 'conjecture' },
  { trig = 'obs', helper = 'observation', label = 'observation' },
  { trig = 'exeg', helper = 'exegesis', label = 'exegesis' },
}

for _, sub in ipairs(subtrees) do
  table.insert(
    snippets,
    s(
      { trig = sub.trig, desc = 'wanshi: ' .. sub.label .. ' subtree' },
      fmta('#' .. sub.helper .. '(slug: "<>", title: "<>")[\n  <>\n]', { i(1, 'slug'), i(2, 'Title'), i(0) }),
      { condition = in_wanshi }
    )
  )
end

--- Anonymous by default: a proof belongs to the statement above it and rarely
--- needs its own URL.
table.insert(
  snippets,
  s({ trig = 'prf', desc = 'wanshi: proof (anonymous)' }, fmta('#proof[\n  <>\n]', { i(0) }), { condition = in_wanshi })
)

--- Listings. These are resolved at build time against the whole forest, so a
--- hub written with one never needs editing when a note is added.
table.insert(
  snippets,
  s(
    { trig = 'children', desc = 'wanshi: list this page\'s children' },
    fmta('#children(<>)', { i(0) }),
    { condition = in_wanshi }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'recent', desc = 'wanshi: list recent notes' },
    fmta('#recent(count: <>)', { i(1, '10') }),
    { condition = in_wanshi }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'bytaxon', desc = 'wanshi: list every note of one taxon' },
    fmta('#by-taxon("<>", title: "<>")', { i(1, 'definition'), i(2, 'All definitions') }),
    { condition = in_wanshi }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'orphans', desc = 'wanshi: list unreachable notes' },
    fmta('#orphans(title: "<>")', { i(1, 'Not linked from anywhere') }),
    { condition = in_wanshi }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'query', desc = 'wanshi: custom listing' },
    fmta('#query(from: "<>", sort: "<>", order: "<>", limit: <>, title: "<>")', {
      c(1, { t 'children', t 'descendants', t 'siblings', t 'all', t 'orphans' }),
      c(2, { t 'date', t 'title', t 'slug', t 'taxon' }),
      c(3, { t 'desc', t 'asc' }),
      i(4, '10'),
      i(5, 'Title'),
    }),
    { condition = in_wanshi }
  )
)

--- Diagrams must be wrapped to survive the HTML export: `auto-frame` renders
--- Typst-drawn content as inline SVG, `auto-figure` centres it. A bare
--- `fletcher`/`cetz` diagram does not make it through.
table.insert(
  snippets,
  s(
    { trig = 'fig', desc = 'wanshi: figure that survives HTML export' },
    fmta('#auto-figure(auto-frame(\n  <>\n))', { i(0) }),
    { condition = in_wanshi }
  )
)

--- A named subtree repeated as its own heading is common enough to warrant the
--- `title` being echoed into the slug when they match.
table.insert(
  snippets,
  s(
    { trig = 'sub', desc = 'wanshi: generic subtree' },
    fmta('#subtree(slug: "<>", title: "<>", taxon: "<>")[\n  <>\n]', {
      i(1, 'slug'),
      i(2, 'Title'),
      i(3, 'note'),
      i(0),
    }),
    { condition = in_wanshi }
  )
)

return snippets
