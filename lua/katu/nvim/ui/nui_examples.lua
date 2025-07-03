local NuiTable = require("nui.table")
local Text = require("nui.text")
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event
local Popup = require("nui.popup")
local Layout = require("nui.layout")
local Input = require("nui.input")
local Split = require("nui.split")
local Line = require("nui.line")
local Tree = require("nui.tree")

function tree(buf)
    if not buf then
        buf = vim.api.nvim_create_buf(false, true)
    end
    local tree = Tree({
        bufnr = buf,
        nodes = {
            Tree.Node({ text = "a" }),
            Tree.Node({ text = "b" }, {
                Tree.Node({ text = "b-1" }),
                Tree.Node({ text = { "b-2", "b-3" } }),
            }),
        },
    })

    tree:render()
end

function line()
    local line = Line()

    line:append("Something Went Wrong!", "Error")

    local bufnr, ns_id, linenr_start = 0, -1, 1

    line:render(bufnr, ns_id, linenr_start)
end

function tble(buf)
    if not buf then
        buf = vim.api.nvim_create_buf(false, true)
    end

    local tbl = NuiTable({
        bufnr = buf,
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
                    return tostring(cell.get_value())
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
    return tbl
end

function layout_popup()
    local popup_one, popup_two = Popup({
        enter = true,
        border = "rounded",
    }), Popup({
        border = "rounded",
    })

    local layout = Layout(
        {
            position = "50%",
            size = {
                width = 80,
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box(popup_one, { size = "40%" }),
            Layout.Box(popup_two, { size = "60%" }),
        }, { dir = "row" })
    )

    local current_dir = "row"

    popup_one:map("n", "r", function()
        if current_dir == "col" then
            layout:update(Layout.Box({
                Layout.Box(popup_one, { size = "40%" }),
                Layout.Box(popup_two, { size = "60%" }),
            }, { dir = "row" }))

            current_dir = "row"
        else
            layout:update(Layout.Box({
                Layout.Box(popup_two, { size = "60%" }),
                Layout.Box(popup_one, { size = "40%" }),
            }, { dir = "col" }))

            current_dir = "col"
        end
    end, {})

    layout:mount()
    return layout
end

function popup()

    local popup = Popup({
        enter = true,
        focusable = true,
        border = {
            style = "rounded",
        },
        position = "50%",
        size = {
            width = "80%",
            height = "60%",
        },
    })

    -- mount/open the component
    popup:mount()

    -- unmount component when cursor leaves buffer
    popup:on(event.BufLeave, function()
        popup:unmount()
    end)

    -- set content
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, { "Hello World" })
end


-- create a new input component
function input()
    local input = Input({
        position = "50%",
        size = {
            width = 20,
        },
        border = {
            style = "single",
            text = {
                top = "[Howdy?]",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
            prompt = "> ",
            default_value = "Hello",
            on_close = function()
                print("Input Closed!")
            end,
            on_submit = function(value)
                print("Input Submitted: " .. value)
            end,
        })

    -- mount/open the component
    input:mount()

    -- unmount component when cursor leaves buffer
    input:on(event.BufLeave, function()
        input:unmount()
    end)
    return input
end

function menu()
    local menu = Menu(
        {
            position = "50%",
            size = {
                width = 25,
                height = 5,
            },
            border = {
                style = "single",
                text = {
                    top = "[Choose-an-Element]",
                    top_align = "center",
                },
            },
            win_options = {
                winhighlight = "Normal:Normal,FloatBorder:Normal",
            },
        },
        {
            lines = {
                Menu.item("Hydrogen (H)"),
                Menu.item("Carbon (C)"),
                Menu.item("Nitrogen (N)"),
                Menu.separator("Noble-Gases", {
                    char = "-",
                    text_align = "right",
                }),
                Menu.item("Helium (He)"),
                Menu.item("Neon (Ne)"),
                Menu.item("Argon (Ar)"),
            },
            max_width = 20,
            keymap = {
                focus_next = { "j", "<Down>", "<Tab>" },
                focus_prev = { "k", "<Up>", "<S-Tab>" },
                close = { "<Esc>", "<C-c>" },
                submit = { "<CR>", "<Space>" },
            },
            on_close = function()
                print("Menu Closed!")
            end,
            on_submit = function(item)
                print("Menu Submitted: ", item.text)
            end,
        })

    -- mount the component
    menu:mount()

    return menu
end

function nui_split()
    local split = Split({
        relative = "editor",
        position = "bottom",
        size = "20%",
    })

    -- mount/open the component
    split:mount()

    -- unmount component when cursor leaves buffer
    split:on(event.BufLeave, function()
        split:unmount()
    end)
end

