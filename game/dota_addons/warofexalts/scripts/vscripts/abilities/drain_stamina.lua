drain_stamina = class({})


function drain_stamina:OnToggle()
    if IsServer() then
        self.timer = Timers:CreateTimer(0, function()
            if self:GetToggleState() then
                self:GetCaster():SpendStamina(10)
                return 0.5
            end
        end)
    end
end