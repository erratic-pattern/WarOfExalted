if Affectors == nil then
    print("[AFFECTORS] creating Affectors")
    Affectors = { }
    Affectors.__index = Affectors
end



function Affectors:CreateAffector(affector)
    affector.Position = affector.Position or Vector(0,0,0)
    affector.ThinkInterval = affector.ThinkInterval or 0.1
    affector.FindOrder = affector.FindOrder or FIND_ANY_ORDER
    affector.CanGrowCache = affector.CanGrowCache or false
    affector.Duration  = affector.Duration or 1
    affector.Radius = affector.Radius or 1
    affector.OnThink = affector.OnThink or function() return end
    affector.OnUnit  = affector.OnUnit or function() return end
    affector.caster = affector.Source or (affector.Ability and affector.Ability:GetCaster())
    affector.UseGameTime = affector.UseGameTime or true
    function affector:FindUnits()
        local source = self.caster
        if source then
            if self.iUnitTargetTeam or self.iUnitTargetFlags or self.iUnitTargetType then
                return FindUnitsInRadius(source:GetTeam(), self.Position, nil, self.Radius, self.iUnitTargetTeam or 0, self.iUnitTargetType or 0, self.iUnitTargetFlags or 0, self.FindOrder, self.CanGrowCache)
            elseif self.Ability then
                return FindUnitsInRadius(source:GetTeam(), self.Position, nil, self.Radius, self.Ability:GetAbilityTargetTeam(), self.Ability:GetAbilityTargetType(), self.Ability:GetAbilityTargetFlags(), self.FindOrder, self.CanGrowCache)
            end
        end
        return nil
    end
    local startTime = GameRules:GetGameTime()
    affector.timer = Timers:CreateTimer({
        useGameTime = affector.UseGameTime,
        callback = function()
            local ents = affector:FindUnits()
            for _,ent in ipairs(ents) do
                if affector.Modifier then
                    ent:AddNewModifier(affector.caster, affector.Ability, affector.Modifier, affector.ModifierData or {})
                end
                affector:OnUnit(ent)
            end
            affector:OnThink()
            if GameRules:GetGameTime() - startTime < affector.Duration then
                return affector.ThinkInterval
            end
        end
    })
    return affector
end