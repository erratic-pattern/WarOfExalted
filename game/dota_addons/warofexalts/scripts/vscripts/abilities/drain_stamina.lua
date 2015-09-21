drain_stamina = class({})


function drain_stamina:OnToggle()
    if IsServer() then
        if self.timer == nil then
            self.timer = Timers:CreateTimer(0, function()
                if self:GetToggleState() then
                    self:GetCaster():SpendStamina(10)
                end
                return 0.5
            end)
        end
    end
end