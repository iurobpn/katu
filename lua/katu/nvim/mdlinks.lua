local M = {
    keymap = {
        mode = 'n',
        keys = 'gf'
    }
}
local function get_mdlink()
    local current_word = vim.fn.expand("<cWORD>")
    print("Current word: " .. current_word)
    -- match againt the pattern for obsidian markdown links
    local pattern = "%[%[([^|]*).*%]%]"
    local match = string.match(current_word, pattern)
    if match then
        local _, _, file = string.find(current_word, pattern)
        -- if a match is found, return the link
        -- io.popen("fd " .. file " -H 2>&1")
        -- use fd to search for the file in the current directory
        local handle = io.popen("fd " .. file .. " -H -tf 2>&1")
        local res = handle:read("*a")
        if handle == nil then
            return ""
        end
        handle:close()
        return res
    else
        -- if no match is found, return an empty string
        return ""
    end
end

function M.open_mdlink()
    local link = get_mdlink()
    if link == "" then
        vim.cmd('normal ' .. M.keymap.keys)
        return
    end
    files = require'katu.utils'.split(link, "\n")
    if #files == 0 then
        vim.cmd('normal ' .. M.keymap.keys)
        return
    end
    if #files > 1 then
        -- if there are multiple files, ask the user to choose one
        require'katu.nvim.fzf'.run(
            {
                source = files,
                sink = function(file)
                    vim.cmd("edit " .. file)
                end,
                options = '--prompt="Select files> "'
            })
    else
        vim.cmd("edit " .. files[1])
    end
end

vim.api.nvim_set_keymap(
    M.keymap.mode,
    M.keymap.keys,
    ":lua require'mdlinks'.open_mdlink()<CR>",
    { noremap = true, silent = true, desc = "Open markdown link" }
)

return M
