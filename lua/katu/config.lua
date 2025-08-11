local katu = {}

--- katu configuration with its default values.
---
---@type table
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
katu.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
}

---@private
local defaults = vim.deepcopy(katu.options)

--- Defaults katu options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |katu.options|.
---
---@private
function katu.defaults(options)
    katu.options =
        vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

    -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
    assert(
        type(katu.options.debug) == "boolean",
        "`debug` must be a boolean (`true` or `false`)."
    )

    return katu.options
end

--- Define your katu setup.
---
---@param options table Module config table. See |katu.options|.
---
---@usage `require("katu").setup()` (add `{}` with your |katu.options| table)
function katu.setup(options)
    katu.options = katu.defaults(options or {})

    require"katu.commands"
    require"katu.keymaps"
    katu.color = require'katu.gruvbox-colors'
    -- log.warn_deprecation(katu.options)
    --
    local proj = require'katu.lua.project'
    _G.proj = proj
    vim.g.proj = proj
    vim.g.proj.init()

    return katu.options
end

return katu
