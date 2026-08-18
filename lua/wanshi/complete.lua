--- A blink.cmp source completing wanshi slugs inside `#local(...)` and
--- `#embed(...)`.
---
--- Linking is the substance of a Zettelkasten, and it was the highest-friction
--- part of writing one: a slug is a path, not a title, so getting it right
--- otherwise means leaving the editor to look it up. Getting it *wrong* is
--- quiet — `wanshi check` reports a dangling link, but not until you run it,
--- and `npm run build` gates on it, so a typo breaks the build.
---
--- Candidates come from the generated `wanshi.json`, so they are only as
--- current as the last build. That is the trade for costing nothing to
--- maintain: no parsing here, and the list always agrees with what the site
--- actually published.
---
--- Registered in init.lua under `sources.providers.wanshi`.

local wanshi = require 'wanshi'

--- @class blink.cmp.Source
local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

--- Only inside a forest. Elsewhere `#local` means nothing and the source
--- should not even be consulted.
function M:enabled()
  return vim.bo.filetype == 'typst' and wanshi.find_project() ~= nil
end

--- `"` opens the slug string; `/` is the separator inside one, so retriggering
--- there keeps the list live as a nested slug is typed.
function M:get_trigger_characters()
  return { '"', '/' }
end

--- Match a cursor sitting inside the *first* string argument of `#local(` or
--- `#embed(`.
---
--- Anchored on an unterminated string — `[^"]*$` cannot cross the closing
--- quote — so the source stays silent once the slug is closed, and in
--- `#embed("/x", "Title")` it does not fire again inside the title.
---@param line_to_cursor string
---@return string? typed the slug text already entered, without its leading `/`
---@return integer? start_col 0-indexed column where that text begins
local function slug_context(line_to_cursor)
  local typed
  for _, fn in ipairs { 'local', 'embed' } do
    typed = line_to_cursor:match('#' .. fn .. '%(%s*"([^"]*)$')
    if typed then
      break
    end
  end
  if not typed then
    return nil, nil
  end
  -- The typed text begins right after the quote that opened it.
  local start_col = #line_to_cursor - #typed
  -- A leading slash is part of the syntax, not of the slug, so keep it out of
  -- the replaced range: the user keeps whatever they typed.
  if typed:sub(1, 1) == '/' then
    typed = typed:sub(2)
    start_col = start_col + 1
  end
  return typed, start_col
end

function M:get_completions(ctx, callback)
  local line = ctx.line:sub(1, ctx.cursor[2])
  local typed, start_col = slug_context(line)
  if not typed then
    callback { items = {}, is_incomplete_backward = false, is_incomplete_forward = false }
    return function() end
  end

  local row = ctx.cursor[1] - 1
  local items = {}
  for _, note in ipairs(wanshi.notes()) do
    local detail = note.taxon and (note.taxon .. (note.date and ('  ' .. note.date) or '')) or note.date
    table.insert(items, {
      label = note.slug,
      -- Title in the menu, since a slug is a path and rarely readable on its
      -- own; the slug is what gets inserted.
      labelDetails = { description = note.title },
      detail = detail,
      kind = vim.lsp.protocol.CompletionItemKind.Reference,
      -- An explicit range: without it the leading `/` or a partially typed
      -- slug gets duplicated rather than replaced.
      textEdit = {
        range = {
          start = { line = row, character = start_col },
          ['end'] = { line = row, character = ctx.cursor[2] },
        },
        newText = note.slug,
      },
      documentation = {
        kind = 'markdown',
        value = table.concat({
          '# ' .. note.title,
          '',
          '`/' .. note.slug .. '`',
          note.taxon and ('\ntaxon: ' .. note.taxon) or '',
          note.date and ('\ndate: ' .. note.date) or '',
        }, '\n'),
      },
    })
  end

  callback { items = items, is_incomplete_backward = false, is_incomplete_forward = false }
  return function() end
end

return M
