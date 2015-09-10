WoeUnitMonitor = { }
WoeUnitMonitor.units = { }


function WoeUnitMonitor:GetListenersForUnit(unit)
    local unitId = unit:GetEntityIndex()
    local units = self.units[unitId]
    if units == nil then
        units = { }
        self.units[unitId] = units
    end
    return units
end

function WoeUnitMonitor:AddListener(player, unit)
    local listeners = self:GetListenersForUnit(unit)
    table.insert(listeners, player)
end

function WoeUnitMonitor:RemoveListener(playerId, unit)
    local listeners = self:GetListenerForUnit(unit)
    table.remove(listeners, player)
end

function WoeUnitMonitor:SendEvent(unit, eventName, eventParams)
    local listeners = self:GetListenerForUnit(unit)
    eventParams.unit = eventParams.unit or unit
    --Send_ServerToPlayer doesn't appear to work, so this is commented out for now
    --[[for _, player in pairs(listeners) do
        CustomGameEventManager:Send_ServerToPlayer(player, eventName, eventParams or { })
    end
    ]]
    if next(listeners) ~= nil then --if not empty
        CustomGameEventManager:Send_ServerToAllClients(eventName, eventParams or { })
    end
end
