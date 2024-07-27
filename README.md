# afaire.nvim

Afaire is a Neovim plugin that I intended for my personal management of to-do
lists. The name comes from the french "à faire", which means: "to do".

---

The `README.md` is just a short introduction of the plugin. Please read
[doc/afaire.txt](doc/afaire.txt) (or run `:help afaire` in Neovim after
installing the plugin) to consult a more detailed documentation.

---


## Getting started

### Requirements

`afaire.nvim` is specifically written for Neovim (tested with Neovim 0.10.0). It
is strongly suggested to install [telescope.nvim][a] to use this plugin to its best.

To install `afaire.nvim`, just use your favorite package manager. For example,
with [vim-plug][b]:

```vim
Plug 'jeanguyomarch/afaire.nvim'
```

### Configuration

You must write your configuration using Lua. Take a look at the [lua guide][c]
if you are not sure where to start. This is mandatory as `afaire.nvim` does
not expose any vimscript API.

You **MUST** explicitly call `require("afaire").setup()`. Some configuration
parameters are mandatory: `afaire.nvim` cannot work without them. The main job
of the plugin consists in reading and writing **notes**, that reside on the
filesystem. You must tell the plugin the directory where these files will be
written. Two parameters are required:

1. `directories`: a table where keys are a *directory name* and their associates
   values configure this directory.
2. `default_directory`: a string value that must correspond to one entry in
   the `directories table.`

The following code snippet shows the minimal configuration that should work
out-of-the box. All files written by `afaire.nvim` will end up in the
directory `~/notes/work` by default.

```lua
require("afaire").setup({
  directories = {
    work = {
        notes = "~/notes/work"
    }
  },
  default_directory = "work",
})
```

The entry `directories.NAME.notes` is required. It indicates the path where
notes will be written by `afaire.nvim`. The plugin automatically runs
[expandcmd()][d] on this parameter, which means you can use special characters
such as `~`.


Unless you have set `with_telescope_extension = false`, the plugin automatically
registers the `afaire` extension to [telescope][a]. You may run the vim command
`:Telescope afaire` to browse the notes. You are advised to create a mapping
for an easy access, as in the example below:


```lua
-- In "normal" mode, <leader> followed by the letters "f" and "a" triggers
-- the call to the Telescope extension that displays your notes.
vim.keymap.set('n', '<leader>fa', '<cmd>Telescope afaire<cr>')
```

For additional configuration parameters, please refer to [the documentation](doc/afaire.txt):

```vim
:help afaire.setup
```

### Creating a Note

Type in the command:

```vimscript
:Afaire [optional arguments...]
```

If you provided arguments to `:Afaire`, these are processed as a single string
and will be considered as the `title` of your note. In any case, a window opens
for you to finalize your note. You just have to save the file to create the note.
A new note looks like the following markdown file:

```markdown
---
title = "The title of the note"
created = "(automatically completed)"
priority = "A"
due = "2024/12/30"
---

Write your contents here :)
```

* **priority** must be a single uppercase letter of the latin alphabet (A
  being the highest priority and Z the lowest).
* **due** (may be empty) is used to determine the *urgency* of the note.
  To be properly displayed, this must be a date with a year, month and day. By
  default, the expected format is `YYYY/MM/DD`. See [the
  documentation](doc/afaire.txt) if you need to configure this format.



### Switching directories

You may want to use different directories if you have different "work contexts"
that must not mix together. For instance, if you want to separate your "regular
paid work" from your "home hobbies". Use the `:AfaireDirectory <directory>` to
switch from a directory to another. The name of the directory must obviously
exist in the configuration provided to `afaire.setup`.



### Browsing through your notes

This can only be done with the built-in Telescope plugin. Run the vim command
`:Telescope afaire`. Note that this displays the note in your current
directory. See the section above to switch directories.

Press `Return` once you have previewed an entry to open it in a dedicated
buffer.


### Archiving a note

This can only be done with the built-in Telescope plugin. Press `Ctrl-K`
on a note to archive it. You will be prompted for confirmation. Archives notes
are stored in the `archives/` directory within your current directory, unless
you have explicitly overriden this value.




[a]: https://github.com/nvim-telescope/telescope.nvim
[b]: https://github.com/junegunn/vim-plug
[c]: https://neovim.io/doc/user/lua-guide.html
[d]: https://neovim.io/doc/user/builtin.html#expandcmd()
