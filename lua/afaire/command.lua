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
local window = require("afaire.window")
local M = {}

function M.action_list()
end

function M.action_new(opts, args)
  local now = os.time()
  local timestamp = os.date("%Y%m%d%H%M%S", now)
  local file =  vim.fs.joinpath(A.directory, timestamp .. opts.default_extension)

  -- Eventually, we will write `file` to the filesystem. Make sure its directory
  -- exists. If not, attempt to create it (with parents). Upon failure, we must
  -- stop, as we will not be able to save the note.
  if vim.fn.filewritable(directory) ~= 2 then
    if not vim.fn.mkdir(directory, "p") then
      U.err("Failed to create directory `" .. directory .. "'")
    end
  end

  local win, buffer = window.open(opts)
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
end

function M.parse_input(args)
  local parse_result = {
    action = M.action_list,
    args = nil,
  }

  -- Start by trimming whitespaces: these are not significant and may cause
  -- problems with the parsing.
  args = vim.trim(args)

  -- We have no argument to the command. Just return the default value of
  -- `parse_result`, which will trigger the default behavior of the command.
  if #args == 0 then
    return parse_result
  end

  -- Try to determine the "command". This is the very first "word" in the
  -- command. If there is no space, than the command is the whole command
  -- (the command consists only in the bcommand).
  -- Note that we match against '%s+', in case there are several whitespaces
  -- that follow the command
  local end_of_command, start_of_args = string.find(args, "%s+")
  local command = args
  if end_of_command ~= nil then
    command = string.sub(args, 1, end_of_command - 1)
    args = string.sub(args, start_of_args + 1, -1)
  end

  -- Dispatch the different actions, depending on the contents of `command`.
  if command == "new" then
    parse_result.action = M.action_new
    parse_result.args = args
  elseif command == "list" then
    -- The `list` command accepts no argument. After error checking, we return
    -- `parse_result` unmodified, as the default action is `list`.
    if #args ~= 0 then
      U.err("`Afaire list` accepts no additional arguments")
    end
  else
    U.err("Unknown argument to the Afaire command: `" .. command .. "`")
  end
  return parse_result
end

function M.Afaire(opts, func_input)
  --local parse_result = M.parse_input(func_input.args)

  local args = #func_input == 0 and "" or vim.trim(func_input)
  M.action_new(opts, args)
end

return M
