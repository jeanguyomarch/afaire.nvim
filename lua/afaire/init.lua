--
-- afaire.nvim > init.lua
--
-- This is the main entry point of the afaire module. It returns a
-- "singleton" instance setup with the user configuration. Other modules may
-- query this global state via `require("afaire")`.
--

local U = require("afaire.util")

local M = {
  -- This is the user-provided configuration. It should be immutable at the end
  -- of the `setup()` function, unless the user specifically overrides its
  -- configuration dynamically
  options = nil,
  -- This is a key state variable, as it indicates, at any time, the full path
  -- where afaire needs to look for and create notes.
  directory = nil,
}

-- Unless overriden by the user, this is the function to be called when a new
-- note is created. It sets the initial contents of a note.
--
-- This generates the front matter of a markdown file
local function default_template(context)
  return "---\n"
    .. "title = \"" .. context.title .. "\"\n"
    .. "created = \"" .. os.date("%c", context.timestamp) .. "\"\n"
    .. "priority = \"" .. context.options.default_priority .. "\"\n"
    .. "due = \"\"\n"
    .. "---\n"
    .. "\n"
  end

-- This is the main entry point of the plugin. It parses the user configuration,
-- and defer the configuration work to the `afaire.config` module.
function M.setup(opts)
  opts = opts == nil and {} or opts

  -- These are all the configuration parameters known to the plugin.
  -- Update doc/afaire.txt when you change this, please :)
  U.sanitize_required_parameter(opts, "notes_directory", "string",
    { expand = true })
  U.sanitize_optional_parameter(opts, "default_namespace", "string",
    { expand = false, default_value = "default" })
  U.sanitize_optional_parameter(opts, "template", "function",
    { expand = false, default_value = default_template })
  U.sanitize_optional_parameter(opts, "default_priority", "string",
    { expand = false, default_value = "D" })
  U.sanitize_optional_parameter(opts, "default_extension", "string",
    { expand = false, default_value = ".md" })
  U.sanitize_optional_parameter(opts, "default_filetype", "string",
    { expand = false, default_value = "markdown" })
  U.sanitize_optional_parameter(opts, "with_telescope_extension", "boolean",
    { expand = false, default_value = true })
  U.sanitize_optional_parameter(opts, "load_metadata", "function",
    { expand = false, default_value = require("afaire.cache").load_metadata })

  -- Store the options globally
  M.options = opts
  -- Compose the final directory from the configuration. Note that this may be
  -- overriden later, but for convience, this is placed in a dedicated global
  -- state
  M.directory = vim.fs.joinpath(opts.notes_directory, opts.default_namespace)

  -- Continue with the configuration. This is implemented in a dedicated module.
  require("afaire.config").setup(opts)
end

return M
