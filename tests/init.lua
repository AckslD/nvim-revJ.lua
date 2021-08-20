print('here')
vim.o.runtimepath = vim.o.runtimepath .. ',./rtps/plenary.nvim'
vim.o.runtimepath = vim.o.runtimepath .. ',./rtps/vim-textobj-user'
vim.o.runtimepath = vim.o.runtimepath .. ',./rtps/vim-textobj-parameter'
vim.o.runtimepath = vim.o.runtimepath .. ',.'
vim.cmd('runtime! plugin/textobj/parameter.vim')

vim.g.mapleader = ','
vim.bo.shiftwidth = 4

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
