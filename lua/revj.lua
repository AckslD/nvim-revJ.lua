local revj = {}

local settings = {
    brackets = {first = '([{<', last = ')]}>'},
    new_line_before_last_bracket = true,
    enable_default_keymaps = false,
    keymaps = {},
}

local SHIFTWIDTH = vim.fn.shiftwidth()

local default_keymaps = function()
    return {
        operator = '<Leader>J',
        line = '<Leader>j',
        visual = '<Leader>j',
    }
end

local replace_termcodes = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local normal = function(keys, opts)
    if (opts == nil) then
        opts = {noremap = true} -- default opts
    end
    local cmd
    if (opts.noremap == false) then
        cmd = 'normal'
    else
        cmd = 'normal!'
    end
    vim.cmd(replace_termcodes(cmd.." "..keys))
end

local add_last_colon_if_missing = function(end_pos)
    -- check if either current or next character is , otherwise insert it
    vim.fn.setpos('.', end_pos)
    normal('ya,`]vy', {noremap = false}) -- go to end of arg and get last char
    if (vim.fn.getreg('""') == ',') then
        return
    end
    normal('lvy')
    if (vim.fn.getreg('""') == ',') then
        return
    end
    normal('i,<Esc>')
end

local set_indent = function(indent)
    normal('^d0i'..string.rep(' ', indent))
end

local getcurchar = function()
    normal('vy')
    return vim.fn.getreg('""')
end

local is_end_bracket = function(char)
    return vim.fn.match(settings.brackets.last, char) >= 0
end

local seperate_motion_with_newlines = function(start_pos, orig_indent)
    normal('li<CR><Esc>^') -- new line after motion
    local indent
    if is_end_bracket(getcurchar()) then
        indent = orig_indent
    else
        indent = orig_indent+SHIFTWIDTH
    end
    set_indent(indent)
    vim.fn.setpos('.', start_pos)
    normal('ya,`[', {noremap = true})
    if vim.fn.getcurpos()[3] > 1 then
        normal('i<CR><Esc>') -- new line
        set_indent(orig_indent+SHIFTWIDTH)
    end
end

local is_last_arg = function()
    local cur_line = vim.fn.getcurpos()[2]
    return vim.fn.search([[,.*\S]], 'znc', cur_line) == 0
end

local seperate_args_with_newlines = function(orig_indent)
    while {true} do
        normal('ya,`]', {noremap = false}) -- go to , after first arg
        if is_last_arg() then
            break
        end
        normal('hf i<CR><Esc>') -- new line for next arg
        set_indent(orig_indent+SHIFTWIDTH)
    end
end

local is_arg = function()
    normal('ya,', {noremap = false})
    return vim.fn.getpos("'[")[3] ~= vim.fn.getpos("']")[3]
end

local are_ends_args = function(start_pos, end_pos)
    vim.fn.setpos('.', start_pos)
    if not is_arg() then
        return false
    end
    vim.fn.setpos('.', end_pos)
    if not is_arg() then
        return false
    end
    return true
end

local handle_user_settings = function(user_settings)
    for key, value in pairs(user_settings) do
        settings[key] = value
    end
end

local setup_keys = function()
    local commands = {
        operator = {
            mode = 'n',
            cmd = ':set operatorfunc=v:lua.revj.format_region<CR>g@',
        },
        line = {
            mode = 'n',
            cmd = ':lua require("revj").format_line()<CR>',
        },
        visual = {
            mode = 'v',
            cmd = ':lua require("revj").format_visual()<CR>',
        },
    }

    local opts = {silent=true, noremap=true}
    for op_name, keys in pairs(settings.keymaps) do
        local command = commands[op_name]
        vim.api.nvim_set_keymap(
            command.mode,
            keys,
            command.cmd,
            opts
        )
    end
end

local handle_keymaps = function()
    local keymaps = {}
    if settings.enable_default_keymaps then
        keymaps = default_keymaps()
    end

    for op_name, keys in pairs(settings.keymaps) do
        keymaps[op_name] = keys
    end

    settings.keymaps = keymaps

    setup_keys()
end

local escape_pattern = function(pattern)
    return vim.fn.substitute(pattern, '[', '\\\\[', '')
end

revj.format_region = function(mode)
    local orig_indent = vim.fn.indent('.')
    local start_pos, end_pos
    if (mode == 'char') then
        start_pos = vim.fn.getpos("'[")
        end_pos = vim.fn.getpos("']")
    elseif (mode == 'v') then
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
    else
        return
    end
    if not are_ends_args(start_pos, end_pos) then
        vim.cmd("echoerr 'Motion ends do not overlap with args'")
        return
    end
    if settings.new_line_before_last_bracket then
        add_last_colon_if_missing(end_pos)
    end
    seperate_motion_with_newlines(start_pos, orig_indent)
    seperate_args_with_newlines(orig_indent)
end

revj.format_line = function()
    local cur_line = vim.fn.getcurpos()[2]
    local brackets = settings.brackets.first
    local pattern = '['..escape_pattern(brackets)..']'
    vim.fn.search(pattern, 'z', cur_line)
    local bracket = getcurchar()
    vim.cmd(':set operatorfunc=v:lua.revj.format_region')
    normal('g@i'..bracket)
end

revj.format_visual = function()
    revj.format_region(vim.fn.visualmode())
end

revj.setup = function(user_settings)
    if (user_settings == nil) then
        user_settings = {}
    end
    _G.revj = revj

    handle_user_settings(user_settings)
    handle_keymaps()
end

return revj
