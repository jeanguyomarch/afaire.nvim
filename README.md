# afaire.nvim

Afaire is a Neovim plugin that I intended for my personal management of to-do
lists. The name comes from the french "à faire", which means: "to do".

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
written. This parameter is `notes_directory`; it is a string that gets
processed with a call to [expandcmd()][d] (which means you can use special
characters such as `~`).

The following code snippet shows the minimal configuration that should work
out-of-the box. All files written by `afaire.nvim` will end up in the
directory `~/notes`.

```lua
require("afaire").setup({
  notes_directory = "~/notes",
})
```

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


[a]: https://github.com/nvim-telescope/telescope.nvim
[b]: https://github.com/junegunn/vim-plug
[c]: https://neovim.io/doc/user/lua-guide.html
[d]: https://neovim.io/doc/user/builtin.html#expandcmd()
