if vim == nil then
    return
end

require('katu.utils.class')
local utils = require('katu.utils')
-- local Log = require('katu.lua.log').Log

local Buffer = require('katu.nvim.utils').Buffer

local fmt = string.format

local Window = {
    vid = nil, -- vim id
    idx = -1,  -- index of the window inside the module
    relative = 'editor',

    -- local log = Log('float')
    ----- static ----------------------
    id_count = 0,
    floats = {}, -- list of open floats, indexed by the wim win id
    hidden = {}, -- list of hidden floats, indexed by the wim win id
    ns = {},
    size = {
        relative = {
            width = 0.5,
            height = 0.5,
        },
        -- absolute = {
        --     height = 0,
        --     height = 0,
        -- },
        flex = false
    },

    position = "center",

    border = 'rounded',
    is_toggleable = true,

    content = '',
    filename = '',

    -- Window.-- zindex = 50,
    -- Window.-- external = false,
    title = '',
    maps = {
        n = {
            -- keys = 'q',
            -- cmd = ':lua Window.close()<CR>',
            -- opts = { noremap = true, silent = true }
            },
        i = {},
        v = {},
    },
    close_map = {
        mode = 'n',
        key = 'q',
        cmd = ':Win toggle<CR>',
        opts = { noremap = true, silent = true }
    },
    current = false, --get current windows buffer
    buffer = {
        listed = true,
        scratch = false,
    },
    fullscreem = false,

    focusable = true,
    close_current = false, -- close current window when it is being floated
    option = {
        window = {
            wrap = nil,
            number = nil,
            relativenumber = nil,
            cursorline = nil,
            signcolumn = nil,
            foldcolumn = nil,
            winhighlight = nil,
            winblend = nil,
            winfixwidth = nil,
            winfixheight = nil,

        },
        buffer = {
            modifiable = true,
            swapfile = true,
            buftype = '', -- set the buffer type prompt and terminal are interesting types
            bufhidden = '',
            buflisted = true,
        }
    },

    colors = require('katu.gruvbox-colors').get_colors(),

}
--------------------------------

function Window.new(...)
    local self = {}
    local opts = { ... }
    opts = opts[1]
    if opts then
        for k, v in pairs(opts) do
            if k ~= 'maps' then
                self[k] = v
            end
        end
    end
    self.idx = Window.new_id()

    return self
end

function Window.set_link_ns()
    local ns_id = vim.api.nvim_create_namespace('dev_float')

    if Window.ns.link == nil then
        Window.ns.link = { -- highlight namespaces
            id = ns_id,
            name = 'dev_float',
            normal = {
                group = 'link_hl',
                opts = {
                    fg = Window.colors.neutral_blue,
                    underline = false,
                },
            },
            hover = {
                group = 'link_hover_hl',
                opts = {
                    fg = Window.colors.blue,
                    underline = false,
                }
            }
        }
    end

    local link = Window.ns.link

    vim.api.nvim_set_hl(0, link.normal.group, link.normal.opts)
    vim.api.nvim_set_hl(0, link.hover.group, link.hover.opts)
end

function Window.ui_width()
    return vim.o.columns
end

function Window.ui_height()
    return vim.o.lines
end

function Window:win_width()
    local width
    if self ~= nil and self.vid ~= nil then
        width = vim.api.nvim_win_get_width(self.vid)
    else
        width = vim.o.columns
    end

    return width
end

function Window:win_height()
    local height
    if self ~= nil and self.vid ~= nil then
        height = vim.api.nvim_win_get_height(self.vid)
    else
        height = vim.o.lines
    end

    return height
end

function Window:config(...)
    local opts = { ... }
    opts = opts[1]
    if opts then
        for k, v in pairs(opts) do
            if k ~= 'maps' then
                self[k] = v
            end
        end
    end
end

