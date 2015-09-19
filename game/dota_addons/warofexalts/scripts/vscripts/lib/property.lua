DEFAULT_PROPERTY_CACHE_LIFETIME = 0.1 -- the default cache lifetime of a property

DEFAULT_PROPS_KEY = "_props" --default keyname for a unit's internal property table

PROPERTY_VERSION = 0.1
if Property == nil then
    print("[PROPERTY] Creating Property library")
    Property = class({})
end

--Local function declarations (code defined at bottom of file)
local Msg, GetProps, GetCache, CacheTime, TitleCase

function Property.SetDebug(flag, unit, pName)
    --[[ Sets debug mode for a given unit (or globally), providing detailed console output for property behaviors.
    
    Parameters:
        flag  - true or false, indicating whether or not to provide debug messages.
        
        unit  - (optional) the unit to disable/enable debugging on. If nil, sets the global
                debug flag for all units (Note: unit-specific settings take precedence over global settings)
                
        pName - (optional) the name of the property to disable/enable debugging on. If nil, sets the unit's
                debug flag (Note: property-specific settings take precedence over both unit and global settings)
    ]]
    if unit == nil then
        Property.debugMode = flag --global flag
    elseif pName == nil then
        unit._propertyDebugMode = flag -- unit flag
    else
        _InitUnit(unit)
        local cache = GetCache(unit)[pName]
        if cache then
            cache.debugMode = flag
        end
    end
end

