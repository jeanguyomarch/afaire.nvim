--
-- afaire.nvim > util.lua
--
-- This module provides convinient helpers to other modules.
-- For convenience, this module will be referred to as `U'.
--   E.g. local U = require("afaire.util")
--

local M = {}

-- Raise a `nice` error. This ends up "aborting" the current "action".
function M.err(...)
  vim.notify_once(..., vim.log.levels.ERROR, { title = "afaire" })
  error(...)
end

-- Notify something unexpected, yet not fatal happened.
function M.warn(...)
  vim.notify(..., vim.log.levels.WARNING, { title = "afaire" })
end

-- Return the name of the highlight group for a given priority
function M.priority_hl_group(priority)
  return "AfairePriority" .. priority
end

-- This comes directly from:
--   https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/actions/init.lua
--
function M.ask_to_confirm(prompt, default_value, yes_values)
  yes_values = yes_values or { "y", "yes" }
  default_value = default_value or ""
  local confirmation = vim.fn.input(prompt, default_value)
  confirmation = string.lower(confirmation)
  if string.len(confirmation) == 0 then
    return false
  end
  for _, v in pairs(yes_values) do
    if v == confirmation then
      return true
    end
  end
  return false
end

return M
