drain_stamina = class({})


function drain_stamina:OnToggle()
    self.timer = nil
    if IsServer() then
        local t = self:GetCaster()._propsCache.StaminaRegenBase
        util.debugTable("cache", t)
        self.timer = Timers:CreateTimer(0, function()
            if self:GetToggleState() then
                self:GetCaster():SpendStamina(10)
                return 0.5
            end
        end)
    end
end