function Property:constructor(unit, pName, opts)
    --[[ Adds a custom property to a game unit, providing getter/setter methods as well as providing a mechanism for unit modifiers to transform property values.
        
        Basic Usage:
            Property(myUnit, "myPropertyName")

        Inputs:
            unit: The entity to which we will attach the property (required)
            pName: The name of the property (required)
            opts: a table of configuration parameters (optional)
            
        Options Table Format (all fields are optional):
            default - the initial value for this property
            
            type -  a string indicating the property's type. Controls multiple default behaviors including:
                        * the default property value if the "default" option is not given
                        * the way that computed values from modifiers are combined, if the "combine" option is not given
                    Valid types: number, bool, string
                            
            onChange -  a function that's called when the computed value of the property has changed from its previous value.
                            
                        Input parameters: (unit, newValue, oldValue, propName, opts)
                        
                        Return value: (optional) a replacement value for the property
                            
            combine -   a function describing how property values are computed from modifiers.
                        Essentially, this is a binary operator that is used to sequentially fold all of the values returned by modifiers for this property.
                    
                        Input parameters: (modifier, accumulatedValue, modifierValue)
                    
                        Return value: the desired result of combining accumulatedValue with modifierValue
                    
                        For example, if you wanted to override the default additive behavior of numeric properties and instead use multiplicative, you could define combine like this:
                            Property(myUnit, "multiplicativeProperty", {
                                default = 1,
                                combine = function(modifier, a, b)
                                    return a*b
                                end
                            })
                        
                        For convenience, this multiplicative behavior is provided by the built-in function Property.multiplicative. See the examples below for examples of its usage.
                                
            updateEvent - a string indicating the name of a custom event to send to clients whenever this property's value changed. If not set, we will not automatically
                          send update events to clients.
                          
            modifyEventParams - if the updateEvent option is specified, this option can be a function that will be called just before the event fires, and can be used to modify the events parameters
            
                                Input parameters: (eventName, eventParams, unit)
                                
                                Returns: (optional) a table describing the new event parameters. If no return value, we simply use the original parameter table, complete with any modifications that
                                         the callback made.
                                
            useGameTime - if true, instructs caching behavior to use GetGameTime instead of Time
            
            cacheLifetime - a floating point value representing the time (in seconds) that a cached value is valid.
            
            set - a string specifying a custom name to use for the property's setter function instead of the default, or false to indicate no setter should be created.
            
            get - same behavior as 'set', but for the getter function; expects a string name or false.
            
            debug - a boolean indicating whether or not to display debug messages for this property. This can also be changed with Property.SetDebug (Note: takes precedence over both unit-defined settings and global settings)
                          
        Examples:
            -- An additive numeric property
            Property(unit, "myPropertyName", {
                type = "number"
            })
        
            -- A multiplicative numeric property
            Property(unit, "myPropertyName", {
                type = "number",
                default = 1,
                combine = Property.multiplicative
            })
            
            -- A numeric property that sends an update event to all clients when changed
            Property(unit, "myPropertyName", {
                type = "number",
                onChange = function(unit, newValue, oldValue)
                    CustomGameEventMananger:Send_ServerToAllClients("property_changed", {unitId = unit, value = newValue})
                end
            })
            
            -- Make all properties on this unit, by default, send an update event when changed
            Property.UnitOptions(unit, {
                defaultPropertyOptions = {
                    onChange = function(unit, newValue, oldValue, propName)
                        CustomGameEventMananger:Send_ServerToAllClients("property_changed", {name = propName, unitId = unit, value = newValue})
                    end
                }
            }
            
            -- A boolean flag with custom names for its getter/setter functions
            Property(unit, "CustomBehaviorRequired", {
                type = "bool",
                default = false,
                get = "IsCustomBehaviorRequired",
                set = "RequireCustomBehavior"
            })
            
            -- A boolean flag that will fail if any modifier returns false for it
            Property(unit, "FailIfFalse", {
                type = "bool",
                default = true,
                combine = Property.boolAll
            })
        
            -- A numeric property with no setter function (only modifiers can be used to alter its value)
            Property(unit, "propertyName", {
                type = "number",
                default = 50,
                set = false,
            })
            
            -- A string property that ignores all modifiers (only the setter function can be used to change it)
            Property(unit, "propertyName", {
                type = "string",
                combine = Property.ignoreModifiers,
            })
            
            -- A read-only property
            Property(unit, "readOnlyProperty", {
                default = 50,
                set = false,
                combine = Property.ignoreModifiers,
            })
            
            -- A magic resist stat that behaves like dota armor rating, and automatically updates built-in magic resist when changed.    
            Property(unit, "customMagicResist", {
                type = "number",
                onChange = function(unit, newValue, oldValue)
                    unit:SetBaseMagicalResistanceValue(0.06 * newValue / (1 + 0.06 * newValue))
                end
            })
    ]] 
    Property._HandleOptions(pName, opts, unit)
    return { } --not currently used, but we might return a property handle to the user in the future.
end

function Property.UnitOptions(unit, opts)
    --[[ This function allows specification of unit-wide options that the property system will obey.
        
        Options Table Format (all fields are optional):
            debug - a boolean indicating whether or not we should print debugging messages for this unit.
                    (Note: unit-specified options take precedence over global options, see: Property.SetDebug)
            
            defaultPropertyOptions - a table of default property options to use for properties of this unit.
                                     if the Property() options table for a property on this unit does not define a field, it will
                                     be copied from this table instead.
            
            propsKey - a string that will override the default name for the inner table used to store property values on this unit
    ]]
    unit._propertyDebugMode = opts.debug
    unit._propsKey = opts.propsKey
    unit._propsDefaults = opts.defaultPropertyOptions
end

function Property.ClearCache(unit, pName)
    --[[ Clears the cached value of a unit's property. If no property name is specified, clears all cached properties. 
    ]]
    local clearList
    if pName == nil then
        clearList = GetCache(unit)
    else
        clearList = { GetCache(unit)[pName] }
    end
    for _, cacheEntry in pairs(clearList) do
        cacheEntry.cacheTime = 0
    end
end

function Property.SuppressUpdateEvents(unit, cb, suppressedHandler)
--[[ Runs a callback with all update events suppressed. Suppression will discontinue at the end.
    The optional second callback is a handler called at the end that receives an array of
    the suppressed events.
]]
    --print("SuppressUpdateEvents")
    Property._InitUnit(unit)
    --save a snapshot of previous suppression state, so that we can handle nested SuppressUpdateEvents calls properly
    local previousEvents = unit._suppressedEventsList
    local previousFlag = unit._suppressUpdateEvents     
    --execute the given callback with event suppression enabled, catching all errors
    unit._suppressUpdateEvents = true
    unit._suppressedEventsList = { }
    local errorStatus, res = pcall(cb)
    local suppressed = unit._suppressedEventsList -- store a snapshot of the suppressed events, for use by the suppression handler
    --restore previous suppression state before we were called
    unit._suppressUpdateEvents = previousFlag
    unit._suppressedEventsList = previousEvents
    --rethrow any errors that occured
    if not errorStatus then
        error(res)
    end
    -- if suppression was enabled in outer calling context, aggregate new suppressed events array into old array
    if unit._suppressUpdateEvents then
        for _, event in ipairs(suppressed) do
            table.insert(unit._suppressedEventsList, event)
        end
    -- if suppression was disabled in the outer calling context, execute optional suppressed events handler 
    elseif suppressedHandler ~= nil then
        local errorMsg
        errorStatus, errorMsg = pcall(suppressedHandler, suppressed)
        if not errorStatus then
            error(errorMsg)
        end
    end
    --Return callback result
    return res
end

function Property.BatchUpdateEvents(unit, cb)
    --[[ Aggregates all update events that fire within the callback into single events with combined parameters.
       
        Useful for avoiding unnecessary network usage when updating multiple unit properties simultaneously.
    ]]
    Property._InitUnit(unit)
    return Property.SuppressUpdateEvents(unit, cb, function(suppressed)
        local batchedEvents = { }
        -- aggregate events with the same name into one event
        for _, event in ipairs(suppressed) do
            local batched = batchedEvents[event.name]
            if batched == nil then
                batchedEvents[event.name] = event.params or { }
            else
                for paramName, paramValue in pairs(event.params) do
                    batched[paramName] = paramValue
                end
            end
        end
        for eventName, eventParams in pairs(batchedEvents) do
            Property.SendUpdateEvent(unit, eventName, eventParams)
        end
    end)
end

 
--[[ 
    For convenience, a number of commonly used combinators are provided with this library. 
    These are intended to be passed to the "combine" option for Property definitions. 
]]

--[[ additive numeric behavior. default combinator for properties with the type "number" ]]
function Property.additive(m, a, b)
    return a+b
end

--[[ multiplicative numeric behavior ]]
function Property.multiplicative(m, a, b)
    return a*b
end

--[[ additive boolean behavior. property will be true if any modifier value is true. default combinator for properties with the type "bool" ]]
function Property.boolAny(m, a, b)
    return a or b
end

--[[ multiplicative boolean behavior. property will fail if any modifier value is false. ]]
function Property.boolAll(m, a, b)
    return a and b
end

--[[ concats property strings together. default combinator for properties with the type "string" ]]
function Property.concat(m, a, b)
    return a .. b
end

--[[ Ignores all values returned by modifiers. Only the value attached to the unit itself and modified with the property's setter function will be considered

    This is the default combine behavior for properties with no type specified.
]]
function Property.ignoreModifiers(m, a, b)
    return a
end

--[[ 

    The remaining functions in this module are all used internally, and aren't part of the basic usage API. You probably don't need to ever call them, but they can be
    useful if you wish to override default library behavior for more advanced use cases.

]]

function Property.CheckDebugMode(unit, pName) 
    --[[ Returns a boolean indicating whether or not we are currently printing debug info for the given unit and property.
    
        if unit parameter is nil, checks the global flag only.
        
        if pName parameter is nil, checks the unit flag and global flag.
    ]]
    if unit ~= nil then
        if pName ~= nil then -- check property debug flag first
            local cache = GetCache(unit)
            if cache then
                local entry = cache[pName]
                if entry and entry.debugMode ~= nil then
                    return cache.debugMode
                end
            end
        end
        if unit._propertyDebugMode ~= nil then -- check unit debug flag second
            return unit._propertyDebugMode
        end
    end
    return Property.debugMode -- check global flag last
end 

function Property.SendUpdateEvent(unit, eventName, eventParams)
--[[ Sends an event to client(s) to indicate that stats were changed, respecting event suppression settings.

    If you passed an updateEvent option to the property (or to the unit-wide defaults via Property.UnitOptions), this function is called automatically
    upon changes to a property's value.
    
    However, you may wish to use this function yourself in order to leverage BatchUpdateEvents and SuppressUpdateEvents for
    custom events that aren't associated with the property system. It's in fact possible to use this function along with BatchUpdateEvents
    and SuppressUpdateEvents without even initializing a single property on the unit, so these functions may become a seperate library in the future.

    Parameters:
        unit - the entity associated with this event
        eventName - a string representing the event's name
        eventParams - (optional) a table of event parameters to pass to the client(s)
                      if this table provides a key named "playerID", we will send the event only to that client,
                      otherwise we send to all clients.
]]
    Property._InitUnit(unit)
    eventParams = eventParams or { }
    --eventParams.unit = eventParams.unit or unit:GetEntityIndex()
    --util.printTable(eventParam)
    if unit._suppressUpdateEvents then
        Msg(unit, nil, "SendUpdateEvent", eventName, "SUPPRESSED")
        table.insert(unit._suppressedEventsList, {name = eventName, params = eventParams})
    else
        Msg(unit, nil, "SendUpdateEvent", eventName, "SENDING (playerID: " .. (eventParams.playerID or "(none)") .. ")")
        if Property.CheckDebugMode(unit) then
            util.printTable(eventParams)
        end
        if eventParams.playerID then
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(eventParams.playerID), eventName, eventParams)
        else
            CustomGameEventManager:Send_ServerToAllClients(eventName, eventParams)
        end
    end
