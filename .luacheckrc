local M = {}

if vim ~= nil then
    M.color = false
end

M.globals = {
    'vim',
    'dev',
    'Snacks',
    "inspect",
    "hs",
    "it",
    "describe",
    "before_each",
    "after_each"
}

return M
