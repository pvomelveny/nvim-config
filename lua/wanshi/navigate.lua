--- Moving around a wanshi forest without leaving the editor.
---
--- Two directions, which together are what a Zettelkasten is for:
---
---   * `follow()`    — `gf` on a `#local`/`#embed` target, forward along a link
---   * `links()`     — everything this note points at
---   * `backlinks()` — everything pointing here
---   * `find()`      — every note in the forest
---
--- `follow` and `links` read the buffer, so they include links written since
--- the last build. `backlinks` and `find` read generated artifacts
--- (`wanshi.graph.json`, `wanshi.json`) and are therefore as current as the
--- last build — keep `npm run notes:watch` running and they stay live.
---
--- Backlinks cannot come from the buffer: they are the one direction only the
--- whole forest knows.

local wanshi = require 'wanshi'

local M = {}

--- The `#local` / `#embed` target under (or nearest before) the cursor.
---
--- Scans the whole line rather than using `<cfile>`: a slug contains slashes
--- and lives inside quotes, so Vim's idea of "the filename under the cursor"
--- is wrong here in both directions.
---
--- Only the *first* string argument counts. In `#embed("/x", "Title")` the
--- title is not a target, so the match is anchored to the opening paren.
---@return string? target
local function target_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  for _, fn in ipairs { 'local', 'embed' } do
    local init = 1
    while true do
      local s, e, target = line:find('#' .. fn .. '%(%s*"([^"]*)"', init)
      if not s then
        break
      end
      -- Accept a cursor anywhere in the call, not just inside the quotes:
      -- pressing gf with the cursor on `#local` should work.
      if col >= s and col <= e then
        return target
      end
      init = e + 1
    end
  end

  -- Nothing under the cursor: fall back to the first target on the line, so a
  -- line carrying exactly one link works from anywhere on it.
  for _, fn in ipairs { 'local', 'embed' } do
    local target = line:match('#' .. fn .. '%(%s*"([^"]*)"')
    if target then
      return target
    end
  end
  return nil
end

--- Follow the link under the cursor to the note's source.
---
--- Bound to `gf` in forest buffers. Falls back to the built-in `gf` when there
--- is no link here, so the key keeps its ordinary meaning on, say, an import
--- path.
function M.follow()
  local target = target_under_cursor()
  if not target then
    -- `norm!` avoids recursing into this mapping.
    local ok = pcall(vim.cmd, 'normal! gf')
    if not ok then
      vim.notify('wanshi: no link under cursor', vim.log.levels.INFO)
    end
    return
  end

  local from = wanshi.slug_of()
  local slug = wanshi.resolve_target(target, from)
  local path = wanshi.path_of(slug)

  if not path then
    -- A dangling link is a legitimate way to work — wanshi treats it as a
    -- warning, not an error — so offer to create the note rather than refuse.
    local root = wanshi.root_for()
    local intended = root and vim.fs.joinpath(root, slug .. '.typ')
    vim.notify(('wanshi: `%s` resolves to `%s`, which does not exist yet'):format(target, slug), vim.log.levels.WARN)
    if intended and vim.fn.confirm('Create ' .. slug .. '.typ?', '&Yes\n&No', 2) == 1 then
      vim.fn.mkdir(vim.fs.dirname(intended), 'p')
      vim.cmd.edit(vim.fn.fnameescape(intended))
    end
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

--- Rows for a telescope picker: slug plus title, for a list of slugs.
---
--- `kinds` labels *why* each slug is listed, and is only passed by `backlinks`,
--- where a note can be here for two different reasons. The other pickers pass
--- nothing and render exactly as before.
---@param slugs string[]
---@param kinds table<string, string>? slug -> tag, e.g. 'link+embed'
---@return { slug: string, title: string, taxon: string?, path: string?, kind: string?, host: string? }[]
local function decorate(slugs, kinds)
  local by_slug = {}
  for _, note in ipairs(wanshi.notes()) do
    by_slug[note.slug] = note
  end
  -- Resolve the root and the graph once. `path_of` re-derives the root per slug,
  -- which is an upward directory walk and a `Wanshi.toml` read each time — fine
  -- for a single lookup, but this runs over every entry in the picker.
  local root = wanshi.root_for()
  local graph = wanshi.graph()
  local out = {}
  for _, slug in ipairs(slugs) do
    local note = by_slug[slug] or {}
    -- `source_for`, not `path_in`: a named subtree has no file of its own, and
    -- opening the note that contains it is what the reader actually wants.
    local path, host
    if root then
      path, host = wanshi.source_for(slug, root, graph)
    end
    table.insert(out, {
      slug = slug,
      title = note.title or slug,
      taxon = note.taxon,
      path = path,
      host = host,
      kind = kinds and kinds[slug] or nil,
    })
  end
  table.sort(out, function(a, b)
    return a.slug < b.slug
  end)
  return out
end

