local lfs = require('lfs')
local utils = require('katu.utils')

-- Helper function to check if a file exists
local M = {}

---check if file/folder exists
---@param fname string
---@return boolean
function M.file_exists(fname)
    if type(fname) ~= 'string' then
        print('Filename must be a string', vim.log.levels.ERROR)
        return false
    end
    local fd = io.popen('stat ' .. fname .. ' 2>&1 /dev/null')
    if fd == nil then
        return false
    end
    local out = fd:read('*a')
    if out:find('No such file or directory') then
        return false
    end
    return true
end

---get the filename of the open file in the current buffer
---@return string
function M.get_current_file()
    if vim ~= nil then
        return vim.fn.expand('%:p')
    else
        return ''
    end
end

--- get basename from path, the last part of the path without a /
---@param path string
---@return string
function M.basename(path)
    return M.get_filename(path)
end

---get the file name from the path
---@param path string
---@return string
function M.get_filename(path)
    local parts = utils.split(path, '/')
    return parts[#parts]
end

---get a path from a path/file or path
---@param filepath string
---@return string
function M.get_path(filepath)
    if M.is_dir(filepath) then
        return filepath
    end
    local is_root = filepath:sub(1,1) == '/'
    local parts = utils.split(filepath, '/')
    parts[#parts] = nil
    local out = table.concat(parts, '/')
    out = is_root and '/' .. out or out
    return out
end

---get a path from a path/file or path
---@param filepath string
---@return string
function M.downdir(filepath)
    local is_root = filepath:sub(1,1) == '/'
    if filepath == '/'  then
        return '/'
    end
    local parts = utils.split(filepath, '/')
    if #parts <= 1 then
        return '.'
    end
    parts[#parts] = nil
    local out = table.concat(parts, '/')
    out = is_root and '/' .. out or out
    return out
end

---get the extension of a file
---@param path string
---@return string
function M.get_file_extension(path)
    local parts = utils.split(path, '.')
    return parts[#parts]
end

---check if path string is a directory
---@param path string
---@return boolean
function M.is_dir(path)
    return lfs.attributes(path, 'mode') == 'directory'
end

---check if a path is a file
---@param path string
---@return boolean
function M.is_file(path)
    return lfs.attributes(path, 'mode') == 'file'
end

return M

