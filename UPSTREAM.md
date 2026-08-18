# Upstream sync (kickstart.nvim)

This config is a fork of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
It has diverged far enough that a plain merge is no longer viable, so upstream
changes get **ported by hand**. This file records what has been taken, what has
been deliberately left, and what still needs doing.

Keep it current when you sync — the value here is the *reasons*, which are
expensive to re-derive and invisible in the diff.

```
origin    git@github.com:pvomelveny/nvim-config.git
upstream  git@github.com:nvim-lua/kickstart.nvim.git
```

## State as of 2026-08-17

| | |
|---|---|
| merge base | `3338d39` "Update remaining Mason's old address" |
| divergence | 85 behind, 20 ahead |
| last port | `3b9aa27` |

### Why not just merge

Upstream **replaced lazy.nvim with `vim.pack`** (Neovim's built-in plugin
manager, commit `c460542`) and restructured `init.lua` into flat `do ... end`
blocks labelled `SECTION 1..10`. A trial merge produces conflicts in
`.gitignore`, `lua/kickstart/plugins/debug.lua`, and `init.lua` — with **1695 of
1997 lines of `init.lua` inside conflict markers** (measured 2026-08-17; the
ratio only grows as this fork diverges further). There is nothing meaningful to
resolve; they are two different files.

Reproduce the assessment any time with:

```sh
git fetch upstream
git worktree add --detach /tmp/ks-merge master
git -C /tmp/ks-merge merge --no-commit --no-ff upstream/master
git -C /tmp/ks-merge diff --name-only --diff-filter=U
git worktree remove --force /tmp/ks-merge
```

## Deferred work

### 1. nvim-treesitter `master` → `main` — the one with a deadline

**Both branches this config pins are frozen upstream.**

- `nvim-treesitter` `master`: last commit is `42fc28ba` (2025-05-18),
  *"docs(readme)!: announce archiving of master branch"*. Its README carries a
  CAUTION: *"The `master` branch is frozen and provided for backward
  compatibility only. All future updates happen on the `main` branch, which will
  become the default branch in the future."*
- `nvim-treesitter-textobjects` `master`: last commit *"docs: master is frozen"*
  (2025-10-31), same notice.

Nothing breaks today, and frozen means frozen rather than deleted — but no new
parsers, no fixes, and no new Neovim compatibility work land on either branch.
This is the item most likely to force itself at an inconvenient moment.

**What the migration actually is.** `main` is not a new version of the same API,
it is a different design. The `master` branch is a module system driven by a
declarative `opts` table; `main` is a small install/attach library that you wire
into a `FileType` autocommand yourself.

Currently in `init.lua` (the `nvim-treesitter` spec):

```lua
branch = 'master',
main = 'nvim-treesitter.configs',
opts = {
  ensure_installed = { ... ~40 parsers ... },
  auto_install = true,
  highlight = { enable = true, disable = { 'latex' }, additional_vim_regex_highlighting = { ... } },
  indent = { enable = true, disable = { 'ruby' } },
  textobjects = { select = { ... }, move = { ... } },
}
```

On `main` there is no `ensure_installed`, no `highlight`, no `indent`, and no
`textobjects` key. Instead:

- parsers install via `require('nvim-treesitter').install { ... }`
- highlighting starts per-buffer with `vim.treesitter.start(buf, lang)`
- indentation is an option: `vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`,
  and only when `vim.treesitter.query.get(lang, 'indents')` exists
- textobjects move to the textobjects plugin's own `main` branch with a
  different setup shape

Upstream's `SECTION 9` in `init.lua` is a complete worked example of the new
form, including auto-install-on-open via
`require('nvim-treesitter').install(language):await(...)`. Read it before
starting:

```sh
git show upstream/master:init.lua | sed -n '897,960p'
```

**Watch out for, when doing this:**

- `additional_vim_regex_highlighting` and per-language `disable` lists have no
  direct equivalent. This config disables treesitter highlight for `latex` and
  keeps vim regex highlighting for `latex`/`markdown`/`ruby` — that interacts
  with VimTeX and `render-markdown`, so verify those still render.
- `indent = { disable = { 'ruby' } }` similarly needs re-expressing.
- The textobjects keymaps (`af`/`if`, `ac`/`ic`, `aa`/`ia`, `]f`/`[f`, `]c`/`[c`)
  are configured through the plugin on `master` and must be rebuilt on `main`.
- `nvim-treesitter-context` and `lean.nvim` both sit on treesitter; re-check them
  after.

Do it on a branch, and expect it to be an afternoon rather than a patch.

### 2. `vim.pack` migration — optional, large

