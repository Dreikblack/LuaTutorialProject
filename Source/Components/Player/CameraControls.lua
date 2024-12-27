-- Define the CameraControls table
CameraControls = {}
CameraControls.freelookmousepos = Vec3(0, 0, 0)
CameraControls.freelookrotation = Vec3(0, 0, 0)
CameraControls.lookchange = Vec2(0, 0)
CameraControls.mousesmoothing = 0.0
CameraControls.mouselookspeed = 1.0
CameraControls.movespeed = 4.0
CameraControls.name = "CameraControls"

-- Update function for CameraControls
function CameraControls:Update()
    local window = ActiveWindow()
    if window == nil then
        return
    end
    
    if self.freelookstarted ~= true then
        self.freelookstarted = true
        self.freelookrotation = self.entity:GetRotation(true)
        self.freelookmousepos = window:GetMouseAxis()
    end
    
    local newmousepos = window:GetMouseAxis()
    self.lookchange.x = self.lookchange.x * self.mousesmoothing + (newmousepos.y - self.freelookmousepos.y) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)
    self.lookchange.y = self.lookchange.y * self.mousesmoothing + (newmousepos.x - self.freelookmousepos.x) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)
    
    if math.abs(self.lookchange.x) < 0.001 then
        self.lookchange.x = 0.0
    end
    
    if math.abs(self.lookchange.y) < 0.001 then
        self.lookchange.y = 0.0
    end
    
    if self.lookchange.x ~= 0.0 or self.lookchange.y ~= 0.0 then
        self.freelookrotation.x = self.freelookrotation.x + self.lookchange.x
        self.freelookrotation.y = self.freelookrotation.y + self.lookchange.y
        self.entity:SetRotation(self.freelookrotation, true)
    end
    
    self.freelookmousepos = newmousepos
    local speed = self.movespeed / 60.0
    
    if window:KeyDown(KEY_SHIFT) then
        speed = speed * 10.0
    elseif window:KeyDown(KEY_CONTROL) then
        speed = speed * 0.25
    end
    
    if window:KeyDown(KEY_E) then
        self.entity:Translate(0, speed, 0)
    end
    
    if window:KeyDown(KEY_Q) then
        self.entity:Translate(0, -speed, 0)
    end
    
    if window:KeyDown(KEY_D) then
        self.entity:Move(speed, 0, 0)
    end
    
    if window:KeyDown(KEY_A) then
        self.entity:Move(-speed, 0, 0)
    end
    
    if window:KeyDown(KEY_W) then
        self.entity:Move(0, 0, speed)
    end
    
    if window:KeyDown(KEY_S) then
        self.entity:Move(0, 0, -speed)
    end
end

RegisterComponent("CameraControls", CameraControls)

-- Return the CameraControls table
return CameraControls