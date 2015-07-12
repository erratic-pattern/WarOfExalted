--An unordered collection of keywords that can be associated with abilities and ability damage/effects
WoeKeywords = class({})

--Initializes a new keyword collection based on the given keyword list
--
--A "keyword list" can take 2 forms: either a string of keywords seperated by spaces,
--or an array of keyword strings.
function WoeKeywords:constructor(kWords)
    self.kw = {}
    self:Add(kWords)
end

--Takes a keyword list (see constructor) and adds it to the collection
function WoeKeywords:Add(kWords)
    self:_SetArray(kWords, true)
end

--Takes a keyword list (see constructor) and removes it from the collection
function WoeKeywords:Remove(kWords)
    self:_SetArray(kWords, nil)
end


function WoeKeywords:RemoveAll()
    for kWords, _ in pairs(self.kw) do
        self.kw[kWords] = nil
    end
end

--Updates keywords based on an update table. Example:
--
-- keyWords = WoeKeyWords("attack spell area")                     -- initialized as "attack spell area"
-- keyWords:Update({ aura = true, debuff = true, attack = false }) -- becomes "spell aura debuff"
function WoeKeywords:Update(updateTable)
    for kWord, val in pairs(updateTable) do
        self.kw[kWord] = val or nil
    end
end

--Takes a keyword list (see constructor) and returns true if all keywords are present
function WoeKeywords:HasAll(kWords)
    kWords = WoeKeywords.NormalizeKwList(kWords)
    for _, kWord in ipairs(kWords) do
        if not self.kw[kWord] then
            return false
        end
    end
    return true
end

function WoeKeywords:HasAny(kWords)
    kWords = WoeKeywords.NormalizeKwList(kWords)
    for _, kWord in ipairs(kWords) do
        if self.kw[kWord] then
            return true
        end
    end
    return false
end

--Has is a shorthand for HasAll
WoeKeywords.Has = WoeKeywords.HasAll

--Iterator over all keyword strings
function WoeKeywords:ForAll(cb)
    for kWord, val in pairs(self.kw) do
        if val then
            cb(val)
        end 
    end
end

--Convert collection to an array of strings
function WoeKeywords:AsArray()
    local arr = {}
    for kWord, val in pairs(self.kw) do
        if val then
            table.insert(arr, kWord)
        end
    end
    return arr
end

--Convert collection to a string of words separated by spaces
function WoeKeywords:AsString()
    local str = ""
    for kWord, val in pairs(self.kw) do
        if val then
            if str == "" then
                str = kWord
            else
                str = str .. ' ' .. kWord
            end
        end
    end
    return str
end

--Convert keyword collection to a table representing an unordered set.
--The keys of the table are keywords, and the associated values are booleans
function WoeKeywords:AsTable()
    return util.shallowCopy(self.kw)
end

--Union of multiple keyword collections
function WoeKeywords.Union(...)
    local out = WoeKeywords()
    return out:UnionInPlace(...)
end

--In-place union of keyword collections. First collection in arguments list is updated in-place with keywords from subsequent collections.
function WoeKeywords:UnionInPlace(...)
    for _, kWords in ipairs(arg) do
        for kWord, val in pairs(kWords.kw) do
            if val then
                self.kw[kWord] = true
            end
        end
    end
    return self
end


--Static helper function: Converts "list of keywords" to {"list", "of", "keywords"}
function WoeKeywords.NormalizeKwList(kWords)
    if kWords == nil then
        kWords = { }
    elseif type(kWords) == 'string' then
        kWords = string.split(kWords)
    elseif type(kWords) ~= 'table' then
        print("Warning: Invalid value for WoeKeywords input: ", kWords)
    end
    return kWords
end

--Internal helper for Add/Remove
function WoeKeywords:_SetArray(kWords, val)
    kWords = WoeKeywords.NormalizeKwList(kWords)
    for _, kWord in ipairs(kWords) do
        self.kw[kWord] = val
    end
end