Upstream's reason for moving is that `vim.pack` ships with Neovim (0.12+, which
this machine runs) and removes a dependency. lazy.nvim is not deprecated and
nothing here is broken, so this is a preference, not maintenance.

Cost is high: every plugin spec in `init.lua` plus the 13 specs in
`lua/custom/plugins/` and 6 in `lua/kickstart/plugins/` uses lazy.nvim's spec
format (`opts`, `dependencies`, `event`, `ft`, `keys`, `cond`, `build`). Lazy
loading in particular has no one-to-one translation — `vim.pack` has no `event`
or `keys` equivalent, so anything relying on deferred loading needs rethinking.

Recommendation: don't, unless lazy.nvim actually becomes a problem.

### 3. `nvim-web-devicons` → `mini.icons` (upstream `ec3f448`)

Upstream dropped `nvim-web-devicons` for `mini.icons`, using
`MiniIcons.mock_nvim_web_devicons()` for plugins that still expect the old API.

Deferred because `nvim-web-devicons` is a declared dependency in four places
here and works fine:

- `init.lua` (telescope)
- `lua/kickstart/plugins/neo-tree.lua`
- `lua/custom/plugins/filetree.lua`
- `lua/custom/plugins/render-markdown.lua`

`mini.nvim` is already installed, so the swap is cheap if wanted — but the mock
is a compatibility shim, and four consumers means four things to re-verify for
no functional gain.

### 4. `format_on_save` whitelist (upstream `ce353a9`) — decided against

Upstream inverted `format_on_save` from a blacklist (`disable_filetypes = { c, cpp }`)
to a whitelist that ships **empty**, i.e. formats nothing until you opt a
filetype in.

**Do not port this.** This config depends on format-on-save for Typst
(`tinymist` + `typstyle`, see the `tinymist` entry in `servers`) and Lua
(`stylua`). Taking it verbatim would silently switch formatting off everywhere.
If the blacklist ever needs to become a whitelist, populate it first.

## Already ported

Hand-ported in `3b9aa27` unless noted. Upstream SHAs are on `upstream/master`.

| Upstream | Change | Note |
|---|---|---|
| `b2af42a` | `guess-indent` gets `opts = {}` | Real bug: it registers its command and autocommands inside `setup()` and ships no `plugin/` file, so as a bare string spec lazy.nvim never initialized it. It was installed and completely inert. |
| `c8e189f` | `mini.nvim` → `nvim-mini/mini.nvim` | Org moved. Old path is still a redirect. Run `:Lazy sync` to re-point the existing clone. |
| `1f4c21f` | Drop manual blink.cmp capabilities broadcast | blink registers `vim.lsp.config('*', { capabilities = ... })` from its own `plugin/blink-cmp.lua`, so per-server merging was redundant. |
| `3ddda4a` | Drop `client_supports_method` shim | Only existed to straddle nvim 0.10/0.11. |
| `716d746` | `vim.loader.enable()` | Caches compiled Lua modules. |
| `8c6b78c` | `<leader>sw` in visual mode | Greps the selection. |
| `8f479db` | `<leader>sc` → `builtin.commands` | |
| `80b1ee1` | `gr` which-key group | |
| `dabce46` | Underline warnings, not just errors | |
| — | `vim.lsp.config`/`vim.lsp.enable` instead of mason-lspconfig `handlers` | Done independently in `57854ed` before noticing upstream `3a2194f` had made the same change. v2 removed `handlers`, so the old block had silently stopped applying anything in `servers`. |

### Not applicable

- `bd53f28`, `b01d052`, `b9f3965` — upstream's `lua_ls` `on_init` rework. This
  config uses `lazydev.nvim` instead, which covers the same ground.
  (`bd53f28` is worth knowing about anyway: `vim.tbl_extend('force', ...)` on two
  *lists* merges by integer index, so appending `${3rd}/...` entries to
  `nvim_get_runtime_file('', true)` silently overwrites the first entries. If
  that pattern ever gets copied in here, it is a trap.)
- `a5d4d12` — deprecated `jump = { float = true }` diagnostic config. Never
  present here.
- CI workflows, issue templates, README — upstream project infrastructure.

## Checking for new upstream work

```sh
git fetch upstream
git log --oneline --no-merges $(git merge-base master upstream/master)..upstream/master
```

Most of what that lists is the `vim.pack` restructure and docs churn. Filter for
substance with:

```sh
git log --oneline --no-merges $(git merge-base master upstream/master)..upstream/master \
  | grep -viE 'readme|comment|section|doc|typo|ci|workflow|template|vim\.pack'
```

To see one commit's actual effect: `git show <sha> -- init.lua`.
