--[[ 
    AUTHOR: Adam Curtis, Copyright 2015
    CONTACT: kallisti.dev@gmail.com
    WEBSITE: https://github.com/kallisti-dev/baregrills
    
    A library for adding a sophsticated set of event-driven properties to game entities. Features include:
    
        * Automatic generation of getter/setter methods on entities
        * Transparent event-driven computation of property values that allows you to easily make dynamic modifications via Lua modifiers.
        * Automatic (and optional) update events that are sent to the client when a property changes, if desired.
        * Event hooks allowing you to execute custom logic when a property changes.
        * Optional caching of computed property values, to improve performance and to prevent infinite recursion in event handlers.
        * Creation of "derived properties" that are automatically updated whenever their subproperties are.
        * Extensive debugging options allowing you to specify which entities, which properties, and what types of messages are logged to console
        
    Planned upcoming features:
        * Automatic generation of an object-oriented Javascript API, based on your property definitions, that fetches property values from server asynchronously.
        
        
    Usage examples pulled directly from my current custom game project:
        Primary API Usage: 
        
]]

DEFAULT_PROPERTY_CACHE_LIFETIME = 0.1 -- the default cache lifetime of a property

DEFAULT_PROPS_KEY = "_props" --default keyname for a entity's internal property table

--debug flag enum
PROP_DEBUG_NONE = 0 -- or just use false
PROP_DEBUG_GETTER = 1 -- debug getter calls
PROP_DEBUG_SETTER = 2 -- debug setter calls
PROP_DEBUG_CACHE = 4 -- debug cache behavior
PROP_DEBUG_EVENTS = 8 -- debug update events
PROP_DEBUG_CHANGES = 16 -- debug when a value changes
PROP_DEBUG_ALL = PROP_DEBUG_GETTER + PROP_DEBUG_SETTER + PROP_DEBUG_CACHE + PROP_DEBUG_EVENTS + PROP_DEBUG_CHANGES -- or just use true

if Property == nil then
    print("[PROPERTY] Creating Property library")
    Property = class({})
end
Property.VERSION = 0.1

--Local function declarations (code defined at bottom of file)
local Msg, GetProps, GetCache, CacheTime, TitleCase, NormalizeDebugOpt, FindGetter

