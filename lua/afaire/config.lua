--
-- afaire.nvim > config.lua
--
-- This module validates
--

local U = require("afaire.util")

local M = {}

-- The two functions below (sanitize_required_parameter and
-- sanitize_optional_parameter) are really helpful when parsing the user
-- configuration. They ensure the plugin starts with "sanitized" parameters
--
-- Both functions accept `extra_args`, which is an optional table (i.e. may be
-- nil) with the following fields:
--   * default_value: Contains the default value of the parameter being
--     sanitized. This is obviously not needed for sanitize_required_parameter(),
--     as an error is raised if the parameter is missing.
--
-- These functions raise an error if something unusual happens, as we should
-- not move forward with a deeply invalid user configuration.
--
local function sanitize_required_parameter(container, key, expected_type, extra_args)
  extra_args = extra_args == nil and {} or extra_args
  local value = container[key]
  if value == nil then
    M.err("You must provide a non-nil parameter named `" .. key .. "` when calling setup()")
  end
  if type(value) ~= expected_type then
    M.err("Parameter `" .. key .. "` must be of type " .. expected_type)
  end
end

local function sanitize_optional_parameter(container, key, expected_type, extra_args)
  extra_args = extra_args == nil and {} or extra_args
  local value = container[key]
  if value == nil then
    container[key] = extra_args.default_value
  elseif type(value) ~= expected_type then
    M.err("Parameter `" .. key .. "` must be of type " .. expected_type)
  end
end


-- Unless overriden by the user, this is the function to be called when a new
-- note is created. It sets the initial contents of a note.
--
-- This generates the front matter of a markdown file
function M.default_template(context)
  return "---\n"
    .. "title = \"" .. context.title .. "\"\n"
    .. "created = \"" .. os.date("%c", context.timestamp) .. "\"\n"
    .. "priority = \"" .. context.options.default_priority .. "\"\n"
    .. "due = \"\"\n"
    .. "---\n"
    .. "\n"
end


local function make_default_highlight_groups(defaut_hl_group)
  local HlPriority = {
    A = { fg = "#ff0000", standout = true, },
    B = { fg = "#FF8B01", },
    C = { fg = "#FFD301", },
    D = { fg = "#0088DD", },
    E = { fg = "#2A52BD", },
    K = { fg = "#ffffff", },
    X = { fg = "#d2b8e0", },
    Y = { fg = "#d2b8e0", },
    Z = { fg = "#d2b8e0", },
  }

  -- We will create one highlight group per priority. Unless one already exist
  -- (we suppose it was created earlier by the user). We use our local table
  -- `HlPriority` to retrieve our default configuration values.
  for priority in string.gmatch("ABCDEFGHIJKLMNOPQRSTUVWXYZ", ".") do
    local hl_group = U.priority_hl_group(priority)
    if vim.api.nvim_get_hl(0, { name = hl_group }) ~= nil then
      local args = HlPriority[priority] or { link = defaut_hl_group }
      vim.api.nvim_set_hl(0, hl_group, args)
    end
  end
end

-- Check that each `CONF.directories` entry is correctly written.
local function check_directory(name, dir)
  -- Expect a table to configure a directory
  if dir == nil or type(dir) ~= "table" then
    U.err("A directory configuration is required for directory `" .. name .. "'")
  end

  -- The field `.notes` is absolutely mandatory. Expand it.
  if dir.notes == nil then
    U.err("Missing required entry `notes' in directory `" .. name "'")
  end
  dir.notes = vim.fn.expandcmd(dir.notes)

  -- Deduce `.archives` from `.notes`. If provided by the user, expand it.
  if dir.archives == nil then
    dir.archives = vim.fs.joinpath(dir.notes, "archives")
  else
    dir.archives = vim.fn.expandcmd(dir.archives)
  end
end


-- Validate the `directories` entry of the global configuration, and affiliated
-- entries, such as `default_directory`.
local function check_directories(opts)
  -- The `default_directory` must exist (a default value has been created
  -- earlier). We make sure there is a matching `directory` entry.
  if opts.directories[opts.default_directory] == nil then
    U.err("Missing directory configuration for default directory `" .. opts.default_directory .. "'")
  end
  -- Validate every directory entry
  for name, conf in pairs(opts.directories) do
    check_directory(name, conf)
  end
end

function M.finalize(opts)
  opts = opts == nil and {} or opts

  -- Setup the top-level configuration entries
  sanitize_required_parameter(opts, "directories", "table", {})
  sanitize_required_parameter(opts, "default_directory", "string",
    { default_value = "default" })
  sanitize_optional_parameter(opts, "template", "function",
    { default_value = M.default_template })
  sanitize_optional_parameter(opts, "default_priority", "string",
    { default_value = "D" })
  sanitize_optional_parameter(opts, "default_extension", "string",
    { default_value = ".md" })
  sanitize_optional_parameter(opts, "default_filetype", "string",
    { default_value = "markdown" })
  sanitize_optional_parameter(opts, "with_telescope_extension", "boolean",
    { default_value = true })
  sanitize_optional_parameter(opts, "load_note_metadata", "function",
    { default_value = require("afaire.fs").load_note_metadata })
  sanitize_optional_parameter(opts, "default_highlight_group", "string",
    { default_value = "Identifier" })

  -- Setup the `directories` entry, which expects a table
  check_directories(opts)

  -- Configure the default highlight groups
  make_default_highlight_groups(opts.default_highlight_group)

  return opts
end


return M
