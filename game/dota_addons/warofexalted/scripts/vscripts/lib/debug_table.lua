--[[ 
    
    AUTHOR: Adam Curtis, Copyright 2015
    CONTACT: kallisti.dev@gmail.com
    
    A utility module providing debugging tools for tables
    
    Basic Usage:
        DebugTable.Start(myTable, "tableName")
        DoSomeStuffWith(myTable) -- all table operations will be recorded to console
        DebugTable.Stop(myTable)
    
]]

if DebugTable == nil then
    DebugTable = { }
end
DebugTable.VERSION = 0.1

local _DebugTable -- local helper function(s) (defined near the end of the file)


function DebugTable.Start(t, name)
    --[[ Enables debugging information for the given table.
    
        Usage:  DebugTable.Start(myTable, "tableName")
        
        After the call, all usage of myTable will be recorded to console.
    ]]
    return _DebugTable(t, {}, name)
end

function DebugTable.Stop(t)
    --[[ Disables debug messages from the given table
    ]]
    if DebugTable.Check(t) then
        getmetatable(t):undebug()
    else
        print("WARNING: DebugTable.Undo called on invalid input. Ignoring.")
    end
end


function DebugTable.Check(t)
    --[[ Checks if a given value is a table being debugged.
    ]] 
    return t ~= nil and type(t) == "table" and type(getmetatable(t)) == "table" and getmetatable(t).isDebugTable
end


function DebugTable.Proxy(t, name)
    --[[ Similar to DebugTable.Start, except rather than modifying the metatable of the original table,
        we instead return a proxy table who defers all its table operations to the original table.
        
        The key difference here is that accessing the original table will not produce any console messages, but accessing the returned
        proxy table will. Aside from that, the proxy table should act just like a normal reference to the original table.
        
        If you want to log almost all usage of the table regardless of context, use DebugTable.Start. If you want to target debugging messages to a 
        specific area of your code, use DebugTable.Proxy
    ]]
    return _DebugTable({}, t, name)
end



_DebugTable = function(outer, inner, name)
    --[[ Internal implementation of both DebugTable.Start and DebugTable.Proxy ]]
    if DebugTable.Check(outer) then
        DebugTable.Stop(outer)
    elseif DebugTable.Check(inner) then
        DebugTable.Stop(inner)
    end
    
    name = name or outer.__debugTableName or "table"
    
    --construct the inner table where we actually store keys
    for k,v in pairs(outer) do
        inner[k] = v
    end
    local innerMeta = getmetatable(outer)
    if innerMeta == nil then
        innerMeta = { }
    else
        setmetatable(inner, innerMeta)  -- inner table gets old metatable (Note: this will error is inner has protected metatable)
    end
    -- set new metatable
    setmetatable(outer, {
        isDebugTable = true,
        
        debugName = name,
        
        undebug = function(self)  -- calling this will reset the table
            print("undebug", type(innerMeta))
            setmetatable(outer, innerMeta)
            for k, v in pairs(inner) do
                outer[k] = v
            end
        end,
        
        __index = function(_, key) -- key access
            local val = inner[key]
            print(name .. " access: ", key, "->", val)
            return val
        end,
        
        __newindex = function(_, key, val) --key update 
            print(name .. "update:", key, "<-", val)
            inner[key] = val
        end,
        
        --binary operators (TODO: log these perhaps?)
        __add = innerMeta.__add,
        __sub = innerMeta.__sub,
        __mul = innerMeta.__mul,
        __div = innerMeta.__div,
        __mod = innerMeta.__mod,
        __unm = innerMeta.__uhm,
        __pow = innerMeta.__pow,
        __concat = innerMeta.__concat,
        __le = innerMeta.__le,
        __lt = innerMeta.__lt,
        __eq = innerMeta.__eq,
        
        --events / built-in operations
        
        --Note: this is not supported for tables in Lua < 5.2
        __len = innerMeta.__len or function(_)
            return #inner
        end,
        
        __tostring = innerMeta.__tostring or function(_)
            return tostring(inner)
        end,
        
        --Note: __pairs and __ipairs are not available in Lua versions < 5.2, but we provide a workaround at the bottom of the file
        __pairs = innerMeta.__pairs or function(_, ...)
            return pairs(inner, ...)
        end,
        
        __ipairs = innerMeta.__ipairs or function(_, ...)
            return pairs(inner, ...)
        end        
    })
    return outer
end

--override ipairs and pairs to support metamethods in Lua 5.1 (this is a feature supported in Lua 5.2, so if Valve ever updates their Lua interpreter this won't be needed)
if __VERSION == "Lua 5.1" and not _baregrillsLuaOverride then
    local _pairs, _ipairs = pairs, ipairs
    function pairs(t, ...)
        return (getmetatable(t).__pairs or _pairs)(t, ...) 
    end
    function ipairs(t, ...)
        return (getmetatable(t).__ipairs or _ipairs)(t, ...)
    end
        
    _baregrillsLuaOverride = true
end
