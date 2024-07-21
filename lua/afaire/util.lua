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

-- The two functions below (sanitize_required_parameter and
-- sanitize_optional_parameter) are really helpful when parsing the user
-- configuration. They ensure the plugin starts with "sanitized" parameters
--
-- Both functions accept `extra_args`, which is an optional table (i.e. may be
-- nil) with the following fields:
--   * expand: boolean. If true, `expandcmd()` is run on the input parameter.
--   * default_value: Contains the default value of the parameter being
--     sanitized. This is obviously not needed for sanitize_required_parameter(),
--     as an error is raised if the parameter is missing.
--
-- These functions raise an error if something unusual happens, as we should
-- not move forward with a deeply invalid user configuration.
--
function M.sanitize_required_parameter(container, key, expected_type, extra_args)
  extra_args = extra_args == nil and {} or extra_args
  local value = container[key]
  if value == nil then
    M.err("You must provide a non-nil parameter named `" .. key .. "` when calling setup()")
  end
  if type(value) ~= expected_type then
    M.err("Parameter `" .. key .. "` must be of type " .. expected_type)
  end

  if extra_args.expand == true then
    container[key] = vim.fn.expandcmd(value)
  end
end

function M.sanitize_optional_parameter(container, key, expected_type, extra_args)
  extra_args = extra_args == nil and {} or extra_args
  local value = container[key]
  if value == nil then
    container[key] = extra_args.default_value
  elseif type(value) ~= expected_type then
    M.err("Parameter `" .. key .. "` must be of type " .. expected_type)
  end

  if extra_args.expand == true then
    container[key] = vim.fn.expand(value)
  end
end

return M
