# Editing wanshi note forests

[wanshi](https://github.com/pvomelveny/wanshi) is a Typst-only Zettelkasten
generator. A *forest* is any directory holding `Wanshi.toml`, with sources under
`trees/` and a bundled library at `trees/_lib/wanshi.typ`.

This file covers the **editing** half — what this config adds. The **edit-link**
half (clicking `[edit]` on a served page to open it here) is a separate piece
living in `~/dotfiles/wanshi-editor-link/`, which has its own README.

Everything below is scoped to a detected forest. Outside one, `gf` and
`<leader>n` keep their ordinary meanings and none of it costs anything.

## What you get

| | |
| --- | --- |
| `gf` | follow the `#local`/`#embed` link under the cursor |
| `<leader>nb` | backlinks **and** Found in — everything that points here |
| `<leader>nl` | links — what this note points at |
| `<leader>nf` | find any note in the forest |

Plus slug completion inside `#local("…")` / `#embed("…")` showing each note's
title and taxon, and 28 snippets: `note`, `meta`, all sixteen subtree helpers
(`def`, `thm`, `lem`, `prf`, `ax`, `clm`, `fct`, `hyp`, `post`, …),
`ln`/`lnt`/`embed`, and the listings (`children`, `recent`, `bytaxon`,
`orphans`, `query`).

## Two kinds of backlink

wanshi records two reverse edges and keeps them apart deliberately, because
citing a note and containing one are different relationships:

| Edge | Reverse of | Shown on the page as |
| --- | --- | --- |
| `backlinks` | `#local()` | Backlinks |
| `embedded_by` | `#embed()` | Found in |

`embedded_by` exists because an embed's other trace is fragile. Embedding also
makes the host the *parent* of the embedded note — but `parent` holds a single
slug, and one the note declares for itself replaces the embedder entirely. Since
declaring a parent is the recommended fix for a note embedded in several places,
following that advice used to erase every record of the embedding. `embedded_by`
records every host, and only direct ones: if A embeds B and B embeds C, C records
B, not A.

`<leader>nb` answers both at once — while writing, the question is "what points
at this?", and needing two keys for half an answer each is the wrong shape. A
note in both lists appears **once**, tagged:

```
Backlinks & Found in — guide/chain-middle

  link        guide/chain-inner    Chain, inner
  link+embed  guide/embeds         Embedding notes   (guide)
```

The tag is searchable, so typing `embed` narrows to one kind.

## Layout

```
lua/wanshi/init.lua               detection, slug ↔ path, reads the artifacts
lua/wanshi/navigate.lua           gf and the three pickers
lua/wanshi/complete.lua           blink.cmp source for slugs
lua/custom/LuaSnip/typst/wanshi.lua   snippets
```

Four touchpoints in `init.lua`: the `tinymist` entry's `root_dir`, the
`wanshi` blink provider, the `<leader>n` which-key group, and a single
`require('wanshi.navigate').setup()` before the lazy bootstrap.

## Why tinymist needs a custom root

Every note opens with a **root-absolute** import:

```typst
#import "/_lib/wanshi.typ": *
```

`/` there means Typst's root, not the filesystem. wanshi compiles with
`--root <project>/trees`, but lspconfig ships `root_markers = { '.git' }`, so
tinymist rooted at the *host repository* for an embedded forest and searched
`<repo>/_lib/wanshi.typ`. Result: a spurious `file not found` on line 1 of every
note, and no completion for wanshi's own helpers.

`root_dir` now reads `[build].typst-root` out of `Wanshi.toml` rather than
hardcoding `trees`, since it is configurable. Fixing it also made tinymist read
the library, so `#defini` → `definition` now comes from the LSP with real
signatures — the snippets scaffold structure, but discovery is the LSP's job.

## Gotchas

- **The `servers` table was silently inert.** mason-lspconfig v2 removed the
  `handlers` key, so kickstart's `require('lspconfig')[name].setup(server)` never
  ran — every server started with stock defaults. `tinymist.settings` was `{}`
  and `lua_ls`'s `callSnippet` was `nil`. It failed *quietly*: the servers still
  attached, just unconfigured. Now a `vim.lsp.config()` + `vim.lsp.enable()` loop.
  If a server override ever seems ignored, check that loop first.

- **Two `root_dir` signatures exist.** `vim.lsp.config` takes
  `fun(bufnr, on_dir)` and adopts the root only if `on_dir` is called;
  lspconfig's old framework took `fun(fname, bufnr)` returning a string. This
  config uses the former. Getting it wrong fails silently — the root just stays
  at the default.

- **`links()` cannot use the graph.** `wanshi.graph.json`'s `references` field
  means *citation* targets (the `asref` mechanism), not outbound links. A note
  that plainly `#local`s another contributes a backlink to the target but
  nothing to its own `references`, so a graph-based "links from here" would be
  permanently empty. It scans the buffer instead — which is also live.

- **Backlinks and completion go stale.** They read generated artifacts
  (`wanshi.json`, `wanshi.graph.json`), so they reflect the last build. Keep
  `npm run notes:watch` — or `wanshi serve --indexes` — running while writing.
  Note that plain `wanshi serve` defaults indexes **off** and will delete the
  index a build wrote.

- **A named subtree has no file of its own.** `#definition(slug: "…")` and
  friends are sections written *inside* another note, so they appear in
  `wanshi.json` and the graph while `path_in` finds nothing for them — 5 of the
  21 sections in wanshi's own demo forest are like this. The pickers follow
  `embedded_by` (then `parent`) to the nearest section that does have a file and
  open that, showing `in <host>` on the row. The walk is transitive, since a
  subtree can be written inside a subtree.

- **Slugs are not filenames.** A directory index is linked by slug
  (`#local("/boolean/index")`) even though it is *served* at `/boolean/`. And a
  target without a leading `/` resolves against the containing directory, so
  `#local("boolean/x")` inside `boolean/index` means `boolean/boolean/x`. `gf`
  implements both rules; the `ln` snippet includes the slash so the second
  mistake is not the default.

## Checking it works

```lua
:lua =require('wanshi').root_for()      -- should end in /trees inside a forest
:lua =require('wanshi').slug_of()       -- the current note's slug
:lua =#require('wanshi').notes()        -- 0 means the forest has not been built
:checkhealth vim.lsp                    -- tinymist's root_dir
```

If notes show a `file not found` on their import line, `root_for()` returned
`nil` — either `Wanshi.toml` is missing above the file, or `[build].typst-root`
names a directory that does not exist.

## Related

- `~/dotfiles/wanshi-editor-link/` — the `nvim://` URL handler that makes
  `[edit]` links open here. Separate because it is a macOS app bundle and a
  shell helper, not Neovim config.
- The host site's `CLAUDE.md` ("Writing in Neovim") records the same workflow
  from the notes side, plus the npm scripts that drive builds.
- wanshi's own `docs/users/` — `writing-notes.md` and
  `links-and-references.md` are the authority on slugs, taxons, and linking.
