modifier_client_side_init = class({})

print("[WAROFEXALTED] client-side Lua init")
if not IsServer() then
    CustomGameEventMananger:RegisterListener("woe_unit_response", function(params)
        local ent = EntIndexToHScript(params.unitId)
        ent:SetBaseMagicalResistanceValue(ent:GetBaseMagicalResistanceValue()) -- update UI
    end)
end