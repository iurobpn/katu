local tbl = require('katu.lua.tbl')
local M = {}
M.month_names = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

M.week_days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}

-- Get the first day of the month and how many days in the month
function M.get_month_data(year, month)
    -- Lua's os.date uses 1-indexed months
    local first_day = tonumber(os.date("%w", os.time{year=year, month=month, day=1}))
    local days_in_month = tonumber(os.date("%d", os.time{year=year, month=month + 1, day=0}))
    return first_day, days_in_month
end

-- M.fmt(format, ...)
--
--
-- if  then
--     
--     return string.format(format, ...)
--     end
-- end

-- Draw a line of the calendar
M.h_line_inner = function(h_padding, n_squares, square_width, sep, inner_sep, border_seps)
    local hpad = string.rep(' ', h_padding)
    local elem = string.rep(sep, square_width)

    local lsep
    local rsep
    if border_seps == nil then
        lsep = inner_sep
        rsep = inner_sep
    else
        lsep = border_seps.left
        rsep = border_seps.right
    end

    local t_sq = {}
    for _ = 1, n_squares do
        table.insert(t_sq, elem)
    end

    local line = hpad .. lsep .. table.concat(t_sq, inner_sep) .. rsep .. hpad

    return line
end


function M.draw_calendar_line(h_padding, square_width, t_elem, sep, border_seps)

    -- print('h_padding: ' .. h_padding)
    -- print('square_width: ' .. square_width)
    if type(t_elem) == 'string' then
        t_elem = {t_elem}
    end
    -- print('------------- init of draw_line -------------')

    local rsep
    local lsep
    if border_seps == nil then
        lsep = sep
        rsep = sep
    else
        lsep = border_seps.left
        rsep = border_seps.right
    end

    local hp = string.rep(" ", h_padding)
    -- print('h_padding: ' .. h_padding)
    -- print('hp: ' .. M.len(hp))

    local isep = sep
    local line = hp .. lsep
    -- print(string.format('init line: (%d): %s', M.len(line), line))
    for i, elem in ipairs(t_elem) do
        if i == #t_elem then
            isep = rsep
        end
        -- print(string.format('---------------- square %d --------------------', i))
        -- print('elem: ' .. elem)
        -- print('line size: ' .. M.len(line))
        local n_left = math.floor((square_width + #elem) / 2)
        local n_right = square_width - n_left + #isep -- including the border
        -- elem = tostring(elem)
        -- print('elem size: ' .. M.len(elem))
        -- print('n_left: ' .. n_left)
        -- print('n_right: ' .. n_right)

        local sql = string.format('%' .. n_left .. 's', elem)
        local sqr = string.format('%' .. n_right .. 's', isep)
        local sq = sql .. sqr
        -- print(string.format('sq [%d: (%d,%d)]: %s', M.len(sq), M.len(sql), M.len(sqr), sq))
        -- print('line size: ' .. M.len(line))
        line = line .. sq
        -- print('total(n_left + n_right + #elem): ' .. (n_left + n_right + M.len(elem) ))
        -- print('square_width: ' .. square_width)
        -- print('line size: ' .. M.len(line))
        -- print(string.format('------------ end square %d --------------------', i))
    end
    -- print('hpad: ' .. hp)
    -- print('rsep: ' .. rsep)
    line = line .. hp
    -- print('line size: ' .. M.len(line))
    --
 --    print('expected size: ' .. 2*h_padding + #t_elem * square_width + #t_elem + 1)
 --    print('line:')
 --    print(line)

    assert(M.len(line) == M.win_width)
    -- print('-------------- end of draw_line -------------')
    return line

end

M.borders = {
    table = {
        top = {
            left = "┌",
            right = "┐",
        },
        bottom = {
            right = "┘",
            left = "└",
        },

        vert = "│",
        horiz = "─",

        tri = {
            left = "├",
            right = "┤",
            top = "┬",
            bottom = "┴",
        },
        quad = "┼",
    },
    square = {
        top = {
            left   = "🭽",
            right  = "🭾",
        },
        bottom = {
            right  = "🭿",
            left   = "🭼",
        },
        vert = {
            left   = "▏",
            right  = "▕",
        },
        horiz = {
            top    = "▔",
            bottom = "▁",
        },
        tri = {
            left   = {
                "🭼",
                "🭽",
            },
            right  = {
                "🭿",
                "🭾",
            },

            top    = "🭾🭽",
            bottom = "🭿🭼",
            -- inverted top and bottom
        },
        quad = {
            bottom = "🭿🭼",
            top    = "🭾🭽",
        },
    },
    double = {
        top = {
            left = "╔",
            right = "╗",
        },
        bottom = {
            right = "╝",
            left = "╚",
        },
        vert = "║",
        horiz = "═",
        tri = {
            left = "╠",
            right = "╣",
            top = "╦",
            bottom = "╩",
        },
        quad = "╬",
    }
}

M.icons = {
    Class = " ",
    Color = " ",
    Constant = " ",
    Constructor = " ",
    Enum = " ",
    EnumMember = " ",
    Field = "󰄶 ",
    File = " ",
    Folder = " ",
    Function = " ",
    Interface = "󰜰",
    Keyword = "󰌆 ",
    Method = "ƒ ",
    Module = "󰏗 ",
    Property = " ",
    Snippet = "󰘍 ",
    Struct = " ",
    Text = " ",
    Unit = " ",
    Value = "󰎠 ",
    Variable = " ",
    prefix = '■', -- Could be '●', '▎', 'x'

    prompt = '󰨭 ',           -- Prompt Icon
    preview_prompt = ' ',   -- Preview Prompt Icon

    signs = {
        Error = "󰅚",
        Warn = "󰀪",
        Hint = "󰌶",
        Info = " ",
    },
}

function M.h_line(h_padding, square_width, sep, border_seps)
    local p_horiz = string.rep(' ', h_padding)
    local lsep, rsep
    if border_seps then
        lsep = border_seps.left
        rsep = border_seps.right
    else
        lsep = sep
        rsep = sep
    end
    local line = p_horiz .. lsep .. string.rep(sep, square_width * 7 + 6) .. rsep .. p_horiz
    -- print sizes
    local n_line = M.len(line)
    -- print('-------------- h_line --------------')
    -- print('line size: ' .. n_line)
    -- print('line: ' .. line)
    -- print('h_padding: ' .. h_padding)
    -- print('square_width: ' .. square_width)
    -- print('sep (' .. M.len(sep) .. '): ' .. sep)
    -- print('p_horiz size: ' .. M.len(p_horiz))
    -- print('lsep (' .. M.len(lsep) .. '): ' .. lsep)
    -- print('rsep (' .. M.len(rsep) .. '): ' .. rsep)
    -- print('n: ' .. n)
    -- print('win_width: ' .. M.win_width)
    -- print('-------------- end h_line --------------')

    assert(n_line == M.win_width)
    return line
end

M.len = function(str)
    -- count char in string dividing unicode of M.seps by 3
    local total = #str
    local border = tbl.flatten(M.border)
    -- print('border: ' .. #border)
    local unicode = 0
    for _, u in ipairs(border) do
        for m in str:gmatch(u) do
            if m ~= nil then
                unicode = unicode + #m - 1
            end
        end
    end
    return total - unicode
end

function M.set_hl()
    M.ns_id = vim.api.nvim_create_namespace('calendar')
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)

    -- Step 3: Apply an empty highlight namespace to the window
    -- local empty_ns = vim.api.nvim_create_namespace('empty_ns')
    -- vim.api.nvim_win_set_hl_ns(0, empty_ns)
    -- Create a new empty namespace


    local colors = require('katu.gruvbox-colors').palette
    local hl_group = {}
    if colors.light0 == nil then
        print('colors not found')
        hl_group = { bg = '#1E1E2E', fg = '#C0CAF5' }
    else
        hl_group = {bg = colors.dark0_hard, fg=colors.bright_blue, underline = false}
    end
    vim.api.nvim_set_hl(M.ns_id, 'Normal', hl_group)

    -- vim.cmd('set winhl=Normal:WinBg')
    -- vim.api.nvim_win_set_hl_ns(0, M.ns_id)

    -- local grid_ns = vim.api.nvim_create_namespace('grid_ns')
    -- vim.api.nvim_set_hl(0, 'Normal', {bg = colors.dark4})
    -- Set the window's highlight namespace to the new one
end

M.set_grid_hl = function(v_padding, h_padding, win_width, grid_height)
    M.set_hl()
    -- set hl on the lines vert_padding + 1 to vert_padding + 25 of the buffer
    -- also, from columns horiz_padding to win_width - horiz_padding
    local colors = require('katu.gruvbox-colors').palette
    local hl_group = {}
    if colors.light0 == nil then
        print('colors not found')
        hl_group = { bg = '#1E1E2E', fg = '#C0CAF5' }
    else
        hl_group = {bg = colors.dark3, fg=colors.light0_hard, underline = false}
    end
    -- Create a new namespace

    -- set the hl groups
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_hl(0, 'CalendarBg', hl_group)

    -- set hl on the lines vert_padding + 1 to vert_padding + 25 of the buffer
    -- also, from columns horiz_padding to win_width - horiz_padding

    -- for i = v_padding + 1, v_padding + 2grid_height do
    local col_init = h_padding
    local col_end = win_width - h_padding
    for i = v_padding + 1, v_padding + grid_height do
    -- for i = v_padding + 1, v_padding + 2 do
        print('i: ' .. i .. ', col_init: ' .. col_init .. ', col_end: ' .. col_end)

        -- clear the buffer highlines on the line andcols
        -- vim.api.nvim_buf_clear_namespace(0, -1, i, i+1)
        vim.api.nvim_buf_add_highlight(bufnr, M.ns_id, 'CalendarBg', i, col_init, col_end)
    end
    vim.cmd('set nonumber')
    vim.cmd('set norelativenumber')
    vim.cmd('set nocursorline')
    vim.cmd('set signcolumn=no')
    vim.cmd('set colorcolumn=0')
end

-- Draw the calendar dynamically based on the window size
function M.draw_calendar(year, month, border, win_width, win_height)
    if border == nil then
        border = M.borders.table
    end
    -- print('border')
    M.border = border
    -- print('flattened border')
    -- Get window dimensions
    if win_width == nil then
        M.win_width = vim.api.nvim_win_get_width(0)-2
    else
        M.win_width = win_width
    end
    if win_height == nil then
        M.win_height = vim.api.nvim_win_get_height(0)-1
    else
        M.win_height = win_height
    end

    -- Calculate the number of squares and padding
    local horizontal_padding = 10
    local vertical_padding = 3
    local total_width = win_width - 2 * horizontal_padding
    local total_height = win_height - 2 * vertical_padding
    local square_width = math.floor((total_width - 8) / 7) -- wo margins
    local square_height = math.floor(total_height / 5)
    local total_cal_width = square_width * 7 + 8 -- with margins

--  |  Sun  |  Mon  |  Tue  |  Wed  |  Thu  |  Fri  |  Sat  |
--  |  %ns1  %ns|  %ns2 %ns| ...
    -- print("Win width: " .. win_width)
    -- print("Win height: " .. win_height)
    -- print("Square width: " .. square_width)
    -- print("Square height: " .. square_height)
    -- print("hpadding: " .. horizontal_padding)


    -- Create a new buffer or use the current one
    -- local buf = vim.api.nvim_get_current_buf()

    -- Create a new buffer or use the current one
    local buf = vim.api.nvim_create_buf(false, true)  -- regular buffer, listed
    vim.api.nvim_set_option_value('bufhidden', 'wipe', {buf = buf})
    -- Clear the buffer before redrawing
    -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})


    -- Set Gruvbox colors
    vim.api.nvim_command('hi CalendarSquare guibg=#3c3836')   -- Dark grey for squares
    vim.api.nvim_command('hi CalendarBorder guifg=#504945')   -- Lighter grey for borders
    vim.api.nvim_command('hi CalendarBackground guibg=#282828') -- Darkest black for background

    -- local p_horiz = string.rep(' ', horizontal_padding)

    local top_line = M.h_line(horizontal_padding, square_width, border.horiz, border.top)
    -- local bottom_line = M.h_line(horizontal_padding, square_width, border.horiz, border.bottom)
    local h_line = M.h_line_inner(horizontal_padding,
        #M.week_days, square_width, border.horiz,
        border.quad, border.tri)

    local htop_line = M.h_line_inner(horizontal_padding, #M.week_days,
        square_width, border.horiz, border.tri.top, border.tri)

    local bottom_line = M.h_line_inner(horizontal_padding, #M.week_days,
        square_width, border.horiz, border.tri.bottom,
        border.bottom)
    -- local h_line = M.h_line(horizontal_padding, square_width, border.horiz, border.tri)

    local blank_line = string.rep(" ", win_width)

    local cal = {}
    -- Add padding to the top
    for _ = 1, vertical_padding do
        table.insert(cal, blank_line)
        -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { blank_line })
    end

    -- Get month data
    local first_day, days_in_month = M.get_month_data(year, month)

    -- Add month title centered
    local month_title = string.format("%s %d", M.month_names[month], year)
    -- local title_padding = math.floor((win_width + #month_title) / 2)

    table.insert(cal, top_line)
    local blank_week = {}
    for _ = 1, #M.week_days do
        table.insert(blank_week, '')
    end

    local cal_blank_line = M.draw_calendar_line(horizontal_padding, square_width, blank_week, border.vert)

    -- print('before month title')
    local line = M.draw_calendar_line(horizontal_padding, square_width*#M.week_days + 6, month_title, border.vert)
    table.insert(cal, line)
    table.insert(cal, htop_line)

    -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
    -- Add day labels (Su Mo Tu We Th Fr Sa)

    line = M.draw_calendar_line(horizontal_padding, square_width, M.week_days, border.vert)
    table.insert(cal, line)
    -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })

    -- Add the days with the calculated padding and sizes
    local week_day = os.date('%w', os.time({year=year, month=month, day=1}))
    -- print('week_day: ' .. week_day)
    -- check if the first day is sunday, if not subtract day difference from the 1st to sunday
    local first_day = 1 - tonumber(week_day)

    local day = first_day
    for week = 1, 6 do
        local week_list = {}
        if day > days_in_month then
            break
        end

        for day_of_week = 1, 7 do
            if day <= days_in_month and day > 0 then
                table.insert(week_list, string.format(" %2d ", day))
            else
                table.insert(week_list,'')
            end
            day = day + 1
        end

        line = M.draw_calendar_line(horizontal_padding, square_width, week_list, border.vert)
        table.insert(cal, h_line)
        table.insert(cal, cal_blank_line)
        table.insert(cal, line)
        table.insert(cal, cal_blank_line)

        -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, week_square)
        -- vim.api.nvim_buf_add_highlight(buf, -1, 'CalendarSquare', week + 1, 0, -1)
    end

    table.insert(cal, bottom_line)
    -- Add padding to the bottom
    for i = 1, vertical_padding do
        table.insert(cal, blank_line)
        -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { string.rep(" ", win_width) })
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, cal)
    vim.api.nvim_win_set_buf(0, buf)

    -- Set the buffer to be unmodifiable
    vim.api.nvim_set_option_value('modifiable', false, {buf = buf})
    M.set_grid_hl(vertical_padding, horizontal_padding, win_width, #cal - 2*vertical_padding )
end

function M.change_month(direction)
    current_month = current_month + direction
    if current_month < 1 then
        current_month = 12
        current_year = current_year - 1
    elseif current_month > 12 then
        current_month = 1
        current_year = current_year + 1
    end
    M.draw_calendar(current_year, current_month)
end

-- Key mappings for navigating months
vim.api.nvim_set_keymap('n', 'h', ':lua M.change_month(-1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'l', ':lua M.change_month(1)<CR>', { noremap = true, silent = true })

-- Auto resize the calendar when window size changes
vim.api.nvim_command('autocmd VimResized * lua M.draw_calendar(current_year, current_month)')

-- Initial draw
-- M.draw_calendar(current_year, current_month)
return M
