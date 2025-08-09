local templater = require 'lustache'
local fs = require'katu.utils.fs'

local M = {
    templater = templater,
    templates = nil,
    config = {
        template_dir = os.getenv('HOME') .. '.config/nvim/templates',
    },
}

M.templates = {
    author  = 'Iuro Nascimento',
    email = 'iuro@ufmg.br',

    Today = function()
        return os.date('%A %d %B %Y')
    end,

    today = function()
        return os.date('%Y-%m-%d')
    end,

    year  = function()
        return os.date('%Y')
    end,

    month = function()
        return os.date('%m')
    end,

    day   = function()
        return os.date('%d')
    end,

    time  = function()
        return os.date('%H:%M:%S')
    end,

    date  = function()
        return os.date('%Y-%m-%d %H:%M:%S')
    end,

    root = M.config.template_dir,
}

M.templates.reminders = function()
    local today = os.date('%a')
    local templ

    if today == "Sun" or today == "Sat" then
        templ = 'weekend.tpl'
    else
        templ = 'workday.tpl'
    end

    local filename
    if M.templates.root == '' then
        filename = templ
    else
        filename = M.templates.root .. '/' .. templ
    end

    local file = io.open(filename)
    if not file then
        print(string.format('File %s does not exist', filename))
        return ''
    end

    local file_content = file:read('*a')
    file:close()
    return M.templater:render(file_content, M.templates)
end

-- local uv = vim.loop
--
-- -- The folder to watch for new files (modify to your desired folder)
-- local folder_to_watch = "/path/to/your/folder"
--
-- -- The template to insert when a new file is created
-- local daily_tasks_template = [[
-- # Daily Tasks for %s
--
-- - [ ] Task 1
-- - [ ] Task 2
-- - [ ] Task 3
--
-- ]]

-- Function to insert the template
function M.insert_template(filepath)
    -- Get the current date
    local date = os.date("%Y-%m-%d")

    -- Open the new file
    local new_file = io.open(filepath, "w")

    if new_file then
        -- Write the template with the current date
        new_file:write(string.format(daily_tasks_template, date))
        new_file:close()
    else
        print("Could not open file:", filepath)
    end
end

-- Function to watch for file creation in the specified folder
function M.watch_folder_for_new_files()
    local handle = uv.new_fs_event()
    if handle == nil then
        print("Failed to create file watcher")
        return
    end

    -- Start watching the folder
    uv.fs_event_start(handle, folder_to_watch, {}, function(err, filepath, event)
        if err then
            print("Error watching folder:", err)
            return
        end

        -- Check if the event is a file creation event
        if event == "create" and filepath then
            if filepath[1] ~= "/" then
                if filepath[1] == '.' then
                    filepath = folder_to_watch .. "/" .. filepath.sub(3)
                end
                filepath = folder_to_watch .. "/" .. filepath
            end

            local today os.date("%Y-%m-%d.md")
            local filename = fs.get_filename(filepath)

            if filename == today then
                -- check if the file is loaded in a buffer
                if vim.fn.bufexists(filepath) == 1 then
                    -- get the buffer number
                    local bufnr = vim.fn.bufnr(filepath)

                    -- get the window number
                    local winnr = vim.fn.bufwinnr(bufnr)

                    -- switch to the window
                    vim.cmd(winnr .. 'wincmd w')
                end

                vim.cmd('normal! G')
                vim.api.nvim_put({''}, 'l', true, false) -- add a line below the current line
                M.expand_file(M.config.template_dir .. '/daily.tpl')
            end

            vim.notify("Today daily file created: ", filepath)
        end
    end)

    vim.notify("Watching folder:", folder_to_watch)
end



-- create a command to insert the template
-- :lua require('templater').insert_template()
function M.expand(text)
    text = M.pre_escape(text)
    -- print('text: ', text)
    text = M.templater:render(text, M.templates)
    text = M.de_escape(text)
    return text
end

function M.de_escape(text)
    local lines = require'katu.utils'.split2(text, '\n')
    for i, line in ipairs(lines) do
        local line, count = line:gsub('%[%[(jq.?:.*)%]%]', '{{%1}}')
        if count > 0 then
            lines[i] = line
        end
    end
    text = table.concat(lines, '\n')
    return text
end

function M.pre_escape(text)
    local lines = require'katu.utils'.split2(text, '\n')
    for i, line in ipairs(lines) do
        local line, count = line:gsub('{{(jq.?:.*)}}', '[[%1]]')
        if count > 0 then
            lines[i] = line
        end
    end
    text = table.concat(lines, '\n')
    return text
end


function M.get_expanded_file(template_file)
    if template_file == nil or template_file == '' then
        require'fzf-lua'.fzf_exec('fd . -tf ' .. M.templates.root, {
            prompt = 'Select> ',
            actions = {
                ['default'] = function(selected)
                    M.get_expand_file(selected[1])
                end,
            },
        })

        return
    end

    local file = io.open(template_file, 'r')
    if file == '' or file == nil or not file then
        print(string.format('Template file %s does not exist', template_file))
        return ''
    end

    local file_content = file:read("*all")
    file:close()

    local content = require'katu.utils'.split2(M.expand(file_content), '\n')
    if type(content) == 'string' then
        content = {content}
    end

    return content
end

function M.expand_file(template_file)
    if template_file == nil or template_file == '' then
        print('template_file is nil')
        require'fzf-lua'.fzf_exec('fd . -tf ' .. M.templates.root, {
            prompt = 'Select> ',
            actions = {
                ['default'] = function(selected)
                    -- print('selected: ', selected[1])
                    M.expand_file(selected[1])
                end,
            },
        })

        return
    end

    local file = io.open(template_file, 'r')
    if file == '' or file == nil or not file then
        print(string.format('Template file %s does not exist', template_file))
        return ''
    end

    local file_content = file:read("*all")
    file:close()

    local content = require'katu.utils'.split2(M.expand(file_content), '\n')
    if type(content) == 'string' then
        content = {content}
    end

    if vim then
        return vim.api.nvim_put(content, 'l', true, false)
    else
        return content
    end
end

vim.api.nvim_create_user_command('TemplIns', function(opt)
    M.expand_file(opt.args)
end, {nargs='?'})

return M