function Window:get_size()
    local ui_width = self:ui_width()
    local ui_height = self:ui_height()

    local width = 0
    local height = 0

    if self.size.flex then
        local lines = Buffer.get_lines(self.buf)

        -- Calculate the height (number of lines)
        height = #lines

        -- Calculate the width (the length of the longest line)
        width = 0
        for _, line in ipairs(lines) do
            if #line > width then
                width = #line
            end
        end
        if width == 0 then
            width = 1
        end
        if height == 0 then
            height = 1
        end
    elseif self.size.absolute then
        width = self.size.absolute.width
        height = self.size.absolute.height
    elseif self.size.flex then
        height = ui_height * (self.size.relative.height or Window.size.relative.height)
        if #self.content == 0 then
            Buffer.get_lines(self.buf)
        end
        local tmp_width = self:get_max_content_width(self.content) + 2
        if tmp_width > ui_width or tmp_width <= 1 then
            tmp_width = ui_width
        end
        width = tmp_width
    elseif self.size.relative then
        width = ui_width * self.size.relative.width
        height = ui_height * self.size.relative.height
    else
        error('Size not set size')
    end

    return width, height
end

function Window:set_size()
    self.width, self.height = self:get_size()
    self.width = math.floor(self.width)
    self.height = math.floor(self.height)
end

function Window:add_map(mode, keys, cmd, opts)
    table.insert(self.maps[mode], { keys = keys, cmd = cmd, opts = opts })
end

function Window:params()
    local width, height = self:get_size()
    local col, row = self:get_position()
    print(fmt('params: width: %s, height: %s, col: %s, row: %s', width, height, col, row))
end

function Window.up()
    -- get the current window  win id
    Window.move(0, 3)
end

function Window.down()
    -- get the current window  win id
    Window.move(0, -3)
end

function Window.left()
    -- get the current window  win id
    Window.move(5, 0)
end

function Window.right()
    -- get the current window  win id
    Window.move(-5, 0)
end

function Window.move(dx, dy)
    -- get the current window  win id
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        return
    end

    if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row[false] = win_config.row[false] - dy -- Adjust the row positiondx, dy
    win_config.col[false] = win_config.col[false] - dx -- Adjust the row positiondx, dy
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window:close(vid)
    local win_id = 0
    if self == nil and vid == nil then
        win_id = vim.fn.win_getid()
    elseif vid == nil then
        win_id = self.vid
    elseif vid >= 0 then
        win_id = vid
        Window.set_win(win_id)
    end
    if win_id ~= nil and Window.is_floating(win_id) then
        -- Buffer.unmap(self.buf)
        vim.api.nvim_win_close(win_id, true)
        Window.floats[win_id] = nil
        if self ~= nil then
            self.vid = nil
        end
    else
        vim.notify("Current window is either invalid (id) or is not a float to close.")
    end
end

function Window.set_win(vid)
    if vim.api.nvim_win_is_valid(vid) then
        vim.api.nvim_set_current_win(vid)
    else
        vim.notify("Invalid window ID")
    end
end

function Window:set_options()
    local buffer = self.option.buffer or {}
    for k, v in pairs(buffer) do
        vim.api.nvim_set_option_value(k, v, { buf = self.buf })
    end
    local window = self.option.window or {}
    for k, v in pairs(window) do
        vim.api.nvim_set_option_value(k, v, { win = self.vid })
    end
end

function Window:get_config()
    return {
        relative = self.relative,
        width = self.width,
        height = self.height,
        anchor = self.anchor,
        row = self.row,
        col = self.col,
        focusable = self.focusable,
        zindex = self.zindex,
        external = self.external,
        style = self.style,
        border = self.border,

        title = self.title,
        title_pos = self.title_pos,
        footer = self.footer,
        footer_pos = self.footer_pos,
        hide = self.hide,
        -- for open_win
        -- vertical = self.vertical,
        -- split = self.split,
    }
end

function Window.close_all()
    for vid, win in pairs(Window.floats) do
        if win ~= nil and Window.is_floating(vid) then
            win:close()
        end
    end
