local M = {}

---get file:line context
---@param filename any
---@param line_num any
---@param size any
---@return string[]|nil
function M.get_context(filename, line_num, size)
    if not filename then
        print('Error: filename is required to get the file context')
        return
    end
    local bufnr
    if not M.is_file_loaded(filename) then
        -- load the file to a new buffer
        bufnr = vim.api.nvim_create_buf(false, true)
        Buffer.load(bufnr, filename)
    else
        bufnr = vim.fn.bufnr(filename)
    end
    if not line_num then
        print('Error: line_num is required to get the file context')
        return
    end
    if not size then
        size = 3
    end

    -- Get the current file context (surrounding lines)
    local context_lines_before = size -- Show 3 lines before the current line
    local context_lines_after = size  -- Show 3 lines after the current line

    local last_line = vim.api.nvim_buf_line_count(bufnr);
    local start_line = math.max(0, line_num - context_lines_before - 1)
    local end_line = math.min(last_line, line_num + context_lines_after)
    local lines  = Buffer.get_lines(bufnr, start_line, end_line)

    return lines
end

--- is_file_loaded
---@param filepath string
---@return boolean
function M.is_file_loaded(filepath)
    -- Get the buffer number for the file (returns -1 if the file is not loaded)
    local bufnr = vim.fn.bufnr(filepath)

    -- Check if the buffer number is valid and if the buffer is listed (loaded)
    if bufnr ~= -1 and vim.fn.buflisted(bufnr) == 1 then
        return true
    end

    return false
end
Buffer = {}

--- test if a map exists
---@param bufnr number
---@param mode characters
---@param lhs string
---@return boolean
function Buffer.mapping_exists(bufnr, mode, lhs)
    local mappings = vim.api.nvim_buf_get_keymap(bufnr, mode)
    for _, map in ipairs(mappings) do
        if map.lhs == lhs then
            return true
        end
    end
    return false
end

--- remove a mapping
---@param bufnr integer
function Buffer.unmap(bufnr)
    local modes = {'n', 'v', 'i', 'x', 's', 'o', 'c', 't'}
    for _,mode in ipairs(modes) do
        local mappings = vim.api.nvim_buf_get_keymap(bufnr, mode)
        for _, map in ipairs(mappings) do
            vim.api.nvim_buf_del_keymap(0, mode, map.lhs)
        end
    end
end

--- number of lines 
---@param buf number
---@return integer
function Buffer.size(buf)
    return vim.api.nvim_buf_line_count(buf)
end

---load a file into a buffer
---@param buf integer
---@param filename string
function Buffer.load(buf,filename)
    if buf ~= nil or not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    if not filename or #filename == 0 then
        error('No filename provided')
        return
    end
    vim.api.nvim_buf_set_name(buf, filename)
    -- read the file using readfile builtin
    local lines = vim.fn.readfile(filename)
    Buffer.set_lines(buf, lines)
end

---append content to a buffer
---@param buf integer
---@param content string[]|string
function Buffer.append(buf, content)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    local line_start = vim.api.nvim_buf_line_count(buf)
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, -1, true, content) -- append to file
end

---set lines in buffer
---@param buf integer
---@param line_start integer
---@param line_end integer
---@param content string[]|string
function Buffer.set_lines(buf, content, line_start, line_end, strict)
    if buf == nil or not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    if line_start == nil then
        line_start = 0
    end
    if line_end == nil then
        line_end = -1
    end
    if strict == nil then
        strict = false
    end
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, line_end, strict, content) -- overwrite file
end

---ensures the content is properly wrapped into a table
---@param content string[]|string
---@return string[]
function Buffer.check_content(content)
    if type(content) == 'string' then
        content = vim.split(content, '\n')
        if type(content) == 'string' then
            content = {content}
        end
    end
    return content
end

---wraps nvim_buf_set_text
---@param buf integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@param content string[]
function Buffer.set_text(buf, start_row, start_col, end_row, end_col, content)
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, content)
end


---creates a new lieted buffer
---@return integer
function Buffer.new()
    return vim.api.nvim_create_buf(true, false)  -- false for listed, true for scratch
end

---comment
---@param content any
---@return integer
function Buffer.scratch(content)
    return vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch
end

function Buffer.delete(buf)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    vim.api.nvim_buf_delete(buf, {force = true})
end

function Buffer.get_lines(buf, start, finish, strict)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    if not start then
        start = 0
    end
    if not finish then
        finish = -1
    end
    if strict == nil then
        strict = false
    end
    return vim.api.nvim_buf_get_lines(buf, start, finish, strict)
end

function Buffer.get_text(buf, start_row, start_col, end_row, end_col)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    return vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col)
end

function Buffer.get_name(buf)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    return vim.api.nvim_buf_get_name(buf)
end

function Buffer.get_option(buf, option)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    return vim.api.nvim_get_option_value(option , { buf = buf})
end

function Buffer.set_option(buf, option, value)
    if not Buffer.is_valid(buf) then
        vim.notify('Buffer is not valid')
        return
    end
    vim.api.nvim_set_option_value(option, value, { buf = buf } )
end

-- checki if buffer is valid
function Buffer.is_valid(buf)
    if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
        return false
    end
    return true
end

function Buffer.set_buf_links(buf, _)
    Window = require'katu.nvim.ui.float'
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

M.Buffer = Buffer

return M
