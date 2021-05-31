-- vim.cmd('filetype plugin on')
-- vim.cmd('set runtimepath+="/home/axel/Dev/vim-plugins/nvim-revJ.lua"')
vim.o.runtimepath = vim.o.runtimepath..",/home/axel/Dev/vim-plugins/nvim-revJ.lua"
vim.o.runtimepath = vim.o.runtimepath..",/home/axel/.local/share/nvim/site/pack/packer/start/vim-textobj-parameter"
vim.cmd("source /home/axel/.local/share/nvim/site/pack/packer/start/vim-textobj-parameter/plugin/textobj/parameter.vim")
vim.bo.shiftwidth = 4

vim.g.mapleader = 'a'

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
}