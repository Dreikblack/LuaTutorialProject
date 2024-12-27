ChangeEmission = {}
ChangeEmission.name = "ChangeEmission"
ChangeEmission.color1 = Vec3(0)
ChangeEmission.color2 = Vec3(0)
ChangeEmission.color3 = Vec3(0)

function ChangeEmission:SetColor1()
    self.entity:SetEmissionColor(self.color1.r, self.color1.g, self.color1.b)
end

function ChangeEmission:SetColor2()
    self.entity:SetEmissionColor(self.color2.r, self.color2.g, self.color2.b)
end

function ChangeEmission:SetColor3()
    self.entity:SetEmissionColor(self.color3.r, self.color3.g, self.color3.b)
end

RegisterComponent("ChangeEmission", ChangeEmission)
return ChangeEmission