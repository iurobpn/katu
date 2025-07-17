local katu = {
    color = vim.g.gruvbox_palette,
    lua = require('katu.lua'),
    nvim = require('katu.nvim'),
}
_G.katu = katu
return katu
