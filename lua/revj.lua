local revj = {}

local settings = {
    brackets = {first = '([{<', last = ')]}>'},
    new_line_before_last_bracket = true,
    add_seperator_for_last_parameter = true,
    enable_default_keymaps = false,
    keymaps = {},
    parameter_mapping = ',',
}

local shiftwidth = vim.fn.shiftwidth()
local SEPERATOR = ',' -- TODO others?

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

local select_and_return_inner_parameter = function()
    normal('yi'..settings.parameter_mapping, {noremap = false})
    return vim.fn.getreg('""')
end

local select_and_return_outer_parameter = function()
    normal('ya'..settings.parameter_mapping, {noremap = false})
    return vim.fn.getreg('""')
end

local getcurchar = function()
    normal('vy')
    return vim.fn.getreg('""')
end

local is_end_bracket = function(char)
    return vim.fn.match(settings.brackets.last, char) >= 0
end

local is_cur_parameter_empty = function()
    local parameter = select_and_return_outer_parameter()
    normal('`]')
    return vim.fn.match(parameter, '^\\s*'..SEPERATOR..'\\s*$') >= 0
end

local set_indent = function(indent)
    normal('^d0i'..string.rep(' ', indent))
end

local only_whitespace_to_the_left = function()
    local cur_pos = vim.fn.getcurpos()
    normal('y0')
    local left_text = vim.fn.getreg('""')
    local is_match = vim.fn.match(left_text, '^\\s*$') >= 0
    vim.fn.setpos('.', cur_pos)
    return is_match
end

local go_to_start_of_first_overlapping_parameter = function(region, opts)
    if opts == nil then
        opts = {}
    end
    vim.fn.setpos('.', region.first)
    if opts.inner then
        select_and_return_inner_parameter()
    else
        select_and_return_outer_parameter()
    end
end

local go_to_end_of_last_overlapping_parameter = function(region, opts)
    if opts == nil then
        opts = {}
    end
    vim.fn.setpos('.', region.last)
    if opts.inner then
        select_and_return_inner_parameter()
    else
        select_and_return_outer_parameter()
    end
    normal('`]')
end

local add_newline = function()
    normal('a<CR><Esc>')
end

local nohlsearch = function()
    vim.cmd('nohlsearch')
end

local remove_all_indent = function()
    vim.cmd('s/^\\s*//')
    nohlsearch()
end

local are_pos_equal = function(pos1, pos2)
    for i=1, 3 do
        if pos1[i] ~= pos2[i] then
            return false
        end
    end
    return true
end

local is_at_place_of_line = function(place)
    local cur_pos = vim.fn.getcurpos()
    normal(place) -- go to place of line
    local place_pos = vim.fn.getcurpos()
    local answer = are_pos_equal(cur_pos, place_pos)
    vim.fn.setpos('.', cur_pos)
    return answer
end

local is_at_start_of_line = function()
    return is_at_place_of_line('0')
end

local is_at_end_of_line = function()
    return is_at_place_of_line('$')
end

local get_next_char = function()
    if is_at_end_of_line() then
        return '\n'
    end
    normal('l')
    local char = getcurchar()
    normal('h')
    return char
end

local remove_trailing_whitespace = function()
    vim.cmd('s/\\s*$//')
    nohlsearch()
end

local format_end_of_region = function(region, orig_indent)
    go_to_end_of_last_overlapping_parameter(region)
    if is_cur_parameter_empty() then
    elseif get_next_char() == SEPERATOR then
        normal('l')
    elseif is_end_bracket(get_next_char()) then
        select_and_return_inner_parameter()
        normal('`]') -- go to end of inner argument
        if settings.add_seperator_for_last_parameter then
            normal('a'..SEPERATOR..'<Esc>')
        end
        if not settings.new_line_before_last_bracket then
            return
        end
    else
        error("unexpected scenario after region")
    end
    add_newline()
    remove_trailing_whitespace()
    remove_all_indent()
    local new_indent
    if is_end_bracket(getcurchar()) then
        new_indent = orig_indent
    else
        new_indent = orig_indent+shiftwidth
    end
    set_indent(new_indent)
end

