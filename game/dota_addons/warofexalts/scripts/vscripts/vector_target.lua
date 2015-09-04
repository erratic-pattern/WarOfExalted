local MAX_ORDER_QUEUE = 34 -- Make sure this value matches dota's internal order queue limit.

local queue = { } -- a basic queue implementation (see bottom of file)

local inProgressOrders = { } -- a table of vector orders currently in-progress, indexed by player ID

local abilityKeys = { } -- data loaded from KV files, indexed by ability name

local castQueues = { } -- table of cast queues indexed by castQueues[unit ID][ability ID]

local initializedPrecache = false

local initializedEventListeners = false

-- call this in your Precache() function to precache vector targeting particles
function PrecacheVectorTarget(context)
    if initializedPrecache then return end
    print("[VECTORTARGET] precaching assets")
    --PrecacheResource("particle", "particles/vector_target_ring.vpcf", context)
    PrecacheResource("particle", "particles/vector_target_range_finder_line.vpcf", context)
    initializedPrecache = true
end


-- call this in your init function to initialize for default use-case behavior
function InitVectorTarget(opts)
    print("[VECTORTARGET] initializing")
    if not initializedPrecache then
        print("[VECTORTARGET] warning: PrecacheVectorTargetLib was not called.")
    end
    opts = opts or { }
    if not opts.noEventListeners then
        InitVectorTargetEventListeners()
    end
    if not opts.noOrderFilter then
        print("[VECTORTARGET] registering ExecuteOrderFilter (use noOrderFilter option to prevent this)")
        GameRules:GetGameModeEntity():SetExecuteOrderFilter(VectorTargetOrderFilter, {})
    end
    if not opts.noLoadKV then
        LoadVectorTargetKV(opts.kv or "scripts/npc/npc_abilities_custom.txt")
    end
end

-- call this on a unit to add vector target functionality to its abilities
function AddVectorTargetingToUnit(unit)
    for i=0, unit:GetAbilityCount()-1 do
        local abil = unit:GetAbilityByIndex(i)
        if abil ~= nil then
            local keys = abilityKeys[abil:GetAbilityName()]
            if keys then
                VectorTargetWrapper(abil, keys)
            end
        end
    end
end


-- call this in your init function to start listening to events
function InitVectorTargetEventListeners()
    if initializedEventListeners then return end
    print("[VECTORTARGET] registering event listeners")
    CustomGameEventManager:RegisterListener("vector_target_order_cancel", function(eventSource, keys)
        --print("order canceled");
        inProgressOrders[keys.playerId] = nil
    end)
    initializedEventListeners = true
end

-- Loads vector target KV values from a file, or a table with the same format as one returned by LoadKeyValues()
function LoadVectorTargetKV(kv)
    print("[VECTORTARGET] loading KV data")
    if type(kv) == "string" then
        kv = LoadKeyValues(kv)
    elseif type(kv) ~= "table" then
        error("[VECTORTARGET] invalid input to LoadVectorTargetKV: " .. string(kv))
    end
    for name, keys in pairs(kv) do
        keys = keys["VectorTarget"]
        if keys and keys ~= "false" and keys ~= 0 then
            if type(keys) ~= "table" then
                keys = { }
            end
            abilityKeys[name] = keys
        end
    end        
end

-- get the cast queue for a given (unit, ability) pair
function castQueues:get(unitId, abilId)
    local unitTable = self[unitId]
    if not unitTable then
        unitTable = { }
        self[unitId] = unitTable
    end
    local q = unitTable[abilId]
    if not q then
        q = queue.new()
        self[unitId][abilId] = q
    end
    return q
end

-- given an array of unit ids, clear all cast queues associated with those units.
function castQueues:clearQueuesForUnits(units)
    for _, unitId in pairs(units) do
        for _, q in pairs(queueList or {}) do
            if q then
                queue.clear(q)
            end
        end
    end
end

-- This is the order filter we use to handle vector targeting.
-- If you don't use any other order filters, you can simply call SetExecuteOrderFilter on this function.
-- Otherwise, call this function from within your own callback.
function VectorTargetOrderFilter(ctx, data)
    --print("--order data--")
    --util.printTable(data)
    if data.queue == 0 then -- if shift was not pressed, clear our cast queues for the unit(s) in question
        castQueues:clearQueuesForUnits(data.units)
    end
    local playerId = data.issuer_player_id_const
    local abilId = data.entindex_ability
    local inProgress = inProgressOrders[playerId] -- retrieve any in-progress orders for this player
    if inProgress and inProgress.abilId ~= abilId then --check if this order cancels an in-progress order
        CustomGameEventManager:Send_ServerToAllClients("vector_target_order_cancel", inProgress)
        inProgress = nil
        inProgressOrders[playerId] = nil
    end
    if abilId ~= nil and abilId > 0 then
        local abil = EntIndexToHScript(abilId)
        if abil.isVectorTarget and data.order_type == DOTA_UNIT_ORDER_CAST_POSITION then
            local unitId = data.units["0"]
            --local player = PlayerResource:GetPlayer(playerId)
            local targetPos = {x = data.position_x, y = data.position_y, z = data.position_z}
            if inProgress == nil then -- if no in-progress order, this order selects the initial point of a vector cast
                local orderData = {
                    abilId = abilId,
                    orderType = data.order_type,
                    unitId = unitId,
                    playerId = playerId,
                    initialPosition = targetPos,
                    shiftPressed = data.queue,
                    minDistance = abil:GetMinDistance(),
                    maxDistance = abil:GetMaxDistance(),
                    targetingParticle = abil._vectorTargetKeys.targetingParticle,
                    cpMap = abil._vectorTargetKeys.cpMap
                }
                CustomGameEventManager:Send_ServerToAllClients("vector_target_order_start", orderData)
                inProgressOrders[playerId] = orderData --set this order as our player's current in-progress order
                return false
            elseif data.queue == 1 then --not sure why I need to do this but it seems to fix stuff...
                return true
            else --in-progress order (initial point has been selected)
                inProgress.terminalPosition = targetPos
                CustomGameEventManager:Send_ServerToAllClients("vector_target_order_finish", inProgress)
                queue.push(castQueues:get(unitId, abilId), inProgress)
                abil:SetInitialPosition(inProgress.initialPosition)
                abil:SetTerminalPosition(inProgress.terminalPosition)
                local p = abil:GetPointOfCast()
                data.position_x = p.x
                data.position_y = p.y
                data.position_z = p.z
                inProgressOrders[playerId] = nil
            end
        end
    end
    return true
