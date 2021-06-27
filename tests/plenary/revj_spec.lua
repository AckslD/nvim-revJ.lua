local function assert_scenario(scenario)
    print('shiftwidth before', vim.fn.shiftwidth())
    vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.fn.split(scenario.initial_buffer, '\n'))
    for _, command in ipairs(scenario.commands) do
        local keys = vim.api.nvim_replace_termcodes(command, true, false, true)
        vim.api.nvim_feedkeys(keys, 'xm', true)
    end
    print('shiftwidth after', vim.fn.shiftwidth())
    local current_buffer = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n')
    assert.are.equal(current_buffer, scenario.expected_buffer)
end

describe("revJ", function()
    it("normal", function()
        assert_scenario{
            initial_buffer = "some_func([1, 2], 1, 2, 3, True, lst=[], kw1=False, d={2, 3})",
            commands = {",j"},
            expected_buffer = [[some_func(
    [1, 2],
    1,
    2,
    3,
    True,
    lst=[],
    kw1=False,
    d={2, 3},
)]],
        }
    end)

    it("local shiftwidth", function()
        assert_scenario{
            initial_buffer = "some_func([1, 2], 1, 2, 3, True, lst=[], kw1=False, d={2, 3})",
            commands = {":set shiftwidth=2", ",j"},
            expected_buffer = [[some_func(
  [1, 2],
  1,
  2,
  3,
  True,
  lst=[],
  kw1=False,
  d={2, 3},
}]],
        }
    end)
end)
