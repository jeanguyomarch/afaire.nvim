--
-- afaire.nvim > init.lua
--
-- This is the main entry point of the afaire module. It returns a
-- "singleton" instance setup with the user configuration. Other modules may
-- query this global state via `require("afaire")`.
--

local U = require("afaire.util")

local M = {}

local function setup_telescope(opts)
  -- Proceed with the telescope integration.
  -- Implementation is in `telescope/_extensions/afaire.lua`
  if opts.with_telescope_extension then
    -- Start by loading `telescope'. Upon failure, the variable `telescope`
    -- will contain the details of the error. Upon success, it is the actual
    -- module.
    local status, telescope = pcall(require, "telescope")
    if not status then
      U.err("Failed to load plugin `telescope'. If you don't want support for"
        .. " telescope, you may want to set `with_telescope_extension = false'."
        .. " " .. telescope)
    end
    telescope.load_extension("afaire")
  end
end

local function setup_commands(opts)
  -- Create the user commands (e.g., type `:Afaire ...`) that really implement
  -- the plugin. The user commands are implemented in the module `afaire.command`.

  -- `:Afaire [...]`
  vim.api.nvim_create_user_command("Afaire", function(input)
    require("afaire.command").Afaire(opts, input)
  end, { nargs = "*", })

  -- `:AfaireDirectory <dir>`
  vim.api.nvim_create_user_command("AfaireDirectory", function(input)
    require("afaire.command").AfaireDirectory(opts, input)
  end, { nargs = 1, })
end


-- Changes the current directory. We search in the user-provided configuration
-- a directory named `directory_name`, and we return the associated configuration
-- entry.
--
-- The updated context is used by the `M:directory()` function.
function M:set_directory(directory_name)
  if self.options.directories[directory_name] == nil then
    U.err("Directory `" .. args .. "' was not configured. Check afaire.setup().")
  end
  self.current_directory = directory_name
end


-- Return the current directory.
--
-- The result is a table containing (at least) the following entries:
--   * notes: the path to the notes directory
--   * archives: the path to the archives directoryt
function M:directory()
  local directory_name = self.current_directory
  local dir = self.options.directories[directory_name]
  if dir == nil then
    U.err("Directory `" .. directory_name .. "' was not configured. Check afaire.setup().")
  end
  assert(dir.notes ~= nil)
  assert(dir.archives ~= nil)
  return dir
end

-- This is the main entry point of the plugin.
function M.setup(opts)
  if vim.fn.has('nvim-0.10') == 0 then
    U.err("Afaire requires neovim 0.10 or higher")
  end

  -- Valide and auto-complete the user-provided configuration
  M.options = require("afaire.config").finalize(opts)

  -- The init current directory (directory that contains the notes) is
  -- set to the default directory.
  M.current_directory = M.options.default_directory

  -- Configure the internals of the plugin
  setup_telescope(opts)
  setup_commands(opts)
end

return M
