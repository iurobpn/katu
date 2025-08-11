local katu = require"katu.config"
katu.lua = require"katu.lua"

-- setup keymaps and commands
katu.setup()

_G.katu = katu
return katu