end

function Window:open(filename, linenr)
    self.filename = filename
    self.linenr = linenr


    -- if not self.cursor then
    -- --     vim.opt.guicursor = vim.o.background
    --     vim.cmd(fmt('highlight Cursor guifg=%s guibg=%s', vim.o.background, vim.o.background))
    -- end

    if self.current then -- use current buffer
        self.vid, self.buf, self.filename = Window.get_current()
        -- elseif self.buf then -- use the buffer already set
    elseif self.vid ~= nil then -- use the window id already set. It must be a float
        self.buf, self.filename = Window.get_window(self.vid)
    else
        if self.buf == nil then
            self.buf = Buffer.scratch()
        end
        if self.filename ~= nil and #self.filename > 0 then -- create a buffer to load the file
            Buffer.set_value(self.buf, 'modifiable', true)
            Buffer.load(self.buf, self.filename)
        elseif self.content ~= nil and #self.content > 0 then -- create a buffer and load the content into it
            if not Buffer.is_valid(self.buf) then
                Buffer.set_value(self.buf, 'modifiable', true)
                -- vim.api.nvim_set_option_value('modifiable', true, { buf = self.buf })
            end
            Buffer.set_lines(self.buf, self.content)
        end
    end

    self:set_size()
    self:set_position()

    local opts = self:get_config()

    if not self.buf then
        vim.notify("No buffer to open")
        return
    end

    if self.current then
        vim.api.nvim_win_set_config(self.vid, opts)
    else
        self.vid = vim.api.nvim_open_win(self.buf, true, opts)
        vim.api.nvim_win_set_buf(self.vid, self.buf)
    end

    if self.vid ~= nil and self.close_current or opts.close_current then
        vim.api.nvim_win_close(self.vid, false)
    end
    if self.idx < 0 then
        self.idx = Window.id_count
        Window.id_count = Window.id_count + 1
    end

    if not self.modifiable then
        vim.api.nvim_buf_set_keymap(self.buf, self.close_map.mode,
            self.close_map.key, self.close_map.cmd, {
                noremap = true,
                silent = true
            })
    else
        vim.api.nvim_buf_set_keymap(self.buf, 'n', '<ESC>', self.close_map.cmd, self.close_map.opts)
    end

    for mode, maps in pairs(self.maps) do
        for _, map in pairs(maps) do
            if map ~= nil then
                vim.api.nvim_buf_set_keymap(self.buf, mode, map.keys, map.cmd, map.opts)
            end
        end
    end
    if self.is_toggleable then
        Window.floats[self.vid] = self
    end
end

function Window.get_window(vid)
    -- Get the current window and buffer
    local buf, filename = nil, nil
    if Window.is_floating(vid) then
        buf = vim.api.nvim_win_get_buf(vid)
        filename = vim.api.nvim_buf_get_name(buf)
    else
        vim.notify('window is not a float')
    end

    return buf, filename
end

function Window.get_win()
    local vid = vim.api.nvim_get_current_win()
    if not Window.is_floating(vid) then
        vim.notify("Current window is not a float.")
        return
    end
    if Window.floats[vid] == nil then
        vim.notify("Current window is not registered as a float.")
        return
    end

    return Window.floats[vid]
end

function Window.get_current()
    -- Get the current window and buffer
    local vid = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(buf)

    return vid, buf, filename
end

-- no link to the file, like in :r filename
function Window:read(filename)
    vim.api.nvim_buf_call(self.buf, function()
        vim.api.nvim_command("edit " .. filename)
    end)
end

function Window.is_floating(vid)
    return vid ~= nil and vim.api.nvim_win_is_valid(vid) and vim.api.nvim_win_get_config(vid).relative ~= ''
end

