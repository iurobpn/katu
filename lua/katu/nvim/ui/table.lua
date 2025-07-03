local NuiTable = require("nui.table")
local Text = require("nui.text")
--
open_treesitter_query_files_browser()
-- create a new buffer
bufnr = vim.api.nvim_create_buf(false, true)
--create a new window with this buffer
local win = vim.api.nvim_open_win(bufnr, true, {
  relative = "editor",
  width = 50,
  height = 10,
  row = 5,
  col = 5,
  style = "minimal",
})
local tbl = NuiTable({
  bufnr = bufnr,
  columns = {
    {
      align = "center",
      header = "Name",
      columns = {
        { accessor_key = "firstName", header = "First" },
        {
          id = "lastName",
          accessor_fn = function(row)
            return row.lastName
          end,
          header = "Last",
        },
      },
    },
    {
      align = "right",
      accessor_key = "age",
      cell = function(cell)
        return Text(tostring(cell.get_value()), "DiagnosticInfo")
      end,
      header = "Age",
    },
  },
  data = {
    { firstName = "John", lastName = "Doe", age = 42 },
    { firstName = "Jane", lastName = "Doe", age = 27 },
  },
})

tbl:render()

