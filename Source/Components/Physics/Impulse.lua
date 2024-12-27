Impulse = {}
Impulse.name = "Impulse"
Impulse.frames = 1
Impulse.force = Vec3(0)
Impulse.torque = Vec3(0)
Impulse.global = true

function Impulse:Update()
    if self.frames > 0 then
        self.entity:AddForce(self.force, self.global)
        self.entity:AddTorque(self.torque, self.global)
        self.frames = self.frames - 1
    end
end

RegisterComponent("Impulse", Impulse)
return Impulse