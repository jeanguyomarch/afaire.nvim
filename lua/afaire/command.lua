--
-- afaire.nvim > command.lua
--
-- This module implements user-defined vim commands that are given to the user
-- to interact with the plugin
--
-- The following commands are implemented:
--
-- * Afaire (...): create a new note
--

local A = require("afaire")
local U = require("afaire.util")
local M = {}

function M.action_new(opts, args)
  local now = os.time()
  local timestamp = os.date("%Y%m%d%H%M%S", now)
  local directory = A:directory()
  local file =  vim.fs.joinpath(directory.notes, timestamp .. opts.default_extension)

  -- Eventually, we will write `file` to the filesystem. Make sure its directory
  -- exists. If not, attempt to create it (with parents). Upon failure, we must
  -- stop, as we will not be able to save the note.
  require("afaire.fs").ensure_dir_exists(directory.notes)

  local buffer = vim.api.nvim_create_buf(false, false)
  -- Pop a window containing the buffer we previously created. This will be
  -- the new current active window
  local window_args = {
    split = "above",
    --relative = "editor",
    --row = 0, col = 0,
    --width = 80,
    --height = 20,
    --border = "rounded",
  }

  local window = vim.api.nvim_open_win(buffer, true, window_args)
  vim.api.nvim_buf_set_option(buffer, "filetype", opts.default_filetype)
  vim.api.nvim_buf_set_name(buffer, file)

  -- Compute the template.
  local template = opts.template({
    options = opts,
    timestamp = now,
    title = args,
    file = file,
  })

  -- The buffer must be fed with an array of lines. Convert the big string
  -- into an array of lines.
  local lines = vim.split(template, '\n')
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

  return window, buffer
end


function M.Afaire(opts, func_input)
  local args = func_input.args
  args = #args == 0 and "" or vim.trim(args)
  M.action_new(opts, args)
end

function M.AfaireBang(opts, func_input)
  local args = func_input.args
  if #args == 0 then
    U.err("Arguments (the title of the new note) are expected")
  end
  local window, buffer = M.action_new(opts, vim.trim(args))
  -- TODO
end


function M.AfaireDirectory(opts, func_input)
  local args = func_input.args

  A:set_directory(args)
end

return M
