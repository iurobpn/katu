-- -----------------------------------------
-- Author: Iuro Nascimento
-- Date 2024-09-15 13:05
-- Description: Custom previewer for fzf-lua
-- -----------------------------------------

-- local fzf_lua = require("fzf-lua")
local builtin = require("fzf-lua.previewer.builtin")

local utils = require("utils")
local fs = require("utils.fs")

local M = {}

-- Inherit from "base" instead of "buffer_or_file"
local Previewer = builtin.buffer_or_file:extend()


function Previewer:new(o, opts, fzf_win, ...)--i
    self.has_custom_hl = true

    Previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, Previewer)
    return self
end

function Previewer:populate_preview_buf(entry_str)
    local path, line_nr = utils.get_file_line(entry_str)
    if path == nil then
        vim.notify('Could not get file path from entry_str: ' .. entry_str)
        return
    end

    local tmpbuf = self:get_tmp_buffer()

    self.load_buffer(tmpbuf, path)
    self:set_preview_buf(tmpbuf)

    -- set cursor and cursorline
    local winid = self.win.preview_winid
    vim.api.nvim_win_set_cursor(winid, {line_nr, 0})
    vim.api.nvim_set_option_value('cursorline', true, {win = winid, scope = "local"})
    if self.has_custom_hl then
        print('entry_str: ', entry_str)
        self:set_custom_hl(tmpbuf, line_nr)
    end

    self.set_syntax(winid, path)
end

function Previewer:set_custom_hl(buf, line)

    local entry = vim.api.nvim_buf_get_lines(buf, line-1, line, false)
    
    entry = entry[1]
    if entry == nil then
        print(string.format('could not get line %d from buffer', line))
        return
    end
    local due_date = entry:match("due:: (%d%d%d%d%-%d%d%-%d%d)")
    if due_date == nil then
        print('no due date found')
        return
    end
    vim.api.nvim_set_hl(0, 'MetaTags', { fg = "#818181", italic = true })  -- Adjust the color as needed
    -- Define the namespace for extmarks (you can use the same namespace for multiple extmarks)
    local ns_id = vim.api.nvim_create_namespace('previewer_due')
    -- Create your custom highlight group with color similar to comments

    -- Set virtual text at a given line (line 2 in this case, 0-based index)
    vim.api.nvim_buf_set_extmark(buf, ns_id, line-1, 0, {
        virt_text = { { string.format("(due: %s) ", due_date), "MetaTags" } },  -- Text and optional highlight group
        virt_text_pos = "inline",
        -- virt_text_pos = "eol",  -- Places the virtual text at the end of the line
    })
end

function Previewer.set_syntax(winid,file)
    local ft = fs.get_file_extension(file)
    if ft == 'md' then
        ft = 'markdown'
    end
    -- vim.api.nvim_win_set_option(winid, 'filetype', ft)
    vim.api.nvim_set_option_value('filetype', ft, {win = winid, scope = "local"})
end


function Previewer:set_winopts(opts)
    self.added_winopts = opts
end
-- Disable line numbering and word wrap
function Previewer:gen_winopts()
    local new_winopts = {
        wrap           = false,
        number         = true,
        relativenumber = false,
        cursorline     = true,
        title_pos      = "center",
        -- cursorline        = true,
    }
    self.winopts = vim.tbl_extend("force", self.winopts, new_winopts)
    if self.added_winopts == nil then
        return self.winopts
    end
    return vim.tbl_extend("force", self.winopts, self.added_winopts)
end

function Previewer.load_buffer(tmpbuf, path)
    -- local path = entry_str
    local fd = io.open(path, 'r')
    if fd == nil then
        print('could not open file ' .. path)
        return
    end

    local lines = {}
    local k = 1
    for line in fd:lines() do
        table.insert(lines, line)
        k = k + 1
    end

    vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
    -- vim.cmd('filetype plugin on')
    -- vim.cmd('filetype on')
    -- vim.cmd('syntax on')
    vim.cmd('filetype detect')
end

function Previewer.load_buffer_line(tmpbuf, path, line_nr)
    -- local path = entry_str
    local fd = io.open(path, 'r')
    if fd == nil then
        print('could not open file ' .. path)
        return
    end

    local lines = {}
    local line_c = ' ops, line not selected'
    local k = 1
    for line in fd:lines() do
        if line_nr == line-1 then
            line_c = line
            break
        end
        k = k + 1
    end
    table.insert(lines, line_c)

    vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
    vim.api.nvim_buf_set_name(tmpbuf, path)
end
M.Previewer = Previewer

return M
