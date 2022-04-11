# nvim-revJ.lua

:warning: *I've decided to completely re-write this plugin and use treesitter instead of textobjects etc and completely move away from the current implementation. Feel free to checkout `trevJ` instead:*

https://github.com/AckslD/nvim-trevJ.lua

Nvim-plugin for doing the opposite of join-line (J) of arguments written in lua.
Requires some textobject that selects a argument such as [`vim-textobj-parameter`](https://github.com/sgur/vim-textobj-parameter) or [`targets.vim`](https://github.com/wellle/targets.vim).
Note: `vim-textobj-parameter` in turn requires `vim-textobj-user`.
Note: `targets.vim` should in principle work I think but I haven't managed to get it to select arguments as I would want.
Note: whitespace needs to be included in the textobject so [`nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) won't work yet, because of [this](https://github.com/nvim-treesitter/nvim-treesitter-textobjects/pull/23#issuecomment-805853884).

![](revj.gif)

# Installation

Use your favourite plugin manager, for example using [`packer.nvim`](https://github.com/wbthomason/packer.nvim)
```lua
use {
    'AckslD/nvim-revJ.lua',
    requires = {'kana/vim-textobj-user', 'sgur/vim-textobj-parameter'},
    -- or
    -- requires = {'wellle/targets.vim'},
    -- or ...
}
```
or [`vim-plug`](https://github.com/junegunn/vim-plug):
```vim
Plug 'kana/vim-textobj-user'
Plug 'sgur/vim-textobj-parameter'
" or
" Plug 'wellle/targets.vim'
" or ...
Plug 'AckslD/nvim-revJ.lua'
```

# Usage
The plugin needs to be enabled by calling it's setup function.
```lua
require("revj").setup{}
```
By default no keybindings are enabled, see below for configuration.

# Configuration
These are the default values
```lua
require("revj").setup{
    brackets = {first = '([{<', last = ')]}>'}, -- brackets to consider surrounding arguments
    new_line_before_last_bracket = true, -- add new line between last argument and last bracket (only if no last seperator)
    add_seperator_for_last_parameter = true, -- if a seperator should be added if not present after last parameter
    enable_default_keymaps = false, -- enables default keymaps without having to set them below
    keymaps = {
        operator = '<Leader>J', -- for operator (+motion)
        line = '<Leader>j', -- for formatting current line
        visual = '<Leader>j', -- for formatting visual selection
    },
    parameter_mapping = ',', -- specifies what text object selects an arguments (ie a, and i, by default)
        -- if you're using `vim-textobj-parameter` you can also set this to `vim.g.vim_textobj_parameter_mapping`
}
```

# Keybindings
Three keybindings can be enabled:
* `operator` for splitting arguments to new lines within a motion.
* `visual` for splitting arguments to new lines within a visual selection.
* `line` for splitting arguments to new lines from the first occurrence of an enabled bracket until its partner.
Default keybindings can be enabled in the setup (see above), which is equivalent to doing:
```lua
require("revj").setup{
    keymaps = {
        operator = '<Leader>J', -- for operator (+motion)
        line = '<Leader>j', -- for formatting current line
        visual = '<Leader>j', -- for formatting visual selection
    },
}
```

# Development
## Testing
To run the tests locally (TODO update)
```
make test
```
