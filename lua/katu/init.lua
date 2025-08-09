local katu = {
    color = require'katu.gruvbox-colors',
    lua = require('katu.lua'),
    nvim = require('katu.nvim'),
}

-- setup keymaps and commands
require'katu.nvim.mdlinks'

_G.katu = katu
return katu
