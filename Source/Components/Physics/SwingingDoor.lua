SwingingDoor = {}
SwingingDoor.name = "SwingingDoor"
SwingingDoor.pin = Vec3(0,1,0)
SwingingDoor.offset = Vec3(0)
SwingingDoor.storedmass = 0
SwingingDoor.fullyopened = false
SwingingDoor.fullyclosed = false
SwingingDoor.distance = 90
SwingingDoor.movespeed = 60.0
SwingingDoor.maxforce = 60.0
SwingingDoor.openstate = false

function SwingingDoor:BuildJoint()
    if not self.joint then
        self.storedmass = self.entity:GetMass()
        
        if self.storedmass == 0.0 then
            self.storedmass = 10
            self.entity:SetMass(self.storedmass)
        end
        
        self.startposition = self.entity:GetPosition(true)
        local parent = self.entity:GetParent()
        
        if not parent or parent:GetMass() == 0.0 then
            self.entity:SetGravityMode(false)
        end
        
        local position = self.entity:GetPosition() + self.offset
        local translate = TransformNormal(self.pin.x, self.pin.y, self.pin.z, self.entity, nil)
        self.joint = CreateHingeJoint(position, translate, parent, self.entity)
        self.joint:SetMaxTorque(0.0)
        self.joint:SetMotorSpeed(self.movespeed)
    end
end

function SwingingDoor:Start()
    self.storedmass = self.entity:GetMass();
    if self.storedmass == 0 then self.storedmass = 10 end
    self.entity:SetMass(0)
end

function SwingingDoor:Update()
    if self.entity:GetMass() > 0 then
        local o = math.abs(self.joint:GetOffset())
        
        if self.openstate then
            if o ~= 0.0 then
                local dis = math.abs(o - self.distance)
                if dis == 0.0 then return end
                
                if dis < 0.01 then
                    if not self.fullyopened then
                        self:FireOutputs("FullyOpened")
                        self.joint:SetMaxTorque(0)
                        self.entity:SetMass(0)
                        self.fullyopened = true
                    end
                end
            end
        else
            if o ~= 0.0 then
                if o < 0.01 then
                    if not self.fullyclosed then
                        self:FireOutputs("FullyClosed")
                        self.entity:SetMass(0)
                        self.joint:SetMaxTorque(0)
                        self.fullyclosed = true
                    end
                end
            end
        end
    end
end

function SwingingDoor:Open()
    if self.openstate then return end
    if not self:GetEnabled() then return end
    
    self.entity:SetMass(self.storedmass)
    
    if not self.joint then 
        self:BuildJoint() 
    end
    
    self.fullyopened = false
    self.fullyclosed = false
    self.openstate = true
    
    local pos = self.entity.position
    -- entity:SetPosition(pos + Vec3(1, 0, 0)) -- Triggers light refreshing early
    -- entity:SetPosition(pos)
    
    self.joint:SetMaxTorque(self.maxforce)
    self.joint:SetPose(self.distance)
    
end

function SwingingDoor:Close()
    if not self.openstate then return end
    if not self:GetEnabled() then return end
    
    self.entity:SetMass(self.storedmass)
    
    if not self.joint then 
        self:BuildJoint() 
    end
    
    self.fullyopened = false
    self.fullyclosed = false
    self.openstate = false
    
    -- self.joint:SetPose(0) -- Uncomment if needed
    local pos = self.entity.position
    self.joint:SetMaxTorque(self.maxforce)
    self.joint:SetPose(0)
    
    -- entity:SetPosition(pos + Vec3(1, 0, 0)) -- Triggers light refreshing early
    -- entity:SetPosition(pos)
    
end

function SwingingDoor:ToggleDoor()
    if self:GetEnabled() then
        if not self.openstate then
            self:Open()
        else
            self:Close()
        end
    end
end

function SwingingDoor:Use(user)
    if self:GetEnabled() then
        if self.openstate then
            self:Close()
        else
            self:Open()
        end
    end
end

function SwingingDoor:Load(properties, binstream, scene, flags, extra)
    if type(properties.openstate) == "boolean" then    
        self.openstate = properties.openstate
        if self.joint then
            if self.openstate then
                self:Open()
            else
                self:Close()
            end
        end
    end
    return true
end

RegisterComponent("SwingingDoor", SwingingDoor)
return SwingingDoor