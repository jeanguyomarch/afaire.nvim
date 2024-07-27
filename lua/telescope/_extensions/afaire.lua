--
-- This is a telescope extension for the neovim plugin `afaire.nvim`.
-- It diplays every "note" within the current namespace in the fancy telescope
-- interface, while allowing for a quick search and preview
--

-- These are "standard" includes for telescope.
-- Cf https://github.com/nvim-telescope/telescope.nvim/blob/0.1.x/developers.md
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")


local A = require("afaire")
local U = require("afaire.util")
local fs = require("afaire.fs")



local function archive(entry_title, entry_path, bufnr)
  local confirmation = U.ask_to_confirm("Do you really want to archive entry `" .. entry_title .. "'? [Y/n] ", "y")
  if not confirmation then
    return
  end

  local picker = action_state.get_current_picker(bufnr)
  picker:delete_selection(function()
    local directory = A:directory()
    fs.archive_note(entry_path, directory.archives)
  end)
end

local function search(opts)
  local afaire = require("afaire")
  local config = require("afaire.config")

  -- Let each note be displayed as a row in a table, such as:
  --
  --    A  2024-07-21  This is my note
  --
  -- In the example above, there are actually three fields. From left to right,
  -- these are:
  --   * the priority, as a single uppercase letter
  --   * the due date, if any. This is blank if there is no firm deadline
  --   * the title of the note
  --
  -- `displayer` is created separately, as advised by the devs, for better
  -- run time performances. It really is the function `make_display` that
  -- creates a row consisting of the three fields aforementioned
  local displayer = entry_display.create({
    separator = "  ", -- Each field is separated by two spaces
    items = {
      { width = 1 }, -- priority
      { width = 10 }, -- due date
      { remaining = true }, -- title
    },
  })
  local make_display = function(entry)
    local priority_hl_group = U.priority_hl_group(entry.value.priority)
    local due_date = config.parse_due_date(entry.value.due or "", afaire.options.due_format)
    local due_hl_group = nil
    if due_date ~= nil then
      due_hl_group = afaire.options.evaluate_note_urgency(due_date)
    end
    return displayer({
      { entry.value.priority, priority_hl_group },
      { entry.value.due or "", due_hl_group },
      entry.value.title,
    })
  end

  local results = fs.load_notes()
  pickers.new(opts, {
    prompt_title = "afaire",
    sorter = conf.generic_sorter(opts), -- Nothing special. Good practice.
    previewer = conf.file_previewer(opts), -- Requires a `path` key below
    -- TODO: make mapping configurable
    attach_mappings = function(x, map)
      map({"i", "n"}, "<C-k>", function(bufnr)
        local current_entry = action_state.get_selected_entry()
        archive(current_entry.value.title, current_entry.path, bufnr)
      end)
      return true -- true: keep default mappings
    end,
    finder = finders.new_table({
      -- `results` is the list of every note (sorted by decreasing priority) in
      -- the current namespace.
      results = results,
      entry_maker = function(entry)
        return {
          -- path: required by the previewer (what file should be loaded?)
          path = entry.path,
          -- ordinal: ordering criterion
          ordinal = entry.title,
          -- value: "good practice"
          value = entry,
          display = make_display,
        }
      end,
    }),
  }):find()
end


return require("telescope").register_extension({
  setup = function(ext_config, user_config)
    -- Setup currently does not much...
    -- Maybe add an action later...
    --action = ext_config.action or action
  end,
  exports = { afaire = search },
})
