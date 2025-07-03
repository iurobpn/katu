local json = require('cjson')
local tbl = require('utils.tbl')
local utils = require('utils')

Project = {
    root_priority = {'main_root', 'git', 'root_files'},
    settings_file = '.settings.json',
    root_dir = nil,
    find_root = {},
    query_user_root = false,
    main_root = '',
    root_files = { -- not tested
        '.root', 'root.tex',
    },
    tables = {},
    excepts = {},
    initialized = false,
}

local mt = {}
function mt:__call()
    if vim ~= nil and vim.g.proj_roots then
        Project.roots_files = vim.g.proj_root_files
    end
    if vim ~= nil and vim.g.proj_root_priority then
        Project.root_priority = vim.g.proj_root_priority
    end
    for _, root in ipairs(Project.root_priority) do
        Project.root_dir = Project.find_root[root](Project[root])
        if Project.root_dir then
            Project.root_dir = Project.root_dir:gsub('/$', '')
            break
        end
    end

    return Project.root_dir
end

setmetatable(Project.find_root, mt)

function Project.init()
    if vim ~=nil and vim.g.enable_project == nil then
        vim.g.enable_project = true
    end
    if vim == nil or not vim.g.enable_project then
        return
    end
    Project.root_dir = Project.find_root()
    if not Project.root_dir then
        print('Project root directory not found')
        return
    else
        print('Project root directory: ' .. Project.root_dir)
        vim.g.root_dir = Project.root_dir
    end

    local filename = Project.root_dir .. '/' .. Project.settings_file
    local fd = io.open(filename, 'r')
    if fd then
        local s = fd:read('*a')
        local settings = nil
        if s and s ~= '' then
            settings = json.decode(s)
            for k, v in pairs(settings) do
                Project[k] = v
            end
        end
        fd:close()
    else
        vim.notify('settings file not found')
    end

    local t_period = 30000
    -- save the settings every 30 s
    vim.defer_fn(function()
        Project.save()
    end, t_period)
    Project.initialized = true
end

function Project.save()
    local filename = Project.root_dir .. '/' .. Project.settings_file
    local settings = {}
    for k, v in pairs(Project) do
        if not utils.is_callable(k) and not utils.is_callable(v) then
            settings[k] = v
        end
    end
    local tables = {}
    for name, tab in pairs(settings.tables) do
        tables[name] = {}
        for k, v in pairs(tab) do
            if not utils.is_callable(k) and not utils.is_callable(v) then
                tables[name][k] = v
            end
        end
        for i, keys in ipairs(Project.excepts) do
            for i, k in ipairs(keys) do
                print(i)
                utils.pprint(k, 'removing key: ')
                tables[name][k] = nil
            end
        end
    end
    settings.tables = tables

    local fd = io.open(filename, 'w')
    if fd then
        vim.notify('saving settings at ' .. filename)
        fd:write(tbl.to_json(settings))
        fd:close()
    else
        vim.notify('Error saving settings')
    end
end

function Project.find_root.main_root(main_root)
    if main_root then
        main_root = main_root:gsub('\n', '')
        return Project.find_root.root_files({main_root})
    else
        return false
    end
end

function Project.find_root.git()
    local cmd = 'git rev-parse --show-toplevel'
    local fd = io.popen(cmd)
    if not fd then
        return false
    end
    local s = fd:read('*a')
    fd:close()

    if string.match(s, 'fatal') then
        return false
    else
        return s:gsub('\n', '')
    end
end

function Project.find_root.root_files(file_list)
    local lfs = require("lfs")
    local home_dir = os.getenv("HOME")
    local current_dir = lfs.currentdir()
    local cdir = current_dir

    while current_dir ~= home_dir and current_dir ~= '/' do
        for _, file in ipairs(file_list) do
            local root_path = current_dir .. '/' .. file

            if require'utils.fs'.file_exists(root_path) then
                lfs.chdir(cdir)
                return current_dir:gsub('\n', '')
            end
        end
        -- Move to the parent directory
        lfs.chdir("..")
        current_dir = lfs.currentdir()
    end
    lfs.chdir(cdir)

    return false
end

function Project.register(name,tab,except)
    Project.tables[name] = tab
    Project.excepts[name] = except
end

function Project.get(name)
    if Project.tables[name] == nil then
        if not Project.initialized then
            Project.init()
            return Project.get(name)
        end

        -- check if file exists

        local filename = Project.root_dir .. '/' .. name
        local fd = io.open(filename, 'r')
        if fd then
            local s = fd:read('*a')
            local tab = json.decode(s)
            Project.tables = tab
            fd:close()
            return Project.tables[name]
        else
            return nil
        end
    else
        return Project.tables[name]
    end
end

return Project
