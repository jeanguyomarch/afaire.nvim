local A = require("afaire")
local U = require("afaire.util")

local M = {
}

local function get_frontmatter(data)
  local delimiter = "---\n"

  -- Find the first delimiter. It must start the file.
  local first_fm, end_first_fm = data:find(delimiter)
  if first_fm == nil or first_fm ~= 1 then
    U.warn("File `" .. file .. "' must start with `---`. Skipping...")
    return nil
  end

  -- Find the second delimiter.
  local second_fm, end_second_fm = data:find(delimiter, end_first_fm + 1)
  if second_fm == nil then
    U.warn("File `" .. file .. "' has an ill-formed markdown front matter. Skipping...")
    return nil
  end

  -- The frontmatter is the text body contained within the two delimiters found
  -- earlier
  return data:sub(end_first_fm + 1, second_fm - 1)
end

function M.load_note_metadata(file)
  -- TODO: additional error handling. If contents cannot be retrieved,
  -- skip the file.
  local file_handle = assert(io.open(file, "r"))
  local contents = assert(file_handle:read("*all"))
  file_handle:close()

  local frontmatter = get_frontmatter(contents)
  if frontmatter == nil then
    return nil
  end

  -- Neovim is compatible with Lua 5.1. As such, we must use setfenv()
  -- to "safely" load lua code here. Safe, in the sense that this will not
  -- pollute our global variables. This is still "code injection".
  local result = setmetatable({}, {__index = _G})
  if not pcall(setfenv(assert(loadstring(frontmatter)), result)) then
    U.warn("In file `" .. file .. "': failed to evaluate contents of the frontmatter")
    return nil
  end
  result.path = file
  return setmetatable(result, nil)
end

local function process_file(file)
  -- Load the meta data from the file. Note that the user may provide
  -- their own loader, if they really want to support their own file types.
  return A.options.load_note_metadata(file)
end

function M.load_notes()
  local directory = A:directory()
  local notes = {}
  -- Search for every file in the current "afaire directory" that bear the
  -- extension configured with the plugin.
  for basename, file_type in vim.fs.dir(directory.notes) do
    if file_type == "file" and vim.endswith(basename, A.options.default_extension) then
      -- Compose the full path to the file, and add it to the list of notes
      local file = vim.fs.joinpath(directory.notes, basename)
      local file_data = process_file(file)
      if file_data ~= nil then
        table.insert(notes, file_data)
      end
    end
  end

  table.sort(notes, function(a, b)
    -- Priorities are string, so using `<` is quite fragile. However,
    -- these are assumed to be only a single uppercase letter, so this
    -- should be fine (:
    return a.priority > b.priority
  end)
  return notes
end

function M.ensure_dir_exists(path)
  if vim.fn.filewritable(path) ~= 2 then
    if not vim.fn.mkdir(path, "p") then
      U.err("Failed to create directory `" .. path .. "'")
    end
  end
end

function M.archive_note(note_file, archives_dir)
  -- We will move the note at `note_file` in the `archives` directory.
  -- Make sure this directory exists (creates if needed)
  M.ensure_dir_exists(archives_dir)
  -- Move `note_file` in the archive directory
  local new_file = vim.fs.joinpath(archives_dir, vim.fs.basename(note_file))
  vim.uv.fs_rename(note_file, new_file)
end

return M
