ChangeVisibility = {}
ChangeVisibility.name = "ChangeVisibility"

function ChangeVisibility:Show()
    self.entity:SetHidden(false)
end

function ChangeVisibility:Hide()
    self.entity:SetHidden(true)
end

RegisterComponent("ChangeVisibility", ChangeVisibility)
return ChangeVisibility