--- Editing support for wanshi note forests.
---
--- wanshi (https://github.com/pvomelveny/wanshi) is a Typst-only Zettelkasten
--- generator. A forest is a directory holding `Wanshi.toml`, with sources under
--- `trees/` and a bundled library at `trees/_lib/wanshi.typ`.
---
--- Everything here is scoped to a detected forest, so ordinary Typst files are
--- untouched.
---
--- Provides:
---   * `root_for` — the Typst root a note compiles against, for tinymist
---   * `find_project` / `is_note` — forest detection
---   * `notes` — the forest's sections, read from the generated wanshi.json
---
--- Slug completion lives in `wanshi.complete`. Snippets are not a module: they
--- are in `lua/custom/LuaSnip/typst/wanshi.lua`, picked up by LuaSnip's
--- `from_lua` loader, which keys them by the directory's filetype.

local M = {}

--- Accepted source extensions, current first.
---
--- `.typ` is what wanshi writes now; `.typst` is kept working for forests
--- created before the switch. Order matters to `strip_ext`.
local extensions = { '.typ', '.typst' }

--- Drop a source extension, if there is one.
---
--- A plain suffix comparison rather than a pattern: the extensions are literals
--- and a pattern here only invites the escaping mistakes it is meant to avoid.
---@param name string
---@return string
local function strip_ext(name)
  for _, ext in ipairs(extensions) do
    if name:sub(-#ext) == ext then
      return name:sub(1, -#ext - 1)
    end
  end
  return name
end

--- A path in the same normalized form `root_for` produces, so that the prefix
--- comparisons below are meaningful.
---@param path string?
---@return string?
local function normalized(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then
    return nil
  end
  return vim.fs.normalize(path)
end

--- Directory containing the nearest `Wanshi.toml` at or above `path`.
---@param path string? file or directory; defaults to the current buffer
---@return string? project_root, string? config_file
function M.find_project(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then
    return nil, nil
  end
  local start = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  local found = vim.fs.find('Wanshi.toml', { path = start, upward = true, type = 'file' })[1]
  if not found then
    return nil, nil
  end
  return vim.fs.dirname(found), found
end

--- Read a `key = "value"` string out of a `[section]` of a TOML file.
---
--- Deliberately not a TOML parser. Only two flat keys are ever needed here and
--- both are plain strings; pulling in a parser to read them would be silly.
---
--- The section does have to be tracked, though: `output` is set under both
--- `[build]` and `[serve]`, so a section-blind scan returns whichever table
--- happens to be written first.
---@param file string
---@param section string the `[table]` the key lives under
---@param key string
---@return string?
local function toml_string(file, section, key)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return nil
  end
  -- The key is matched literally, so escape it here — and only here. Escaping
  -- at the call site too would double it: `%-` would become `%%-`, which is a
  -- quantified literal `%` and matches `typstroot` rather than `typst-root`.
  local pattern = '^%s*' .. (key:gsub('(%p)', '%%%1')) .. '%s*=%s*"([^"]*)"'
  local in_section = false
  for _, line in ipairs(lines) do
    local header = line:match '^%s*%[%s*([^%]]-)%s*%]'
    if header then
      in_section = header == section
    elseif in_section then
      local value = line:match(pattern)
      if value then
        return value
      end
    end
  end
  return nil
end

--- The Typst root a note in this forest compiles against.
---
--- This is the fix for the error every note otherwise shows on line 1. Notes
--- open with a *root-absolute* import:
---
---     #import "/_lib/wanshi.typ": *
---
--- which resolves against Typst's root, not the filesystem. wanshi compiles
--- with `--root <project>/trees`, so `/` means `trees/`. tinymist otherwise
--- takes the LSP workspace root — for an embedded forest that is the *host*
--- repository, so it searches `<repo>/_lib/wanshi.typ`, finds nothing, and
--- marks the first line of every note as an error.
---
--- The directory comes from `[build].typst-root` rather than being hardcoded,
--- since it is configurable and need not equal `[wanshi].trees`.
---@param path string?
---@return string? typst_root
function M.root_for(path)
  local project, config = M.find_project(path)
  if not project then
    return nil
  end
  local typst_root = toml_string(config, 'build', 'typst-root') or 'trees'
  -- Normalized because this is a configured relative path and may well be
  -- written `./trees`: `joinpath` would keep the `./`, and every prefix
  -- comparison against a buffer name below would then fail.
  return vim.fs.normalize(vim.fs.joinpath(project, typst_root))
end

--- Whether `path` is a note inside a forest's source tree.
---
--- Files under a `_`-prefixed directory are excluded: wanshi skips those during
--- section discovery, so `trees/_lib/wanshi.typ` is a helper, not a note.
---@param path string?
---@return boolean
function M.is_note(path)
  path = normalized(path)
  if not path or strip_ext(path) == path then
    return false
  end
  local root = M.root_for(path)
  if not root then
    return false
  end
  -- Compare against `root .. '/'`, not `root`: a bare prefix test also accepts
  -- a sibling whose name merely starts with the root's, so for root
  -- `<project>/trees` a file in `<project>/trees-old` would look like a note.
  if path:sub(1, #root + 1) ~= root .. '/' then
    return false
  end
  local rel = path:sub(#root + 2)
  if rel == '' then
    return false
  end
  for segment in vim.gsplit(rel, '/', { plain = true }) do
    if segment:sub(1, 1) == '_' or segment:sub(1, 1) == '.' then
      return false
    end
  end
  return true
end

--- The slug of a note file: its path under the Typst root, minus the extension.
---
--- This is the note's permanent identity — its URL, its link target, and its
--- key in every generated artifact.
---@param path string?
---@return string?
function M.slug_of(path)
  path = normalized(path)
  local root = path and M.root_for(path)
  if not root or path:sub(1, #root + 1) ~= root .. '/' then
    return nil
  end
  return strip_ext(path:sub(#root + 2))
end

--- The file backing a slug under an already-resolved root, if it exists.
---
--- Split out from `path_of` so a caller resolving many slugs at once can find
--- the root a single time. `path_of` re-derives it on every call — an upward
--- directory walk plus a `Wanshi.toml` read — which is nothing once and a few
--- hundred syscalls when decorating a picker.
---@param root string as returned by `root_for`
---@param slug string
---@return string?
function M.path_in(root, slug)
  for _, ext in ipairs(extensions) do
    local candidate = vim.fs.joinpath(root, slug .. ext)
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

--- The file to open for a slug, and the section that file actually is.
---
--- A *named subtree* — `#definition(slug: "…")` and friends — is a section
--- without a file of its own: it is written inside another note. So it appears
--- in `wanshi.json` and in the graph, `path_in` finds nothing for it, and a
--- picker entry pointing at one used to be a dead end.
---
--- `embedded_by` is the record that fixes this. It holds every section that
--- embeds this one, and a named subtree is an embed, so it names the note the
--- subtree was written in. `parent` is the fallback for the rare section with
--- no embedder, and is deliberately second: it holds a single slug that a
--- self-declared `parent` displaces, which is the very fragility `embedded_by`
--- was added to avoid.
---
--- Walks rather than taking one hop, since a subtree can be written inside a
--- subtree (`guide/monoid-strings` sits in `guide/monoid`, which sits in
--- `guide/subtrees`). `seen` guards a graph that points at itself.
---@param slug string
---@param root string as returned by `root_for`
---@param graph table as returned by `graph`
---@return string? path, string? host_slug host_slug is nil when the slug has its own file
function M.source_for(slug, root, graph)
  local own = M.path_in(root, slug)
  if own then
    return own, nil
  end

  local seen, current = { [slug] = true }, slug
  while true do
    local section = graph[current]
    if not section then
      return nil, nil
    end
    -- Sorted so a section with several hosts resolves to the same one every
    -- time; `embedded_by` is a set on wanshi's side and arrives unordered.
    local hosts = vim.deepcopy(section.embedded_by or {})
    table.sort(hosts)
    local next_slug = hosts[1] or section.parent
    if not next_slug or seen[next_slug] then
      return nil, nil
    end
    seen[next_slug] = true
    local path = M.path_in(root, next_slug)
    if path then
      return path, next_slug
    end
    current = next_slug
  end
end

--- The file backing a slug, if it exists.
---@param slug string
---@param path string? any file in the forest, to locate it
---@return string?
function M.path_of(slug, path)
  local root = M.root_for(path)
  return root and M.path_in(root, slug) or nil
end

--- Resolve a `#local` / `#embed` target to a slug.
---
--- The leading `/` is the whole distinction, and getting it wrong is the most
--- common way to write a dangling link. A target starting with `/` is
--- root-absolute in the slug space. Anything else resolves against the
--- *containing directory* of the linking note — so `#local("boolean/basics")`
--- written inside `boolean/index` means `boolean/boolean/basics`, not
--- `boolean/basics`.
---@param target string the string inside #local(...) / #embed(...)
---@param from_slug string? slug of the note containing the link
---@return string slug
function M.resolve_target(target, from_slug)
  target = strip_ext(target)
  if target:sub(1, 1) == '/' then
    return (target:sub(2):gsub('^%./', ''))
  end
  target = target:gsub('^%./', '')
  local dir = from_slug and vim.fs.dirname(from_slug) or '.'
  if dir == '.' or dir == '' then
    return target
  end
  return dir .. '/' .. target
end

--- Where the build writes its artifacts, resolved against the project root.
---
--- Mirrors wanshi's own resolution: every configured path is relative to the
--- directory holding `Wanshi.toml`. `[build].output` is read rather than
--- `[serve].output` because the former is what `wanshi build` writes and is
--- present in every config — hence the explicit section, since both tables
--- define `output` and they routinely differ.
---@param project string
---@param config string
---@return string
local function output_dir(project, config)
  local out = toml_string(config, 'build', 'output') or './publish'
  return vim.fs.normalize(vim.fs.joinpath(project, out))
end

--- Read and shape a generated JSON artifact, memoized on the file's identity.
---
--- The artifacts change only on a build, but they are read on a hot path:
--- `notes()` runs for every completion retrigger and once per picker, so
--- re-reading and re-decoding a whole forest index there is pure waste. Size
--- and nanosecond mtime together are a sharp enough stamp to catch the rapid
--- rebuilds of `wanshi serve --watch`.
---
--- `build` runs only on a miss, so the shaped result is cached too, not just
--- the decode.
---@generic T
---@param cache table<string, { stamp: string, value: T }>
---@param file string
---@param build fun(decoded: table): T?
---@return T?
local function cached_json(cache, file, build)
  local stat = vim.uv.fs_stat(file)
  if not stat or stat.type ~= 'file' then
    return nil
  end
  local stamp = ('%d.%d.%d'):format(stat.mtime.sec, stat.mtime.nsec, stat.size)
  local hit = cache[file]
  if hit and hit.stamp == stamp then
    return hit.value
  end
  local read_ok, lines = pcall(vim.fn.readfile, file)
  if not read_ok then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok or type(decoded) ~= 'table' then
    return nil
  end
  local value = build(decoded)
  cache[file] = { stamp = stamp, value = value }
  return value
end

local graph_cache = {}
local notes_cache = {}

--- The forest's link graph, from the generated `wanshi.graph.json`.
---
--- Shape is `{ sections = { [slug] = { parent, references, backlinks } } }`.
--- Like `notes()`, this is build output and only as current as the last build.
---@param path string?
---@return table<string, { parent: string?, references: string[], backlinks: string[] }>
function M.graph(path)
  local project, config = M.find_project(path)
  if not project then
    return {}
  end
  local file = vim.fs.joinpath(output_dir(project, config), 'wanshi.graph.json')
  return cached_json(graph_cache, file, function(decoded)
    return type(decoded.sections) == 'table' and decoded.sections or {}
  end) or {}
end

--- The forest's sections, read from the generated `wanshi.json`.
---
--- This is build output, so it is only as current as the last `wanshi build`
--- (or a `wanshi serve --indexes`). That is a deliberate trade: it means slug
--- completion costs no parsing here and always agrees with what the site
--- actually published.
---
--- Every value in the index is a tagged union — `{"Plain": "..."}` for plain
--- text, `{"Lazy": ...}` for rich Typst content — so only the plain form is
--- usable as a string.
---@param path string? any file in the forest; defaults to the current buffer
---@return { slug: string, title: string, taxon: string?, date: string? }[]
function M.notes(path)
  local project, config = M.find_project(path)
  if not project then
    return {}
  end
  local index = vim.fs.joinpath(output_dir(project, config), 'wanshi.json')
  return cached_json(notes_cache, index, function(decoded)
    local function plain(value)
      return type(value) == 'table' and type(value.Plain) == 'string' and value.Plain or nil
    end

    local out = {}
    for slug, entry in pairs(decoded) do
      if type(entry) == 'table' then
        table.insert(out, {
          slug = slug,
          -- `page-title` is wanshi's markup-stripped form, so it stays a string
          -- even when a note titles itself with rich Typst content.
          title = plain(entry['page-title']) or plain(entry.title) or slug,
          taxon = plain(entry['data-taxon']),
          date = plain(entry.date),
        })
      end
    end
    table.sort(out, function(a, b)
      return a.slug < b.slug
    end)
    return out
  end) or {}
end

return M
