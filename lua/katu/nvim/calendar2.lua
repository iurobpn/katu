local api = vim.api
local M = {}

M.month_names = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

-- Get the first day of the month and how many days in the month
function M.get_month_data(year, month)
    -- Lua's os.date uses 1-indexed months
    local first_day = tonumber(os.date("%w", os.time{year=year, month=month, day=1}))
    local days_in_month = tonumber(os.date("%d", os.time{year=year, month=month + 1, day=0}))
    return first_day, days_in_month
end

-- Create the calendar structure in a regular buffer
function M.draw_calendar(year, month)
    -- Create a new buffer for the calendar
    local buf = api.nvim_create_buf(true, false)  -- regular buffer, listed
    api.nvim_set_option_value('bufhidden', 'wipe', {buf = buf})

    -- Open a new split window with the calendar
    api.nvim_command("vsplit")
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, buf)

    -- Set up Gruvbox theme colors
    api.nvim_command('hi CalendarSquare guibg=#3c3836')   -- Dark grey for squares
    api.nvim_command('hi CalendarBorder guifg=#504945')   -- Lighter grey for borders
    api.nvim_command('hi CalendarBackground guibg=#282828') -- Darkest black for background

    local height = 5
    local width = 48
    local bline = string.rep(" ", width)
    -- Fill buffer with background color
    for i = 1, 10 do
        api.nvim_buf_set_lines(buf, i-1, i, false, { bline }) -- Adjust width
    end
    api.nvim_buf_add_highlight(buf, -1, 'CalendarBackground', 0, 0, -1)

    -- Get month data
    local first_day, days_in_month = M.get_month_data(year, month)



    local month_year = M.center(M.month_names[month], year, width)
    -- Add the month name at the top
    api.nvim_buf_set_lines(buf, 0, 1, false, { "      " ..  month_year })
    api.nvim_buf_add_highlight(buf, -1, 'CalendarBorder', 0, 0, -1)

    -- Add the days of the week
    api.nvim_buf_set_lines(buf, 1, 2, false, { " Sun Mon Tue Wed Thu Fri Sat " })
    api.nvim_buf_add_highlight(buf, -1, 'CalendarBorder', 1, 0, -1)

    -- Add the days in squares
    local day = 1
    for week = 1, 6 do
        local week_str = ""
        for day_of_week = 1, 7 do
            if week == 1 and day_of_week <= first_day or day > days_in_month then
                week_str = week_str .. "    "
            else
                week_str = week_str .. string.format(" %2d ", day)
                day = day + 1
            end
        end
        api.nvim_buf_set_lines(buf, week + 1, week + 2, false, { week_str })
        api.nvim_buf_add_highlight(buf, -1, 'CalendarSquare', week + 1, 0, -1)
    end

    -- Optionally, set the buffer to be unmodifiable
    api.nvim_set_option_value('modifiable', false, {buf = buf})
    -- api.nvim_buf_set_option(buf, 'listed', false)

    vim.cmd('set nonumber')
    vim.cmd('set norelativenumber')
end

function M.center(text, year, width)
    local padding = math.floor((width - #text - 4) / 2)
    return string.rep(" ", padding) .. text  .. " " .. year .. string.rep(" ", padding)
end

-- Example usage
M.draw_calendar(2024, 9)
