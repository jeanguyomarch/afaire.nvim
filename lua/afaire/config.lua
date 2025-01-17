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


function M.parse_due_date(input, due_format)
  assert(#due_format == 3)

  -- Every valid due date is expected to contain three different fields:
  -- day, month and year (numbers). These may be separatered by any character
  -- (dash, slash, dot), hence the match with `.`.
  -- The results of the match are placed in an array.
  local matches = { string.match(input, "(%d+).(%d+).(%d+)") }
  -- If the match failed (because the input is not a date), return nil.
  -- This indicates we failed to parse the due date.
  if #matches ~= 3 then
    return nil
  end

  -- Do through the `due_format`, to assign the previous results to a day,
  -- month and year. We consider we are at the very beginning of the day.
  local result = { hour = 0, min = 0, sec = 0 }
  for index, name in ipairs(due_format) do
    result[name] = matches[index]
  end
  return result
end

function M.compute_urgency_in_hours(date)
  local now = os.time()
  local due = os.time(date)
  -- os.difftime() gives a result in seconds. Return a result in hours
  -- The result may be negative.
  return os.difftime(due, now) / (60 * 60)
end

function M.evaluate_note_urgency(date)
  -- Urgency is a result in hours, relative to the start of the due date.
  -- Between (-24, 0], this is the current day.
  local urgency = M.compute_urgency_in_hours(date)
  if urgency <= -24 then
    return "AfaireUrgencyExpired"
  elseif urgency <= 0 then
    return "AfaireUrgencyToday"
  elseif urgency <= 24 then
    return "AfaireUrgencyTwoDays"
  elseif urgency <= 48 then
    return "AfaireUrgencyThreeDays"
  elseif urgency <= 144 then
    return "AfaireUrgencyWeek"
  else
    return nil
  end
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

  local HlUrgency = {
    AfaireUrgencyExpired = { strikethrough = true },
    AfaireUrgencyToday = { fg = "#ff0000", standout = true },
    AfaireUrgencyTwoDays = { fg = "#ff0000" },
    AfaireUrgencyThreeDays = { fg = "#ff8b01" },
    AfaireUrgencyWeek = { fg = "#FFD301" },
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

  -- Populate the Urgency highlight groups if they were not previously set
  for hl_group, args in pairs(HlUrgency) do
    if vim.api.nvim_get_hl(0, { name = hl_group }) ~= nil then
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

local function check_due_format(due_format)
  -- `allowlist` contains as keys the names of the valid entries. These are
  -- initialized to `false`, which means there were not encountered. When
  -- we process `due_format`, we toggle this value to `true`, to indicate
  -- that a required parameter has been found.
  local allowlist = { year = false, month = false, day = false }

  -- Go through every item. We reject any input with a value that is not
  -- in the allowlist. Accepted values are marked as being present.
  for _, value in ipairs(due_format) do
    if allowlist[value] == nil then
      U.err("Invalid value `" .. value .. "' in `due_format'")
    end
    allowlist[value] = true
  end

  -- Finally, we ensure that every required parameter was encountered.
  for item, is_set in pairs(allowlist) do
    if not is_set then
      U.err("Missing required value in `due_format': `" .. item .. "'")
    end
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
  sanitize_optional_parameter(opts, "due_format", "table",
    { default_value = { "year", "month", "day" }})
  sanitize_optional_parameter(opts, "evaluate_note_urgency", "function",
    { default_value = M.evaluate_note_urgency })

  -- Setup the `directories` entry, which expects a table
  check_directories(opts)

  -- Ensure that the `due_format` entry is valid
  check_due_format(opts.due_format)

  -- Configure the default highlight groups
  make_default_highlight_groups(opts.default_highlight_group)

  return opts
end


return M
