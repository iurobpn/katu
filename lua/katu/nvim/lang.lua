local M = {
    current = "en",
    levels = {
        "new",
        "recognized",
        "familiar",
        "learned",
        "known",
    },

    words = {

    },

    languages = {
        en = {},

    }
}

-- Word structure
local Word = {
    name = "",
    level = 1,
    language = "",
    translation = "",
    notes = "",
    tags = {},
    examples = {}
}

Word = _G.class(Word)


M.new_lang = function(name)
    M.languages[name] = {}
end

M.new_word = function(name, level, language, translation, notes, tags, examples)
    if name == nil or name == '' then
        vim.notify("Word name cannot be nil or empty")
        return
    end
    local word = Word()
    word.name = string.lower(name)
    word.level = level
    word.language = language
    word.translation = translation
    word.notes = notes
    word.tags = tags
    word.examples = examples

    if language == nil then
        language = M.current
    end
    M.languages[language][word.name] = word
end



M.update_word = function(name)
    name = string.lower(name)
    local word = M.languages[M.current][name] or Word()

    word.name = name
    vim.ui.select(M.levels, { prompt = word.name .. '> ' }, function(selected)
        if selected == nil then
            return
        end
        word.level = selected
    end)
    vim.ui.input({ prompt = word.name .. " translation> " }, function(translation)
        if translation == nil then
            return
        end
        word.translation = translation
    end)
end




