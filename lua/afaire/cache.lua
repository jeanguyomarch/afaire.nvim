local A = require("afaire")
local U = require("afaire.util")

local M = {
  cache_data = nil
}

function M.invalidate()
  M.cache_data = nil
end

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

function M.load_metadata(file)
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
  return A.options.load_metadata(file)
end

function M.build()
  local cache_data = {}
  -- Search for every file in the current "afaire directory" that bear the
  -- extension configured with the plugin.
  for basename, file_type in vim.fs.dir(A.directory) do
    if file_type == "file" and vim.endswith(basename, A.options.default_extension) then
      -- Compose the full path to the file, and add it to the cache
      local file = vim.fs.joinpath(A.directory, basename)
      local file_data = process_file(file)
      if file_data ~= nil then
        table.insert(cache_data, file_data)
      end
    end
  end

  table.sort(cache_data, function(a, b)
    -- Priorities are string, so using `<` is quite fragile. However,
    -- these are assumed to be only a single uppercase letter, so this
    -- should be fine (:
    return a.priority > b.priority
  end)
  return cache_data
end

function M.load()
  -- XXX Always rebuild the cache.
  M.cache_data = M.build()
  return M.cache_data
end

return M
