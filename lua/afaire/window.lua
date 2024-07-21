local M = {}

function M.open(opts)
  -- Create a new temporary buffer.
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
  --vim.api.nvim_create_autocmd("BufWritePost", {
  --  buffer = buffer,
  --  once = true,
  --  callback = function()
  --    print("on write")
  --  end,
  --})



  return window, buffer
end

return M