local format_start_of_region = function(region, orig_indent)
    go_to_start_of_first_overlapping_parameter(region, {inner=true})
    if not only_whitespace_to_the_left() then
        normal('i<CR><Esc>') -- new line
        set_indent(orig_indent+shiftwidth)

        -- remove trailing whitespace on this and previous line
        remove_trailing_whitespace()
        local cur_pos = vim.fn.getcurpos()
        normal('k')
        remove_trailing_whitespace()
        vim.fn.setpos('.', cur_pos)
    end
end

local seperate_motion_with_newlines = function(region, orig_indent)
    format_end_of_region(region, orig_indent)
    format_start_of_region(region, orig_indent)
end

local is_last_parameter_on_line = function()
    local cur_line = vim.fn.getcurpos()[2]
    return vim.fn.search([[,.*\S]], 'znc', cur_line) == 0
end

local seperate_parameters_with_newlines = function(orig_indent)
    while true do
        local cur_pos = vim.fn.getcurpos()
        select_and_return_inner_parameter()
        normal('`]f'..SEPERATOR) -- go to , after first parameter
        local new_pos = vim.fn.getcurpos()
        if are_pos_equal(cur_pos, new_pos) then
            error("couldn't not format current given region")
        end
        if is_last_parameter_on_line() then
            break
        end
        add_newline()
        remove_trailing_whitespace()
        set_indent(orig_indent+shiftwidth)
    end
end

local is_parameter = function()
    select_and_return_outer_parameter()
    return vim.fn.getpos("'[")[3] ~= vim.fn.getpos("']")[3]
end

local are_ends_parameters = function(region)
    vim.fn.setpos('.', region.first)
    if not is_parameter() then
        return false
    end
    vim.fn.setpos('.', region.last)
    if not is_parameter() then
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

local avoid_seperators_at_ends_of_region = function(region)
    vim.fn.setpos('.', region.first)
    while (getcurchar() == SEPERATOR) do
        if is_at_end_of_line() then
            vim.cmd('echoerr "got invalid region to format"')
            return nil
        end
        normal('l')
    end
    region.first = vim.fn.getpos('.')

    vim.fn.setpos('.', region.last)
    while (getcurchar() == SEPERATOR) do
        if is_at_start_of_line() then
            vim.cmd('echoerr "got invalid region to format"')
            return nil
        end
        normal('h')
    end
    region.last = vim.fn.getpos('.')

    if region.first[3] > region.last[3] then
        vim.cmd('echoerr "got invalid region to format"')
        return nil
    end

    return region
end

local get_region = function(mode)
    local first, last
    if (mode == 'char') then
        first = vim.fn.getpos("'[")
        last = vim.fn.getpos("']")
    elseif (mode == 'v') then
        first = vim.fn.getpos("'<")
        last = vim.fn.getpos("'>")
    else
        return
    end
    local region = {first = first, last = last}
    region = avoid_seperators_at_ends_of_region(region)
    return region
end

local go_to_first_parameter_of_expression = function()
    local cur_pos = vim.fn.getcurpos()
    local new_pos
    while true do
        if getcurchar() == SEPERATOR then
            normal('h')
        end
        select_and_return_outer_parameter()
        new_pos = vim.fn.getcurpos()
        if are_pos_equal(cur_pos, new_pos) then
            return
        end
        cur_pos = new_pos
    end
end

local go_to_start_bracket = function()
    go_to_first_parameter_of_expression()
    normal('b')
end

local get_orig_indent = function()
    go_to_start_bracket()
    return vim.fn.indent('.')
end

local update_local_shiftwidth = function()
    shiftwidth = vim.fn.shiftwidth()
end

local function without_autocmd_wrap(func)
  return function(...)
    local saved = vim.api.nvim_get_option('eventignore')
    vim.api.nvim_set_option('eventignore', 'all')
    func(...)
    vim.api.nvim_set_option('eventignore', saved)
  end
end

revj.format_region = without_autocmd_wrap(function(mode)
    update_local_shiftwidth()
    local region = get_region(mode)
    if region == nil then
        return
    end
    local orig_indent = get_orig_indent()
    if not are_ends_parameters(region) then
        vim.cmd("echoerr 'Motion ends do not overlap with parameters'")
        return
    end
    seperate_motion_with_newlines(region, orig_indent)
    seperate_parameters_with_newlines(orig_indent)
end)

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
