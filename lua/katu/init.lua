local katu = {
    color = vim.g.gruvbox_palette,
    lua = require('dev.lua'),
    nvim = require('dev.nvim'),
}
_G.katu = katu
return katu
