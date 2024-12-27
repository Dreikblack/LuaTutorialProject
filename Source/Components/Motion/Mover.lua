Mover = {}
Mover.name = "Mover"

Mover.movementspeed = Vec3(0)
Mover.rotationspeed = Vec3(0,1,0)
Mover.globalcoords = false

function Mover:Start()
    
end

function Mover:Update()
    if self.globalcoords then
        self.entity:Translate(self.movementspeed / 60, true)
    else
        self.entity:Move(self.movementspeed / 60)
    end
    self.entity:Turn(self.rotationspeed / 60, self.globalcoords)
end

RegisterComponent("Mover", Mover)

return Mover