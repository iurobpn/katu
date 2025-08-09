local M = {
    source_dir = os.getenv('HOME') .. '/git/nmpc-obs/cpp',
    build_dir = 'build/Release',
    configs = {}
}

-- Checks if there is a CMakePresets.json or CMakeUserPresets.json file
-- in the current directory, a CMakeUserPresets.json is
-- preferred over CMakePresets.json as CMakePresets.json
-- is implicitly included by CMakeUserPresets.json
function M.check(cwd)
    -- helper function to find the config file
    -- returns file path if found, nil otherwise
    local function findcfg()
        local files = vim.fn.readdir(cwd)
        local file = nil
        local presetFiles = {}
        local Path = require("plenary.path")
        for _, f in ipairs(files) do -- iterate over files in current directory
            if
                f == "CMakePresets.json"
                or f == "CMakeUserPresets.json"
                or f == "cmake-presets.json"
                or f == "cmake-user-presets.json"
            then -- if a preset file is found
                presetFiles[#presetFiles + 1] = tostring(Path:new(cwd, f))
            end
        end
        table.sort(presetFiles, function(a, b)
            return a < b
        end)
        if #presetFiles > 0 then
            file = presetFiles[#presetFiles]
        end
        return file
    end

    local file = findcfg() -- check for config file

    return file
end

function M.get_build_type(preset)
    return preset.configurePresets[1].cacheVariables.CMAKE_BUILD_TYPE or 'nil'
end

function M.get_build_dir(preset)
    return preset.configurePresets[1].binaryDir
end

M.get_preset_file = function(source_dir)
    return M.check(source_dir)
end

function M.decode(file)
    if file == nil then
        vim.notify("Could not find preset file")
        return
    end
    local fd = io.open(file, 'r')
    if fd == nil then
        vim.notify(string.format("Could not open file %s", file))
    end
    local str = fd:read('*a')
    local json = require "dkjson"
    return json.decode(str)
end

function M.get_build_preset(preset)
    return {
        name = preset.buildPresets[1].name,
        build_dir =M. get_build_dir(preset),
        jobs = preset.buildPresets[1].jobs
    }
end


function M.get_configure_preset(preset)
    return {
        name = preset.configurePresets[1].name,
        description = preset.configurePresets[1].description,
        build_dir = M.get_build_dir(preset),
        build_type = M.get_build_type(preset),
        generator = preset.configurePresets[1].generator,
        toolchain_file = preset.configurePresets[1].toolchainFile
    }
end


-- cmake -S /path/to/source --preset=ninja-release
-- cmake --build . --target myexe
-- cmake --build . --target myexe --config Release
M.get_configs = function(source_dir)
    if source_dir == nil or source_dir == '' then
        return
    end
    local configs = {}
    local presets = M.decode(M.get_preset_file(source_dir))
    if presets == nil or presets.include == nil then
        return
    end

    for _, file in ipairs(presets.include) do
        if file:match('cmake') == nil and file:match('TracyClient') == nil then
            file = source_dir .. '/' .. file
            local preset = {
                file = file
            }

            local js = M.decode(file)
            local ppath = require'katu.utils.fs'.get_path(file)
            preset.path = ppath
            preset.source_dir = source_dir

            preset.build = M.get_build_preset(js)
            preset.configure = M.get_configure_preset(js)
            print('Config name: '.. preset.configure.name)

            table.insert(configs, preset)
        end
    end
    return configs
end

M.check_str = function(str)
    return str ~= nil and #str > 1
end

M.build_cmd = function(preset)
    local cmd = 'cmake'
    if M.check_str(preset.source_dir) then
        cmd = cmd .. ' -S ' .. preset.source_dir    
    end
    if M.check_str(preset.build.build_dir) then
        cmd = cmd .. ' -B ' .. preset.build.build_dir
    end
    if M.check_str(preset.configure.generator) then
        cmd = cmd .. ' -G "' .. preset.configure.generator .. '"'
    end
    if M.check_str(preset.configure.build_type) then
        cmd = cmd .. ' -DCMAKE_BUILD_TYPE=' .. preset.configure.build_type
    end
    if M.check_str(preset.configure.toolchain_file) then
        cmd = cmd .. ' -DCMAKE_TOOLCHAIN_FILE=' .. preset.configure.toolchain_file
    end

    return cmd
end

function M.get_targets(buildDir)
    -- Function to read the entire content of a file
    local function readFile(filename)
        local f = io.open(filename, "rb")
        if not f then
            return nil
        end
        local content = f:read("*all")
        f:close()
        return content
    end

    -- Function to create a directory if it doesn't exist
    local function createDir(path)
        local sep = package.config:sub(1,1)
        if sep == "\\" then
            os.execute('mkdir "'..path..'" >NUL 2>NUL')
        else
            os.execute('mkdir -p "'..path..'"')
        end
    end

    buildDir = buildDir or 'build/Debug'
    -- Create the build directory if it doesn't exist
    local attr = require'lfs'.attributes(buildDir)
    if not attr or attr.mode ~= "directory" then
        createDir(buildDir)
    end

    -- Create the CMake API query directory and file
    local queryDir = buildDir .. "/.cmake/api/v1/query"
    createDir(queryDir)
    local queryFile = queryDir .. "/codemodel-v2"
    local f = io.open(queryFile, "w")
    if f then
        f:close()
    else
        print("Error: Could not create query file " .. queryFile)
        os.exit(1)
    end

    -- Run CMake to generate the JSON files
    local lfs = require'lfs'
    local currentDir = lfs.currentdir()
    lfs.chdir(buildDir)
    local res = os.execute("cmake " .. currentDir .. ' >NUL  2>NUL ')
    if res ~= 0 then
        print("Error: CMake configuration failed")
        os.exit(1)
    end
    lfs.chdir(currentDir)

    -- Find the index file generated by CMake
    local replyDir = buildDir .. "/.cmake/api/v1/reply"
    local indexFileName = nil
    for file in lfs.dir(replyDir) do
        if file:match("^index%-.+%.json$") then
            indexFileName = file
            break
        end
    end
    if not indexFileName then
        print("Error: Index file not found in " .. replyDir)
        os.exit(1)
    end

    -- Read and parse the index file
    local indexFilePath = replyDir .. "/" .. indexFileName
    local indexContent = readFile(indexFilePath)
    if not indexContent then
        print("Error: Could not read index file " .. indexFilePath)
        os.exit(1)
    end
    local json = require "dkjson"
    local indexData = json.decode(indexContent)
    if not indexData then
        print("Error: Could not parse index file " .. indexFilePath)
        os.exit(1)
    end

    -- Locate the codemodel file from the index data
    local codemodelFileName = nil
    for key, obj in pairs(indexData.reply) do
        if key:match('^codemodel') then
            codemodelFileName = obj.jsonFile
            break
        end
    end
    if not codemodelFileName then
        print("Error: Codemodel file not found in index.json")
        os.exit(1)
    end

    -- Read and parse the codemodel file
    local codemodelFilePath = replyDir .. "/" .. codemodelFileName
    local codemodelContent = readFile(codemodelFilePath)
    if not codemodelContent then
        print("Error: Could not read codemodel file " .. codemodelFilePath)
        os.exit(1)
    end
    local json = require "dkjson"
    local codemodelData = json.decode(codemodelContent)
    if not codemodelData then
        print("Error: Could not parse codemodel file " .. codemodelFilePath)
        os.exit(1)
    end

    -- Extract the list of targets from the codemodel data
    local targets = {}
    for _, config in ipairs(codemodelData.configurations) do
        for _, target in ipairs(config.targets) do
            table.insert(targets, target.name)
        end
    end

    return targets
end

function M.get_all()
    -- get current dir
    local current_dir = require'lfs'.currentdir()
    M.configs = M.get_configs(current_dir)
    M.targets = M.get_targets()
    return  M.configs, M.targets
end

-- Output the list of targets
M.print = function(configs,targets)
    print("\nTargets found in the C++ project:")
    for _, targetName in ipairs(targets) do
        print("- " .. targetName)
    end
    local preset = configs[#configs]
    print(vim.inspect(configs))
    local cmd = M.build_cmd(preset)
    print(cmd)
end




return M