function Window.snap_down()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.noitfy("Current window is not floating to snap down.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = vim.o.columns - win_config.height
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_up()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap up.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = 0
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_right()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap right.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = vim.o.columns - win_config.width
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_left()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap left.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = 0
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.fullscreen()
    local win_id = vim.fn.win_getid()
    if win_id == nil or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to be in fullscreen.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = 0
    win_config.col = 0
    win_config.width = vim.o.columns
    win_config.height = vim.o.lines
    vim.api.nvim_win_set_config(win_id, win_config)
    Window.floats[win_id].fullscreen = true
end

function Window.open_link()
    local win = Window.get_win()
    local linenr = vim.fn.line('.')
    if win ~= nil then
        win:close()
    else
        vim.notify("Current window is not a float")
        return
    end

    vim.cmd.e(win.map_file_line[linenr].file)
    vim.api.nvim_win_set_cursor(0, { win.map_file_line[linenr].line, 0 })
end

-- should be a buffer function, not window
function Window:set_buf_links(map_file_line)
    self.map_file_line = map_file_line
    vim.api.nvim_buf_set_keymap(self.buf, 'n', '<CR>',
        ':lua katu.nvim.ui.float.Window.open_link()<CR>',
        { noremap = true, silent = true }
    )

    if Window.ns == nil or Window.ns.link == nil then
        Window.set_link_ns()
    end
    local link = Window.ns.link

    local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1

    -- for i=0,N-1 do
    -- vim.api.nvim_buf_clear_namespace(self.buf, link.id, i, i+1)
    -- end

    vim.api.nvim_buf_clear_namespace(self.buf, link.id, 0, -1)

    vim.api.nvim_buf_add_highlight(self.buf, link.id, link.hover.group, cursor_line, 0, -1)

    -- Create an autocommand for updating when cursor moves
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = self.buf,
        callback = function()
            link = Window.ns.link
            -- Clear all highlights first
            vim.api.nvim_buf_clear_namespace(self.buf, link.id, 0, -1)

            local line_count = vim.api.nvim_buf_line_count(self.buf)

            cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
            -- Reapply without cursor highlights
            for i = 0, line_count - 1 do
                if i ~= cursor_line then
                    vim.api.nvim_buf_clear_namespace(self.buf, link.id, i, i + 1)
                end
            end

            -- Get current cursor line

            -- Apply the highlight with cursor on the current line
            vim.api.nvim_buf_add_highlight(self.buf, link.id, link.hover.group, cursor_line, 0, -1)
        end,
    })
end

-- Function to calculate the max width of the content
function Window:get_max_content_width(lines)
    if (type(lines) == 'string') then
        vim.notify("Lines must be a list of strings", vim.log.levels.ERROR)
        error("Lines must be a list of strings")
    end
    if lines == nil or #lines == 0 then
        local buf = self.buf
        if buf == nil then
            buf = 0
        end
        if lines == nil or lines == 0 then
            lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end
    end
    local max_width = 0
    for _, line in ipairs(lines) do
        local len = vim.fn.strdisplaywidth(line) -- Handles wide characters too
        if len > max_width then
            max_width = len
        end
    end
    max_width = max_width + 5
    -- get total number of columns of the neovim



    if max_width > vim.o.columns then
        max_width = vim.o.columns
    end

    return math.floor(max_width)
end

-- generate links in file:number
-- Create a buffer with example links
function Window.setup_buffer_with_links()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Example list of files with line numbers
    local lines = {
        "example.lua:10",
        "another_file.lua:20",
        "yet_another.lua:30"
    }

    -- Set the buffer lines
    Buffer.set_lines(buf, lines)

    -- Define a pattern to match 'filename.lua:number'
    local pattern = [[\v(\S+\.lua):(\d+)]]

    -- vim.api.nvim_set_hl(buf, "Link", { guifg = "red", guibg = "blue" })
    -- Highlight the matching pattern
    vim.fn.matchaddpos("", pattern)

    -- Set the buffer as the current buffer
    vim.api.nvim_set_current_buf(buf)

    -- Set an autocmd to handle opening files when the link is selected
    vim.cmd([[
    augroup FileLinkHandler
      autocmd!
      autocmd CursorMoved <buffer> lua handle_link()
    augroup END
  ]])

    return buf
