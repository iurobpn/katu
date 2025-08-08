-- submodules of katu.lua

local lua = {
    proj = require'katu.lua.project',
}
_G.proj = lua.proj
vim.g.proj = lua.proj
vim.g.proj.init()

lua.sqlite    = require'katu.lua.sqlite'
lua.log       = require'katu.lua.log'
lua.zotero    = require'katu.lua.zotero'
lua.templater = require'katu.lua.templater'

return lua