function Property:constructor(entity, pName, opts)
    --[[ Adds a custom property to a game entity, providing getter/setter methods as well as providing a mechanism for NPC modifiers to transform property values.
        
        Usage:
            Property(myEntity, "myPropertyName")   -- without options table
            Property(myEntity, "myPropertyNAme", { -- with options table
                type = "number",
                default = 100,
                debug = PROP_DEBUG_SETTER + PROP_DEBUG_CHANGES,
                -- ... other options go here ...
            })

        Inputs:
            entity: (required) The entity to attach the property to 
            pName: (required) The name of the property
            opts: (optional) a table of configuration parameters 
            
        Options Table Format:
            default - The initial value for this property
            
            set - A string specifying a name to use for the property's setter method. A value of false indicates no setter should be created.
                  If no set option is given, the setter's name will be "Set" followed by the property's name with the first character capitalized.
                  
                    Example of default behavior (no "set" option defined):
                        Property(entity, "value")
                        entity:SetValue(322)
                        
                    Example with "set" defined:
                        Property(entity, "value", { set = "SetBaseValue" })
                        entity:SetBaseValue(322)          
            
            get - Same behavior as "set", but for the getter function; expects a string or false. Default getter name is likewise similar but with "Get" prefixed to the property name instead of "Set"
            
            type -  A string indicating the property's type. All this effectively does is set some other options to sensible defaults if they're not already defined.
                    Valid type options: "number" (the default), "bool", "string", or nil
                    
                    Detailed behavior of type strings:
                    
                        If the "default" option is not set:
                            number: default value is 0
                            bool: default value is false
                            string: default value is the empty string
                        
                        If the "combine" option is not set:
                            number: return values from Lua modifiers are combined additively
                            bool: if a modifier's handler for this property returns true, the property's value is true
                            string: return values from Lua modifiers are concatened.
                                
            updateEvent - A string indicating the name of a custom event to send to clients whenever this property's value changed. 
                          By default, we do not send update events unless this option is given.
                          For fine-tuned control of event parameters, see the modifyEventParams option.
                                
            useGameTime - if true, instructs the cache to use GetGameTime instead of Time. (default: true)
            
            cacheLifetime - A floating point value representing the time (in seconds) that a cached value is valid. Set to 0 to disable caching.
                    
            onChange -  A function that's called when the computed value of the property has changed from its previous value.
                            
                        Input parameters: (entity, newValue, oldValue, propName, opts)
                        
                        Return value: (optional) a replacement value for the property
                        
            modifyEventParams - if the updateEvent option is specified, this option can be a function that will be called just before the event fires, and can be used to modify the events parameters
            
                                Input parameters: (eventName, eventParams, entity)
                                
                                Returns: (optional) a table describing the new event parameters. If no return value, we simply use the original parameter table, complete with any modifications that
                                         the callback made.
                            
            combine -   A function describing how property values are computed from modifiers.
                        Essentially, this is a binary operator that is used to sequentially fold all of the values returned by modifiers for this property.
                    
                        Input parameters: (modifier, accumulatedValue, modifierValue)
                    
                        Return value: the desired result of combining accumulatedValue with modifierValue
                    
                        For example, if you wanted to override the default additive behavior of numeric properties and instead use multiplicative, you could define combine like this:
                            Property(myEntity, "multiplicativeProperty", {
                                default = 1,
                                combine = function(modifier, a, b)
                                    return a*b
                                end
                            })
                        
                        For convenience, this multiplicative behavior is provided by the built-in function Property.multiplicative. See the examples below for examples of its usage.
                        
            debug - A boolean indicating whether or not to display debug messages for this property, or a bitflag specifying more precise output options. (see PROP_DEBUG_* enum)
                    This can also be changed with Property.SetDebug (Note: takes precedence over both entity-defined settings and global settings)
                          
        Examples:
            -- An additive numeric property
            Property(entity, "myPropertyName", {
                type = "number"
            })
        
            -- A multiplicative numeric property
            Property(entity, "myPropertyName", {
                type = "number",
                default = 1,
                combine = Property.multiplicative
            })
            
            -- A numeric property that sends an update event to all clients when changed
            Property(entity, "myPropertyName", {
                type = "number",
                updateEvent = "property_changed"
            })
            
            -- Make all properties on this entity, by default, send an update event when changed
            Property.EntityOptions(entity, {
                defaultPropertyOptions = {
                    updateEvent = "property_changed"
                }
            }
            
            -- A boolean flag with custom names for its getter/setter functions
            Property(entity, "CustomBehaviorRequired", {
                type = "bool",
                default = false,
                get = "IsCustomBehaviorRequired",
                set = "RequireCustomBehavior"
            })
            
            -- A boolean flag that will fail if any modifier returns false for it
            Property(entity, "FailIfFalse", {
                type = "bool",
                default = true,
                combine = Property.boolAll
            })
        
            -- A numeric property with no setter function (only modifiers can be used to alter its value)
            Property(entity, "propertyName", {
                type = "number",
                default = 50,
                set = false,
            })
            
            -- A string property that ignores all modifiers (only the setter function can be used to change it)
            Property(entity, "propertyName", {
                type = "string",
                combine = Property.ignoreModifiers,
            })
            
            -- A read-only property
            Property(entity, "readOnlyProperty", {
                default = 50,
                set = false,
                combine = Property.ignoreModifiers,
            })
            
            -- A magic resist stat that behaves like dota armor rating, and automatically updates built-in magic resist when changed.    
            Property(entity, "customMagicResist", {
                type = "number",
                onChange = function(entity, newValue, oldValue)
                    entity:SetBaseMagicalResistanceValue(0.06 * newValue / (1 + 0.06 * newValue))
                end
            })
    ]] 
    Property._HandleOptions(pName, opts, entity)
    return { } -- placeholder for a property handle that we might return to the user in the future.
end

function Property.Derived(entity, pName, opts, cb)
    opts = opts or { }
    if cb == nil and type(opts) == "function" then -- handle 3-argument call
        cb = opts
        opts = { }
    end
    
    Property._HandleDerivedOptions(pName, opts, entity)   
    if entity ~= nil then --add callback to handler table
        entity._derivedHandlers[pName] = cb
    end
    return { } -- placeholder for a property handle that we might return to the user in the future.
end


function Property.EntityOptions(entity, opts)
    --[[ This function allows specification of entity-wide options that the property system will obey.
        
        Options Table Format (all fields are optional):
            debug - a boolean indicating whether or not we should print debugging messages for this entity.
                    Can also pass in a debug flag for more specific settings (see PROP_DEBUG_* enum)
                    (Note: entity-specified options take precedence over global options, see: Property.SetDebug)
            
            defaultPropertyOptions - a table of default property options to use for properties of this entity.
                                     if the Property() options table for a property on this entity does not define a field, it will
                                     be copied from this table instead.
            
            propsKey - a string that will override the default name for the inner table used to store property values on this entity
    ]]
    entity._propertyDebugMode = NormalizeDebugOpt(opts.debug)
    entity._propsKey = opts.propsKey
    entity._propsDefaults = opts.defaultPropertyOptions
end

function Property.ClearCache(entity, pName)
    --[[ Clears the cached value of a entity's property. If no property name is specified, clears all cached properties. 
    ]]
    local clearList
    if pName == nil then
        clearList = GetCache(entity)
    else
        clearList = { GetCache(entity)[pName] }
    end
    for _, cacheEntry in pairs(clearList) do
        cacheEntry.cacheTime = 0
    end
end

function Property.SuppressUpdateEvents(entity, cb, suppressedHandler)
--[[ Runs a callback with all update events suppressed. Suppression will discontinue at the end.
    The optional second callback is a handler called at the end that receives an array of
    the suppressed events.
]]
    --print("SuppressUpdateEvents")
    Property._InitEntity(entity)
    --save a snapshot of previous suppression state, so that we can handle nested SuppressUpdateEvents calls properly
    local previousEvents = entity._suppressedEventsList
    local previousFlag = entity._suppressUpdateEvents     
    --execute the given callback with event suppression enabled, catching all errors
    entity._suppressUpdateEvents = true
    entity._suppressedEventsList = { }
    local errorStatus, res = pcall(cb)
    local suppressed = entity._suppressedEventsList -- store a snapshot of the suppressed events, for use by the suppression handler
    --restore previous suppression state before we were called
    entity._suppressUpdateEvents = previousFlag
    entity._suppressedEventsList = previousEvents
    --rethrow any errors that occured
    if not errorStatus then
        error(res)
    end
    -- if suppression was enabled in outer calling context, aggregate new suppressed events array into old array
    if entity._suppressUpdateEvents then
        for _, event in ipairs(suppressed) do
            table.insert(entity._suppressedEventsList, event)
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

function Property.BatchUpdateEvents(entity, cb)
    --[[ Aggregates all update events that fire within the callback into single events with combined parameters.
       
        Useful for avoiding unnecessary network usage when updating multiple entity properties simultaneously.
    ]]
    Property._InitEntity(entity)
    return Property.SuppressUpdateEvents(entity, cb, function(suppressed)
        local batchedEvents = { }
        -- aggregate events with the same name into one event
        for _, event in ipairs(suppressed) do
            local batched = batchedEvents[event.name]
            if batched == nil then
                batched = { }
                batchedEvents[event.name] = batched
            end
            for paramName, paramValue in pairs(event.params) do
                batched[paramName] = paramValue
            end
        end
        for eventName, eventParams in pairs(batchedEvents) do
            Property.SendUpdateEvent(entity, eventName, eventParams)
        end
    end)
end

 
--[[ 
    For convenience, a number of commonly used combinators are provided with this library. 
    These are intended to be passed to the "combine" option for property definitions. 
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

--[[ Ignores all values returned by modifiers. Only the value attached to the entity itself and modified with the property's setter function will be considered

    This is the default combine behavior for properties with no type specified.
]]
function Property.ignoreModifiers(m, a, b)
    return a
end

function Property.SetDebug(flag, entity, pName)
    --[[ Sets debug mode for a given entity (or globally), providing detailed console output for property behaviors.
    
    Parameters:
        flag  - true or false, indicating whether or not to provide debug messages, or a bitflag for more specific options (see PROP_DEBUG_* enum)
        
        entity  - (optional) the entity to disable/enable debugging on. If nil, sets the global
                debug flag for all entities (Note: entity-specific settings take precedence over global settings)
                
        pName - (optional) the name of the property to disable/enable debugging on. If nil, sets the entity's
                debug flag (Note: property-specific settings take precedence over both entity and global settings)
    ]]
    if entity == nil then
        Property.debugMode = NormalizeDebugOpt(flag) --global flag
    elseif pName == nil then
        entity._propertyDebugMode = NormalizeDebugOpt(flag) -- entity flag
    else
        Property._InitEntity(entity)
        local cache = GetCache(entity)[pName]
        if cache then
            cache.debugMode = NormalizeDebugOpt(flag)
        end
    end
end

function Property.IsDerived(entity, pName)
    return entity._derivedHandlers[pName] ~= nil
end

--[[ 

    The remaining functions in this module are all used internally, and aren't part of the basic usage API. You probably don't need to ever call them, but they can be
    useful if you wish to override default library behavior for more advanced use cases.

]]

function Property._InitEntity(entity)
    --[[ Initializes internal entity state. ]]
    if not entity._propsInitialized then
        entity[entity._propsKey or DEFAULT_PROPS_KEY] = { } -- table of property names with associated "base" values, these are the values
                                                        -- that are modified through the setter function for this property.
        entity._propsCache = { } -- cache of results from computing the modifier handlers for a entity's properties
        if entity._propsDefaults == nil then 
            entity._propsDefaults = { } -- default property options for property's of this entity
        end
        entity._suppressUpdateEvents = false -- flag indicating whether or not we're in suppression mode
        entity._suppressedEventsList = { } -- list of events that were suppressed during the current suppression interval.
        entity._propGetters = { } --associates the name of a getter function to the name of the property it gets
        entity._propSetters = { } --same as _propGetters but for setter functions.
        entity._derivedHandlers = { } -- associates the name of a derived property to its getter callback
        entity._associatedUpdates = { } -- keys are property names, values are unordered sets of properties to update when this one is updated
        entity._propsInitialized = true --entity has been properly initialized by the property lib
    end
end

function Property._HandleOptions(pName, opts, entity)
    --[[ Fills in option defaults, and initializes the entity's internal state. Called by literally everything else, so there should be no need to use this normally.
    
        If no options table given, constructs a new table from defaults and returns it.
        If no entity given, no entity initialization is performed, but the options table is still constructed.
    ]]
    --Msg(entity, pName, "_HandleOptions")
    opts = opts or { }
    
    if entity ~= nil then
        Property._InitEntity(entity)
        --initialize entity-defined defaults
        for k, v in pairs(entity._propsDefaults) do
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
    opts.type = opts.type or "number"
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
    
    -- useGameTime defaults
    if opts.useGameTime == nil then
        opts.useGametime = true
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
    
    if entity ~= nil then
        -- initialize property with default
        local props = GetProps(entity)
        if props[pName] == nil and opts.default ~= nil then
            props[pName] = opts.default
        end        
        -- initialize cache value
        local cache = GetCache(entity)
        if cache[pName] == nil then
            cache[pName] = {
                value = props[pName],
                cacheTime = 0,
                debugMode = NormalizeDebugOpt(opts.debug)
            }
        end
        --define property getter/accessor functions
        if opts.get and entity[opts.get] == nil then
            entity[opts.get] = Property.Getter(pName, opts)
            entity._propGetters[opts.get] = entity._propGetters[opts.get] or pName
        end
        if opts.set and entity[opts.set] == nil then
            entity[opts.set] = Property.Setter(pName, opts)
            entity._propSetters[opts.set] = entity._propSetters[opts.set] or pName
        end
    end
    return opts
end

function Property._HandleDerivedOptions(pName, opts, entity)
    --[[ we use the normal options handling for derived props, but fill in some options that shouldn't be messed with
    ]]
    opts.get = opts.get == false or opts.get -- get option cannot be false
    opts.set = false -- cannot define a setter (may change in the future?)
    opts.cacheLifetime = opts.cacheLifetime or 0 -- by default we do not return cached values for derived properties
    opts.default = nil
    opts.type = nil 
    return Property._HandleOptions(pName, opts, entity)
end


function Property.CheckDebugMode(entity, pName, testFlag) 
    --[[ Returns a boolean indicating whether or not we are currently printing debug info for the given entity and property.
    
        if entity parameter is nil, checks the global flag only.
        
        if pName parameter is nil, checks the entity flag and global flag.
        
        testFlag can be used to test the debug flag against a bitset
    ]]
    testFlag = NormalizeDebugOpt(testFlag)
    local flag = Property.GetDebugFlag(entity, pName)
    if flag == nil or flag == PROP_DEBUG_NONE then
        return false
    elseif testFlag == nil and flag ~= PROP_DEBUG_NONE then
        return true
    elseif flag == testFlag then
        return true
    else
        return bit.band(testFlag, flag) ~= 0
    end
end

function Property.GetDebugFlag(entity, pName)
    --[[ retrieve the numeric debug flag that has precedence over this entity/property combination ]]
    
    if entity ~= nil then
        if pName ~= nil then -- check property debug flag first
            local cache = GetCache(entity)
            if cache then
                local entry = cache[pName]
                if entry and entry.debugMode ~= nil then
                    return entry.debugMode
                end
            end
        end
        if entity._propertyDebugMode ~= nil then -- check entity debug flag second
            return entity._propertyDebugMode
        end
    end
    return Property.debugMode -- check global flag last
end

function Property.SendUpdateEvent(entity, eventName, eventParams)
--[[ Sends an event to client(s) to indicate that stats were changed, respecting event suppression settings.

    If you passed an updateEvent option to the property (or to the entity-wide defaults via Property.EntityOptions), this function is called automatically
    upon changes to a property's value.
    
    However, you may wish to use this function yourself in order to leverage BatchUpdateEvents and SuppressUpdateEvents for
    custom events that aren't associated with the property system. It's in fact possible to use this function along with BatchUpdateEvents
    and SuppressUpdateEvents without even initializing a single property on the entity, so these functions may become a seperate library in the future.

    Parameters:
        entity - the entity associated with this event
        eventName - a string representing the event's name
        eventParams - (optional) a table of event parameters to pass to the client(s)
                      if this table provides a key named "playerID", we will send the event only to that client,
                      otherwise we send to all clients.
]]
    Property._InitEntity(entity)
    eventParams = eventParams or { }
    if entity._suppressUpdateEvents then
        Msg(entity, nil, PROP_DEBUG_EVENTS, "SendUpdateEvent", eventName, "SUPPRESSED")
        table.insert(entity._suppressedEventsList, {name = eventName, params = eventParams})
    else
        Msg(entity, nil, PROP_DEBUG_EVENTS, "SendUpdateEvent", eventName, "SENDING (playerID: " .. (eventParams.playerID or "(none)") .. ")")
        if eventParams.playerID then
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(eventParams.playerID), eventName, eventParams)
        else
            CustomGameEventManager:Send_ServerToAllClients(eventName, eventParams)
        end
    end
end

function Property.Getter(pName, opts)
    --[[ Constructs a getter function for a property.

        This is called automatically by the Property() constructor, so you shouldn't need to call this manually in most cases.
    ]]
    return function(entity, dontCheckCache)
        Property._HandleOptions(pName, opts, entity)
        --util.printTable(opts)
        --Msg(entity, pName, "PropGetter", pName)
        local t = CacheTime(opts.useGameTime)
        local cached = GetCache(entity)[pName]
        local v
        if dontCheckCache or t > cached.cacheTime + opts.cacheLifetime then
            Msg(entity, pName, PROP_DEBUG_GETTER, "getting new value for ", pName)
            
            local old = cached.value --save a snapshot of the cache value, since we will be resetting it soon        
            cached.cacheTime = t --update cache time early before actually updating the cache value,
                                 --so if modifiers refer to the property itself, they will get the old cache snapshot instead of recursing
            if Property.IsDerived(entity, pName) then
                v = Property._ComputeDerivedProperty(entity, pName, opts) -- for derived properties, run user-supplied getter
            else
                v = Property._ComputeProperty(entity, pName, opts) -- for normal properties, run all handlers on entity modifiers
            end
            cached.value = v --update cache with newly computed value
            if v ~= old then
                Msg(entity, pName, PROP_DEBUG_GETTER + PROP_DEBUG_CHANGES, "value changed", pName, v, old)
                if opts.onChange ~= nil then
                    local changedV = opts.onChange(entity, v, old, pName, opts)
                    if changedV ~= nil then
                        v = changedV
                        cached.value = v -- update cache again with the modified value
                    end
                end
                Property._SendUpdateEvents(entity, pName, v, opts)
            end
        else
            Msg(entity, pName, PROP_DEBUG_CACHE, "getting cached value for", pName, cached.value)
            v = cached.value
        end 
        return v
    end
end


function Property.Setter(pName, opts)
    --[[ Constructs a setter function for a property.

        This is called automatically by the Property() constructor, so you shouldn't need to call this manually in most cases.
    ]]
    return function(entity, v)
        Property._HandleOptions(pName, opts, entity)
        Msg(entity, pName, PROP_DEBUG_SETTER, "Setter", pName, v)
        GetProps(entity)[pName] = v
        --find and call getter, forcing cache update
        local getter = FindGetter(entity, pName)
        if type(getter) == "function" then
            getter(entity, true)
        end
    end
end

function Property._SendUpdateEvents(entity, pName, value, opts)
    --[[ internal helper used by PropSetter and PropGetter to send update events.
    ]]
    if opts.updateEvent then
        local params = { [pName] = value }
        if opts.modifyEventParams then
            params = opts.modifyEventParams(opts.updateEvent, params, entity) or params
        end
        Property.SendUpdateEvent(entity, opts.updateEvent, params)
    end
    if entity ~= nil then
        local updateList = entity._associatedUpdates[pName]
        if updateList ~= nil then
            for assocProp, _ in pairs(updateList) do
                local getterName
                --find the getter function
                local getter = FindGetter(entity, assocProp)
                if type(getter) == "function" then
                    getter(entity)
                end
            end
        end
    end
end

function Property._ComputeProperty(entity, pName, opts)
    --[[ Computes the value of a property based on its base value and the entity's current modifiers.
    
        While this function is called internally by property getters, you might find it useful as it
        completely ignores the cache and always loops over modifiers to obtain the current property value.
    ]]
    Msg(entity, pName, PROP_DEBUG_GETTER, "_ComputeProperty called")
    Property._HandleOptions(pName, opts, entity)
    local out = GetProps(entity)[pName]
    if type(entity.FindAllModifiers) == "function" then
        for k, modifier in pairs(entity:FindAllModifiers()) do
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
    end
    Msg(entity, pName, PROP_DEBUG_GETTER, "_ComputeProperty", pName, out)
    return out
end

function Property._ComputeDerivedProperty(entity, pName, opts)
    --[[ Computes the value of a derived property by calling its user-supplied getter function, along with a little bit of magic plumbing
         to automatically detect sub-property usage.
    ]]
    Msg(entity, pName, PROP_DEBUG_GETTER, "_ComputeDerivedProperty called")
    Property._HandleDerivedOptions(pName, opts, entity)
    local proxyEntity = Property._CreateProxyEntity(entity)
    local proxyMeta = getmetatable(proxyEntity)
    local out = entity._derivedHandlers[pName](proxyEntity)
    for subPropName, _ in pairs(proxyMeta.callLog) do
        --Msg(entity, pName, "adding association to sub prop:", subPropName)
        local updateList = entity._associatedUpdates[subPropName]
        if updateList == nil then
            updateList = { }
            entity._associatedUpdates[subPropName] = updateList
        end
        updateList[pName] = true
    end
    Msg(entity, pName, PROP_DEBUG_GETTER, "_ComputeDerivedProperty result", pName, out)
    return out
end

function Property._CreateProxyEntity(entity)
    --[[ Before calling a derived propery handler, we create a proxy table for the entity with a metatable for handling entity Property access ]]
    
    local proxy = { } -- a dummy table that we return whose only purpose is to have a metatable attached to it
    local proxyMeta = { } -- metatable for proxy entity
    
    proxyMeta.callLog = { } --list of properties whose getters/setter were called from the proxy 
    
    proxyMeta.__index = function(_, key) -- table access       
        local actualVal = entity[key]
        if type(actualVal) == "function" then
            --check if this is a getter
            local pName = entity._propGetters[key]
            if pName ~= nil then
                --return a proxy getter that records the getter being called
                return function(...)
                    proxyMeta.callLog[pName] = true --log the getter call
                    return actualVal(...) -- call actual entity's getter and return value as is
                    --return Property._CreateProxyValue(entity, pName, propVal) -- return a proxy of the value
                end
            end
        end
        return actualVal -- if not getter, return value as-is
    end
        
    proxyMeta.__newindex = function(_, key, val) -- table update
        entity[key] = val -- pass along table updates as-is
    end
    
    proxyMeta.__pairs = function(_, ...) -- pairs()
        return pairs(entity, ...)
    end
    
    proxyMeta.__ipairs = function(_, ...) -- ipairs()
        return ipairs(entity, ...)
    end
    setmetatable(proxy, proxyMeta)
    return proxy
end

--[[ Various local helper/utility functions are defined below. ]]

Msg = function(entity, pName, flag, ...) --debug helper
    if Property.CheckDebugMode(entity, pName, flag) then
        if entity == nil then
            print(...)
        else
            print(type(entity.GetName) == "function" and entity:GetName() or tostring(entity), ...)
        end
    end
end

GetProps = function(entity) --helper to retrieve entity's internal property table
    return entity[entity._propsKey or DEFAULT_PROPS_KEY]
end

GetCache = function(entity) --helper to retrieve entity's internal property cache
    return entity._propsCache
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

NormalizeDebugOpt = function (debugFlag) 
    if debugFlag == true then
        return PROP_DEBUG_ALL
    elseif debugFlag == false then
        return PROP_DEBUG_NONE
    else
        return debugFlag
    end
end

FindGetter = function(entity, pName)
    for getterName, p in pairs(entity._propGetters or { }) do
        if p == pName then
            return entity[getterName]
        end
    end
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