end

function Window.handle_link()
    -- Get the current line content
    local line = vim.api.nvim_get_current_line()

    -- Match the pattern 'filename.lua:number'
    local pattern = "([^:]+):(%d+)"
    local filename, line_number = string.match(line, pattern)

    if filename and line_number then
        -- Make the link clickable
        vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '', {
            noremap = true,
            silent = true,
            callback = function()
                local win = Window.get_win()
                if win ~= nil then
                    win:close()
                end
                win = Window()
                win:open(filename, tonumber(line_number))
            end
        })
    end
end

function Window.new_id()
    Window.id_count = Window.id_count + 1
    return Window.id_count
end

-- calculate the position of the float window
function Window:get_position()
    local ui_height = self:ui_height()
    local ui_width = self:ui_width()

    local float_width, float_height = self.width, self.height
    local row, col = 0, 0

    if type(self.position) == 'string' then
        if self.position == 'center' then
            col = (ui_width - float_width) / 2
            row = (ui_height - float_height) / 2
        elseif self.position == "top-left" then
            row, col = 1, 0
        elseif self.position == "top-right" then
            row, col = 1, ui_width - float_width
        elseif self.position == "bottom-left" then
            row, col = ui_height - float_height, 0
        elseif self.position == "bottom-right" then
            row, col = ui_height - float_height, ui_width - float_width
        else
            error("Invalid corner specified: " .. (self.position or 'nil'))
        end
    else
        if self.position.relative ~= nil then
            row, col = self.relative.row * ui_height, self.relative.col * ui_width
        elseif self.position.absolute ~= nil then
            row = self.position.absolute.row
            col = self.position.absolute.col
        else
            error('Position not set')
        end
    end

    return row, col
end

function Window:set_position()
    self.row, self.col = self:get_position()
    self.row = math.floor(self.row)
    self.col = math.floor(self.col)
end

function Window:set_content(content)
    if type(content) == 'string' then
        content = utils.split(content, '\n')
    end
    self.content = content
    -- vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, self.content)
end

function Window:redraw()
    local vid
    if not self then
        vid = vim.fn.win_getid()
        self = Window.floats[vid]
        if not self then
            vim.notify("Current window is not a float to be redrawn.")
            return
        end
    end

    self:set_size()
    self:set_position()
    self:set_options()

    vim.api.nvim_win_set_config(self.vid, self:get_config())
end

function Window:fit()
    -- Get the lines of the buffer
    if self.buf == nil then
        vim.notify('No buffer to fit')
        return
    end
    local lines = Buffer.get_lines(self.buf)

    -- Calculate the width (the length of the longest line)
    local width = 0
    for _, line in ipairs(lines) do
        if #line > width then
            width = #line
        end
    end

    self:config({
        style = 'minimal',
        size = {
            flex = true,
        },
        current = false,
        buffer = {
            listed = false,
            scratch = true,
        }
    })
    self:redraw()
end

function Window.flex()
    local win = Window()
    if win == nil then
        vim.notify("Current window is not a float to be toggled.")
        return
    end
    win:config({
        size = {
            flex = true,
        }
    })
    return win
end

function Window.toggle_fullscreen()
    local win_id = vim.fn.win_getid()
    -- local win_config = vim.api.nvim_win_get_config(win_id)
    if Window.floats == nil or Window.floats[win_id] == nil then
        vim.notify("Current window is not a float to be toggled.")
        return
    end
    if Window.floats[win_id].fullscreen then
        Window.floats[win_id].fullscreen = false
        Window:redraw()
    else
        Window.fullscreen()
    end
end

