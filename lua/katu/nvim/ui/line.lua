local NuiLine = require("nui.line")

local line = NuiLine()

line:append("Something Went Wrong!", "Error")

local bufnr, ns_id, linenr_start = 0, -1, 1

line:render(bufnr, ns_id, linenr_start)

