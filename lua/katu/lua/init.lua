-- submodules of dev.lua
-- require'utils.lua' -- empty

local lua = {
    proj = require'dev.lua.project',
}
_G.proj = lua.proj
vim.g.proj = lua.proj
vim.g.proj.init()

lua.sqlite    = require'dev.lua.sqlite'
lua.log       = require'dev.lua.log'
lua.zotero    = require'dev.lua.zotero'
lua.templater = require'dev.lua.templater'

return lua