function Window.toggle()
    local vid = vim.fn.win_getid()
    if Window.floats[vid] then
        local win = Window.floats[vid]
        if not win then
            vim.notify("Current window is not a float to be toggled.")
            return
        end
        Window.hidden[win.idx] = win
        win:close()
        Window.floats[vid] = nil
    else
        local n = utils.numel(Window.hidden)
        local win = nil
        local idx = -1
        if n > 0 then
            for i, w in pairs(Window.hidden) do
                idx = i
                win = w
                break
            end
            if win == nil then
                vim.notify("No window to toggle")
                return
            end
            win:open()
            Window.floats[win.vid] = win
            Window.hidden[idx] = nil
        else
            win = Window()
            win:open()
            Window.floats[win.vid] = win
        end
    end
end

Window = _G.class(Window)

function Buffer.set_buf_links(buf, _)
    if Window.ns == nil or Window.ns.link == nil then
        Window.set_link_ns()
    end

    -- Create an autocommand for updating when cursor moves
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            local link = Window.ns.link
            -- Clear all highlights first
            vim.api.nvim_buf_clear_namespace(buf, link.id, 0, -1)

            local line_count = vim.api.nvim_buf_line_count(buf)

            local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
            -- Reapply without cursor highlights
            for i = 0, line_count - 1 do
                if i ~= cursor_line then
                    vim.api.nvim_buf_clear_namespace(buf, link.id, i, i + 1)
                end
            end

            -- Apply the highlight with cursor on the current line
            vim.api.nvim_buf_add_highlight(buf, link.id, link.hover.group, cursor_line, 0, -1)
        end,
    })
end

Window.complete = function(arg, _, _)
    local options = {
        'open',
        'close',
        'toggle',
        'close_all',
        'flex',
        'up',
        'down',
        'right',
        'left',
        'snap_up',
        'snap_down',
        'snap_left',
        'snap_right',
        'fullscreen',
        'toggle_fullscreen',
        'redraw',
        'fit',
    }
    -- These are the valid completions for the command
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg)
    end, options)
end

Window.command = function(args)
    local cmd = args.fargs[1]
    if cmd == nil then
        cmd = 'open'
    end
    if cmd == 'open' then
        local win = Window()
        print('win open: ' .. require'inspect'.inspect(win))
        win:open()
    elseif cmd == 'close' then
        local win = Window.get_win()
        if win ~= nil then
            win:close()
        end
    elseif cmd == 'toggle' then
        Window.toggle()
    elseif cmd == 'close_all' then
        Window.close_all()
    elseif cmd == 'flex' then
        Window.flex()
    elseif cmd == 'up' then
        Window.up()
    elseif cmd == 'down' then
        Window.down()
    elseif cmd == 'right' then
        Window.right()
    elseif cmd == 'left' then
        Window.left()
    elseif cmd == 'snap_up' then
        Window.snap_up()
    elseif cmd == 'snap_down' then
        Window.snap_down()
    elseif cmd == 'snap_left' then
        Window.snap_left()
    elseif cmd == 'snap_right' then
        Window.snap_right()
    elseif cmd == 'fullscreen' then
        Window.fullscreen()
    elseif cmd == 'toggle_fullscreen' then
        Window.toggle_fullscreen()
    elseif cmd == 'redraw' then
        local win = Window.get_win()
        if win ~= nil then
            win:redraw()
        end
    elseif cmd == 'fit' then
        local win = Window.get_win()
        if win ~= nil then
            win:fit()
        end
    end
end

-- create the command
vim.api.nvim_create_user_command("Win",
    function(args)
        Window.command(args)
    end,
    {
        nargs = "*",
        complete = Window.complete,
        bang = true,
        desc = 'Window commands'
    })


-- create mappings for the move functions
-- vim.api.nvim_set_keymap('n', '<C-k>', ':Win snap_up<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<C-j>', ':Win snap_down<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<C-l>', ':Win snap_right<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<C-h>', ':Win snap_left<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'º', ':Win toggle_fullscreen<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'Ç', ':Win toggle<CR>', { noremap = true, silent = true })


local M = {
    Window = Window
}

return M
