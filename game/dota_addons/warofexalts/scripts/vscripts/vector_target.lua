local MAX_ORDER_QUEUE = 34

-- a basic queue implementation
local queue = { }

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

-- a table vector orders in-progress by player ID
local inProgressOrders = { }

-- table of cast queues indexed by unit ID
local castQueues = { }

-- get a unit's (vector target) cast queue
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

function castQueues:clearQueuesForUnits(units)
    for _, unitId in pairs(units) do
        for _, q in pairs(queueList or {}) do
            if q then
                queue.clear(q)
            end
        end
    end
end

function VectorToArray(v)
    return {v.x, v.y, v.z}
end

-- This is the order filter we use to handle vector targeting.
-- If you don't use any other order filters, you can simply use SetExecuteOrderFilter with this function.
-- Otherwise, call this function from within your own SetExecuteOrderFilter callback.
function VectorTargetOrderFilter(data)
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
    if abilId > 0 then
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
                    shiftPressed = data.queue
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
                inProgressOrders[playerId] = nil
                --TODO: reset data.position_* to nearest allowed cast location
            end
        end
    end
    return true
end

--wrapper applied to all vector targeted abilities during initialization
function VectorTargetWrapper(abil)
    local abiName = abil:GetAbilityName()
    if "ability_lua" ~= abil:GetClassname() then
        print("[VECTORTARGET] warning: " .. abiName .. " is not a Lua ability and cannot be vector targeted.")
        return
    end
    
    --initialize members
    abil.isVectorTarget = true -- use this to test if an ability has vector targeting
    abil._vectorTargetKeys = {
        initialPosition = nil,                      -- initial position of vector input
        terminalPosition = nil                      -- terminal position of vector input
    }
    
    function abil:GetInitialPosition()
        return self._vectorTargetKeys.initialPosition
    end
    
    function abil:SetInitialPosition(t)
        self._vectorTargetKeys.initialPosition = t
    end
    
    function abil:GetTerminalPosition()
        return self._vectorTargetKeys.terminalPosition
    end
    
    function abil:SetTerminalPosition(t)
        self._vectorTargetKeys.terminalPosition = t
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

-- call this in your Precache() function to precache vector targeting particles
function PrecacheVectorTargetLib(context)
    PrecacheResource("particle", "particles/vector_target_ring.vpcf", context)
    PrecacheResource("particle", "particles/vector_target_range_finder_line.vpcd", context)
end


local initializedEventListeners = false

function InitVectorTargetEventListeners()
    if initializedEventListeners then
        return
    end
    print("[VECTORTARGET] initializing event listeners")
    CustomGameEventManager:RegisterListener("vector_target_order_cancel", function(eventSource, keys)
        --print("order canceled");
        inProgressOrders[keys.playerId] = nil
    end)
    initializedEventListeners = true
end