end

function Property.PropGetter(pName, opts)
    --[[ Constructs a getter function for a property.

        This is called automatically by the Property() constructor, so you shouldn't need to call this manually in most cases.
    ]]
    return function(unit)
        Property._HandleOptions(pName, opts, unit)
        --util.printTable(opts)
        --Msg(unit, pName, "PropGetter", pName)
        local t = CacheTime(opts.useGameTime)
        local cached = GetCache(unit)[pName]
        local old = cached.value
        if t > cached.cacheTime + opts.cacheLifetime then
            Msg(unit, pName, "PropGetter: fetching new value for ", pName)
            v = Property._ComputeProperty(unit, pName, opts)
            if v ~= old then
                Msg(unit, pName, "PropGetter: property value changed", v, old)
                cached.value = v
                cached.cacheTime = t
                if opts.onChange ~= nil then
                    local changedV = opts.onChange(unit, v, old, pName, opts) or v
                    if changedV ~= nil then
                        v = changedV
                    end
                    cached.value = v
                end
                Property._SendUpdateEvent(unit, pName, v, opts)
            end
        else
            Msg(unit, pName, "PropGetter: fetching cached value for", cached.value)
            v = cached.value
        end 
        return v
    end
end

function Property.PropSetter(pName, opts)
    --[[ Constructs a setter function for a property.

        This is called automatically by the Property() constructor, so you shouldn't need to call this manually in most cases.
    ]]
    return function(unit, v)
        Property._HandleOptions(pName, opts, unit)
        Msg(unit, pName, "PropSetter", v)
        local old = GetProps(unit)[pName]
        if v ~= old then
            GetProps(unit)[pName] = v
            local cached = GetCache(unit)[pName]
            cached.value = cached.value + v - old
            if opts.onChange ~= nil then
                local old2 = v
                local changedV = opts.onChange(unit, v, old, pName, opts)
                if changedV ~= nil then
                    v = changedV
                end
                GetProps(unit)[pName] = v
                cached.value = cached.value + v - old2
            end
            Property._SendUpdateEvent(unit, pName, v, opts)
        end
    end