--- Show a set of notes in telescope and open the chosen one.
---@param entries table[]
---@param title string
local function pick(entries, title)
  if #entries == 0 then
    vim.notify('wanshi: ' .. title .. ' — none', vim.log.levels.INFO)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          local display = ('%-34s %s'):format(entry.slug, entry.title)
          if entry.taxon then
            display = display .. '  (' .. entry.taxon .. ')'
          end
          -- Only the backlinks picker sets `kind`; elsewhere the row is
          -- unchanged, so no empty column appears in `nl` and `nf`.
          if entry.kind then
            display = ('%-11s %s'):format(entry.kind, display)
          end
          -- Selecting this row opens a different file than the slug names, so
          -- say which one rather than jumping somewhere unannounced.
          if entry.host then
            display = display .. '  in ' .. entry.host
          end
          return {
            value = entry,
            display = display,
            -- Slug, title, tag and host are all searchable: the slug is a path,
            -- the title is what you actually remember, and typing `embed`
            -- narrows to one kind of relationship.
            ordinal = table.concat({ entry.kind or '', entry.slug, entry.title, entry.host or '' }, ' '),
            path = entry.path,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      -- Notes are prose, so the file preview is genuinely readable here.
      previewer = conf.file_previewer {},
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(bufnr)
          if selection and selection.value.path then
            vim.cmd.edit(vim.fn.fnameescape(selection.value.path))
          elseif selection then
            vim.notify('wanshi: `' .. selection.value.slug .. '` has no source file', vim.log.levels.WARN)
          end
        end)
        return true
      end,
    })
    :find()
end

--- Everything that points at this note, of either kind.
---
--- wanshi records two reverse edges, and keeps them apart on purpose: citing a
--- note and containing one are different relationships.
---
---   * `backlinks`   — the reverse of `#local`. A cites B, so B lists A.
---   * `embedded_by` — the reverse of `#embed`, shown as "Found in" on the
---     published page. A contains B, so B lists A.
---
--- Both are derived, never written by hand, and both are answered here: the
--- question while writing is "what points at this?", and having to press two
--- keys to get half an answer each time would be the wrong shape.
---
--- A note can be in both lists — linking something you also embed is ordinary —
--- so they are merged by slug and tagged rather than concatenated. One row per
--- note, because the row is a file you are about to open.
function M.backlinks()
  local slug = wanshi.slug_of()
  if not slug then
    vim.notify('wanshi: not a note', vim.log.levels.WARN)
    return
  end
  local section = wanshi.graph()[slug]
  if not section then
    vim.notify('wanshi: `' .. slug .. '` is not in the graph — build the forest first', vim.log.levels.WARN)
    return
  end

  local seen, slugs = {}, {}
  local function add(list, key)
    for _, other in ipairs(list or {}) do
      if not seen[other] then
        seen[other] = {}
        table.insert(slugs, other)
      end
      seen[other][key] = true
    end
  end
  add(section.backlinks, 'link')
  add(section.embedded_by, 'embed')

  local kinds = {}
  for other, found in pairs(seen) do
    kinds[other] = found.link and (found.embed and 'link+embed' or 'link') or 'embed'
  end

  pick(decorate(slugs, kinds), 'Backlinks & Found in — ' .. slug)
end

--- Notes this one links to.
---
--- Scans the buffer rather than the graph. `wanshi.graph.json`'s `references`
--- field is narrower than it sounds: it holds *citation* targets — sections
--- reached through the `asref` mechanism — not outbound links in general. A
--- note that plainly links another with `#local` contributes a backlink on the
--- target but nothing to its own `references`, so reading the graph here would
--- give an all-but-permanently empty list.
---
--- Reading the buffer is also live: links added since the last build are
--- included, which matches how it feels to be writing one.
function M.links()
  local slug = wanshi.slug_of()
  if not slug then
    vim.notify('wanshi: not a note', vim.log.levels.WARN)
    return
  end

  local seen, slugs = {}, {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    for _, fn in ipairs { 'local', 'embed' } do
      for target in line:gmatch('#' .. fn .. '%(%s*"([^"]*)"') do
        local resolved = wanshi.resolve_target(target, slug)
        if not seen[resolved] then
          seen[resolved] = true
          table.insert(slugs, resolved)
        end
      end
    end
  end

  pick(decorate(slugs), 'Links from ' .. slug)
end

--- Every note in the forest.
function M.find()
  local slugs = {}
  for _, note in ipairs(wanshi.notes()) do
    table.insert(slugs, note.slug)
  end
  pick(decorate(slugs), 'Notes')
end

--- Buffer-local keymaps, applied only to notes inside a forest.
---
--- Buffer-local on purpose: `gf` keeps its built-in meaning everywhere else,
--- and the `<leader>n` group does not appear in unrelated buffers.
function M.attach(bufnr)
  local function map(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map('gf', M.follow, 'wanshi: follow link under cursor')
  map('<leader>nb', M.backlinks, 'wanshi: [N]ote [B]acklinks (what links here)')
  map('<leader>nl', M.links, 'wanshi: [N]ote [L]inks (what this links to)')
  map('<leader>nf', M.find, 'wanshi: [N]ote [F]ind')
end

--- Attach to every Typst buffer that turns out to be inside a forest.
function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    desc = 'wanshi forest navigation',
    group = vim.api.nvim_create_augroup('wanshi-navigate', { clear = true }),
    pattern = 'typst',
    callback = function(args)
      if wanshi.find_project(vim.api.nvim_buf_get_name(args.buf)) then
        M.attach(args.buf)
      end
    end,
  })
end

return M
