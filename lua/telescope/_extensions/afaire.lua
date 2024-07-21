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


local function search(opts)
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
    -- FIXME I would like to add colors to priorities. The following does not seem
    -- to work, and requires further investigation
    --hl_chars = {
    --  { ["D"] = "Keyword" }
    --}
  })
  local make_display = function(entry)
    return displayer {
      entry.value.priority,
      entry.value.due or "",
      entry.value.title,
    }
  end

  pickers.new(opts, {
    prompt_title = "afaire",
    sorter = conf.generic_sorter(opts), -- Nothing special. Good practice.
    previewer = conf.file_previewer(opts), -- Requires a `path` key below
    finder = finders.new_table({
      -- `results` is the list of every note (sorted by decreasing priority) in
      -- the current namespace. It is the job of the `cache` to efficiently retrieve
      -- this list.
      results = require("afaire.cache").load(),
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
  setup = function(ext_config, config)
    -- Setup currently does not much...
    -- Maybe add an action later...
    --action = ext_config.action or action
  end,
  exports = { afaire = search },
})