end

function Property._ComputeProperty(unit, pName, opts)
    --[[ Computes the value of a property based on its base value and the unit's current modifiers.
    
        While this function is called internally by property getters, you might find it useful as it
        completely ignores the cache and always loops over modifiers to obtain the current property value.
    ]]
    Msg(unit, pName, "_ComputeProperty called")
    Property._HandleOptions(pName, opts, unit)
    local out = GetProps(unit)[pName]
    for k, modifier in pairs(unit:FindAllModifiers()) do
        if modifier._propHandlers ~= nil then
            local propHandler = modifier._propHandlers[pName]
            if propHandler ~= nil then
                if type(propHandler) == "function" then
                    local params = { }
                    for k, v in pairs(modifier._params or { }) do
                        params[k] = v
                    end
                    for k, v in pairs(opts.modifierParams or { }) do
                        params[k] = v
                    end
                    out = opts.combine(modifier, out, propHandler(modifier, params))
                else
                    out = opts.combine(modifier, out, propHandler)
                end
            end
        end
    end
    Msg(unit, pName, "_ComputeProperty result = ", out)
    return out
end

function Property._HandleOptions(pName, opts, unit)
    --[[ Fills in option defaults, and initializes the unit's internal state. Called by literally everything else, so there should be no need to use this normally.
    
        If no options table given, constructs a new table from defaults and returns it.
        If no unit given, no unit initialization is performed, but the options table is still constructed.
    ]]
    --Msg(unit, pName, "_HandleOptions")
    opts = opts or { } 
    
    if unit ~= nil then
        Property._InitUnit(unit)
        --initialize unit-defined defaults
        for k, v in pairs(unit._propsDefaults) do
            if opts[k] == nil then
                opts[k] = v
            end
        end
    end  
    
    --getter/setter options handling
    opts.get = opts.get or opts.get == nil
    opts.set = opts.set or opts.set == nil
    if opts.get == true then
        opts.get = "Get" .. TitleCase(pName)
    end
    if opts.set == true then
        opts.set = "Set" .. TitleCase(pName)
    end
    
    --property type handling
    if opts.type == "number" or opts.type == "numeric" then
        if opts.default == nil then
            opts.default = 0
        end
        if opts.combine == nil then
            opts.combine = Property.additive
        end
    elseif opts.type == "string" then
        if opts.default == nil then
            opts.default = ""
        end
        if opts.combine == nil then
            opts.combine = Property.concat
        end
    elseif opts.type == "bool" or opts.type == "boolean" then
        if opts.default == nil then
            opts.default = false
        end
        if opts.combine == nil then
            opts.combine = Property.boolAny
        end
    elseif opts.combine == nil then
        opts.combine = Property.ignoreModifiers
    end
    
    -- cache lifetime handling
    if opts.cacheLifetime == nil then
        opts.cacheLifetime = DEFAULT_PROPERTY_CACHE_LIFETIME
    elseif opts.cacheLifetime == false then
        opts.cacheLifetime = 0
    end
    if opts.cacheLifetime < 0 then
        opts.cacheLifetime = 0
    end
    
    if unit ~= nil then
        -- initialize property with default
        local props = GetProps(unit)
        if props[pName] == nil and opts.default ~= nil then
            props[pName] = opts.default
        end        
        -- initialize cache value
        local cache = GetCache(unit)
        if cache[pName] == nil then
            cache[pName] = {
                value = props[pName],
                cacheTime = 0,
                debugMode = opts.debug
            }
        end
        --define property getter/accessor functions
        if opts.get and unit[opts.get] == nil then
            unit[opts.get] = Property.PropGetter(pName, opts)
        end
        if opts.set and unit[opts.set] == nil then
            unit[opts.set] = Property.PropSetter(pName, opts)
        end  
    end
    return opts