end

--wrapper applied to all vector targeted abilities during initialization
function VectorTargetWrapper(abil, keys)
    local abiName = abil:GetAbilityName()
    if "ability_lua" ~= abil:GetClassname() then
        print("[VECTORTARGET] warning: " .. abiName .. " is not a Lua ability and cannot be vector targeted.")
        return
    end
    if abil.isVectorTarget then
        return
    end
    
    --initialize members
    abil.isVectorTarget = true -- use this to test if an ability has vector targeting
    abil._vectorTargetKeys = {
        initialPosition = nil,                      -- initial position of vector input
        terminalPosition = nil,                     -- terminal position of vector input
        minDistance = keys.MinDistance,
        maxDistance = keys.MaxDistance,
        pointOfCast = keys.PointOfCast or "initial",
        particleName = keys.ParticleName,
        cpMap = keys.ControlPoints
    }
    
    function abil:GetInitialPosition()
        return self._vectorTargetKeys.initialPosition
    end
    
    function abil:SetInitialPosition(v)
        if type(v) == "table" then
            v = Vector(v.x, v.y, v.z)
        end
        self._vectorTargetKeys.initialPosition = v
    end
    
    function abil:GetTerminalPosition()
        return self._vectorTargetKeys.terminalPosition
    end
    
    function abil:SetTerminalPosition(v)
        if type(v) == "table" then
            v = Vector(v.x, v.y, v.z)
        end
        self._vectorTargetKeys.terminalPosition = v
    end
    
    function abil:GetTargetVector()
        local i = self:GetInitialPosition()
        local j = self:GetTerminalPosition()
        return Vector(j.x - i.x, j.y - i.y, j.z - i.z)
    end
    
    
    function abil:GetDirectionVector()
        return self:GetTargetVector():Normalized()
    end
    
    if not abil.GetMinDistance then
        function abil:GetMinDistance()
            return self._vectorTargetKeys.minDistance
        end
    end
    
    if not abil.GetMaxDistance then
        function abil:GetMaxDistance()
            return self._vectorTargetKeys.maxDistance
        end
    end
    
    if not abil.GetPointOfCast then
        function abil:GetPointOfCast()
            local mode = self._vectorTargetKeys.pointOfCast
            if mode == "initial" then
                return self:GetInitialPosition()
            elseif mode == "terminal" then
                return self:GetTerminalPosition()
            elseif mode == "midpoint" then
                local i = self:GetInitialPosition()
                local t = self:GetTerminalPosition()
                return Vector((i.x + t.x)/2, (i.y + t.y)/2, (i.z + t.z)/2)
            else
                error("[VECTORTARGET] invalid point-of-cast mode: " .. string(mode))
            end
        end
    end
    
    --override GetBehavior
    local _GetBehavior = abil.GetBehavior
    function abil:GetBehavior()
        local b = _GetBehavior(self)
        return bit.bor(b, DOTA_ABILITY_BEHAVIOR_POINT)
    end
    
    local _OnAbilityPhaseStart = abil.OnAbilityPhaseStart
    function abil:OnAbilityPhaseStart()
        local abilId = self:GetEntityIndex()
        local unitId = self:GetCaster():GetEntityIndex()
        --pop unit queue
        local data = queue.popFirst(castQueues:get(unitId, abilId))
        self:SetInitialPosition(data.initialPosition)
        self:SetTerminalPosition(data.terminalPosition)
        return _OnAbilityPhaseStart(self)
    end
end

--queue implementation
function queue.new()
    return {first = 0, last = -1}
end

function queue.push(q, value)
    if queue.length(q) >= MAX_ORDER_QUEUE then
        print("[VECTORTARGET] warning: order queue has reached limit of " .. MAX_ORDER_QUEUE)
        return
    end
    local last = q.last + 1
    q.last = last
    q[last] = value
end

function queue.popLast(q)
    local last = q.last
    if q.first > last then error("queue is empty") end
    local value = q[last]
    q[last] = nil
    q.last = last - 1
    return value
end


function queue.popFirst(q)
  local first = q.first
  if first > q.last then error("queue is empty") end
  local value = q[first]
  q[first] = nil
  q.first = first + 1
  return value
end

function queue.clear(q)
    for i = q.first, q.last do
        q[i] = nil
    end
    q.first = 0
    q.last = -1
end

function queue.peekLast(q)
    return q[q.last]
end

function queue.peekFirst(q)
    return q[q.first]
end

function queue.length(q)
    return math.abs(q.last - q.first)
end