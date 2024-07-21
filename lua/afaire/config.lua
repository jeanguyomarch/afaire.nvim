--
-- afaire.nvim > config.lua
--
-- Provides the "meat" of the configuration of the plugin.
--

local U = require("afaire.util")
local M = {}


function M.setup(opts)

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

  -- Create the user commands (e.g., type `:Afaire ...`) that really implement
  -- the plugin. The user commands are implemented in the module `afaire.command`.
  vim.api.nvim_create_user_command("Afaire", function(input)
    require("afaire.command").Afaire(opts, input)
  end, { nargs = "*", })
end

return M