end

function Property._InitUnit(unit)
    --[[ Initializes internal unit state. ]]
    if not unit._propsInitialized then
        unit[unit._propsKey or DEFAULT_PROPS_KEY] = { }
        unit._propsCache = { }
        if unit._propsDefaults == nil then
            unit._propsDefaults = { }
        end
        unit._suppressUpdateEvents = false
        unit._suppressedEventsList = { }
        unit._propsInitialized = true
    end
end

function Property._SendUpdateEvent(unit, pName, value, opts)
    --[[ internal helper used by PropSetter and PropGetter to send update events.
    ]]
    if opts.updateEvent then
        local params = { [pName] = value }
        local outParams
        if opts.modifyEventParams then
            outParams = opts.modifyEventParams(opts.updateEvent, params, unit)
        end
        if outParams == nil then
            outParams = params
        end
        Property.SendUpdateEvent(unit, opts.updateEvent, outParams)
    end
end

--[[ Various local helper/utility functions are defined below. ]]

Msg = function(unit, pName, ...) --debug helper
    if Property.CheckDebugMode(unit, pName) then
        if unit ~= nil then
            print(...)
        else
            print(unit:GetName(), ...)
        end
    end
end

GetProps = function(unit) --helper to retrieve unit's internal property table
    return unit[unit._propsKey or DEFAULT_PROPS_KEY]
end

GetCache = function(unit) --helper to retrieve unit's internal property cache
    return unit._propsCache
end

CacheTime = function(useGameTime) --helper function to retrieve a time value for caching
    if useGameTime then
        return GameRules:GetGameTime()
    else
        return Time()
    end
end

TitleCase = function(str) -- makes first letter of string capital
    return str:gsub("^%l", string.upper)
end