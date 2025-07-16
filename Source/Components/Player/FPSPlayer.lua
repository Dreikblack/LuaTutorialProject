FPSPlayer = {}
FPSPlayer.name = "FPSPlayer"
FPSPlayer.sound_step = {}
FPSPlayer.sound_hit = {}
FPSPlayer.freelookstarted = false
FPSPlayer.freelookmousepos = Vec3(0)
FPSPlayer.freelookrotation = Vec3(0)
FPSPlayer.lookchange = Vec2(0)
FPSPlayer.mousedelta = Vec2(0)
FPSPlayer.currentcameraposition = Vec3(0)
FPSPlayer.lastfootsteptime = 0
FPSPlayer.jumpkey = false
FPSPlayer.running = false
FPSPlayer.lean = 0
FPSPlayer.health = 100
FPSPlayer.maxlean = 0
FPSPlayer.leanspeed = 1
FPSPlayer.camerashakerotation = Quat(0,0,0,1)
FPSPlayer.smoothedcamerashakerotation = Quat(0,0,0,1)
FPSPlayer.flashlightrotation = Quat(0,0,0,1)
FPSPlayer.weapons = {}
FPSPlayer.initialslot = 0
FPSPlayer.movement = Vec3(0)

function FPSPlayer:Start()

    local entity = self.entity
    local world = entity:GetWorld()

    -- Store the position into 
    self.currentcameraposition = self.camera:GetPosition(true)

	-- Set the physics mode to PHYSICS_PLAYER, this will enable the character controller.
	self.entity:SetPhysicsMode(PHYSICS_PLAYER)

	-- If the mass happens to be 0, force set the mass to a default value.
	if self.entity:GetMass() == 0.0 then self.entity:SetMass(78) end

	-- Set the collision type to  COLLISION_PLAYER
	self.entity:SetCollisionType(COLLISION_PLAYER)

	-- Disable shadows
	self.entity:SetShadows(false)

	-- Never render this entity!
	self.entity:SetRenderLayers(0)

	self.entity:SetNavObstacle(false)

	if self.navmesh ~= nil then
		self.agent = CreateNavAgent(self.navmesh, 0.25, 1.8)
		self.agent:SetPosition(self.entity:GetPosition(true))
    end
	
	self.flashlightrotation = self.camera:GetQuaternion(true)

	-- Listen for window events we want to use
	self:Listen(EVENT_KEYDOWN, nil)
	self:Listen(EVENT_KEYUP, nil)

    local n
	for n = 1, 3 do
        if FileType("Sound/Impact/bodypunch" .. tostring(n) .. ".wav") == 1 then
        	self.sound_hit[n] = LoadSound("Sound/Impact/bodypunch" .. tostring(n) .. ".wav")    
        end
	end
    self.sound_jump = LoadSound("Sound/Footsteps/Concrete/jump.wav")
	sound_flashlight = LoadSound("Sound/Items/flashlightswitch.wav")
	for n = 1, 4 do
		self.sound_step[n] = LoadSound("Sound/Footsteps/Concrete/step" .. tostring(n)  .. ".wav")
    end

	local scale = 0.25
	local points = {}

    -- Add corners for a cube
    table.insert(points, Vec3(0.5, 0.5, 0.5) * scale)
    table.insert(points, Vec3(-0.5, 0.5, 0.5) * scale)
    table.insert(points, Vec3(0.5, -0.5, 0.5) * scale)
    table.insert(points, Vec3(-0.5, -0.5, 0.5) * scale)
    table.insert(points, Vec3(0.5, 0.5, -0.5) * scale)
    table.insert(points, Vec3(-0.5, 0.5, -0.5) * scale)
    table.insert(points, Vec3(0.5, -0.5, -0.5) * scale)
    table.insert(points, Vec3(-0.5, -0.5, -0.5) * scale)

    -- Add some points sticking out so the shape rolls a little bit
    table.insert(points, Vec3(0.0, 0.0, -0.667) * scale)
    table.insert(points, Vec3(0.0, 0.0, 0.667) * scale)
    table.insert(points, Vec3(0.0, -0.667, 0.0) * scale)
    table.insert(points, Vec3(0.0, 0.667, 0.0) * scale)
    table.insert(points, Vec3(-0.667, 0.0, 0.0) * scale)
    table.insert(points, Vec3(0.667, 0.0, 0.0) * scale)

	deadbodycollider = CreateConvexHullCollider(points);

	self.entity:AddTag("player")
    self.entity:AddTag("good")
    self.entity.health = 100

end

function FPSPlayer:Kill(attacker)
    self.camera:SetParent(nil)
    self.camera:SetCollider(deadbodycollider)
    self.camera:SetVelocity(self.entity:GetVelocity())
    self.camera:SetMass(10)
    self.camera:SetCollisionType(COLLISION_DEBRIS)
    self.camera:AddTorque(50, Random(-20, 20), Random(-20, 20))

    if self.weapon then
        self.weapon:DetachFromPlayer(self)
    end

    self.weapon = nil
    self.entity:SetMass(0)
    self.entity:SetCollisionType(COLLISION_NONE)
    self.entity:SetCollider(nil)
    self.entity:SetPhysicsMode(PHYSICS_DISABLED)

    if self.flashlight then
        self.flashlight:SetHidden(true)
    end

    self:Disable()
end

function FPSPlayer:ToggleFlashlight()
    if self.flashlight == nil or self.flashlight:GetHidden() then
        self:ShowFlashlight()
    else
        self:HideFlashlight()
    end
end

function FPSPlayer:ShowFlashlight()
    if self.sound_flashlight then 
        self.sound_flashlight:Play() 
    end

    if self.flashlight == nil or self.flashlight:GetHidden() then
        if self.flashlight == nil then
            local world = self.entity:GetWorld()
            self.flashlight = CreateSpotLight(world)
            self.flashlight:SetConeAngles(20, 10)
            self.flashlight:SetRange(0.01, 10)
        end
        self.flashlightrotation = self.camera:GetQuaternion(true)
        self.flashlight:SetHidden(false)
        self:UpdateFlashlight()
        self:FireOutputs("ShowFlashlight")
    end
end

function FPSPlayer:HideFlashlight()
    if self.flashlight then
        self.flashlight:SetHidden(true)
        self:FireOutputs("HideFlashlight")
    end
end

function FPSPlayer:ProcessEvent(e)
    if not self:GetEnabled() then return true end
    if self.entity.health <= 0 then return true end

    local world = self.entity:GetWorld()

    if e.id == EVENT_KEYDOWN then
        if e.data == KEY_SPACE then
            self.jumpkey = true
        elseif e.data == KEY_SHIFT then
            -- if self.weapon and not self.weapon:PlayerCanRun() then return true end
            -- self.running = true
        elseif e.data == KEY_F then
            self:ToggleFlashlight()
        elseif e.data == KEY_E then
            if world then
                local pos = self.entity:GetPosition(true)
                local bounds = Aabb(pos - 2.0, pos + 2.0)
                local entities = world:GetEntitiesInArea(bounds.min, bounds.max)
                for _, e in ipairs(entities) do
                    if e == entity then goto continue end
                    for _, c in ipairs(e.components) do
                        if c.Use and type(c.Use) == "function" and c:GetEnabled() then
                            c:Use(entity)
                        end
                    end
                    ::continue::
                end
            end
        end
    elseif e.id == EVENT_KEYUP then
        if e.data == KEY_SPACE then
            self.jumpkey = false
        elseif e.data == KEY_SHIFT then
            -- self.running = false
        end
    end
    return true
end

function FPSPlayer:UnCrouchFilter(entity, extra)
    if self.entity == extra then
        return false
    end
    if entity:GetCollider() == nil or entity:GetCollisionType() == COLLISION_NONE or entity:GetCollisionType() == COLLISION_TRIGGER then
        return false
    end
    return true
end

function FPSPlayer:Load(properties, binstream, scene, flags, extra)
    properties.health = self.entity.health
end

function FPSPlayer:Load(properties, binstream, scene, flags, extra)
    local world = self.entity:GetWorld()
    local entity = self.entity

	self.weapons = {}
	for n = 0, 3 do
        local key = "slot" .. tostring(n)
		if type(properties[key]) == "string" and properties[key] ~= "" then
			local path = properties[key]
            local prefab = LoadPrefab(world, path)
			self.weapons[n + 1] = prefab
        end
    end
    
    if not self.camera then
        self.camera = CreateCamera(world)
        self.camera:Listen()
    end

    local pos = entity:GetPosition(true)
    self.camera:SetPosition(pos.x, pos.y + self.eyeheight, pos.z)
    self.camera:SetRotation(0, 0, 0)
    self.camera:SetFov(self.fov)

    if type(self.selectedslot) ~= "number" then
        self.selectedslot = self.initialslot + 1
    end
    if self.weapons[self.selectedslot] then
        local entity = self.weapons[self.selectedslot]
        local weapon = entity:GetComponent("FPSGun")
        if not weapon then weapon = entity:GetComponent("FPSMelee") end
        if weapon then weapon:AttachToPlayer(self) end
    end

    local n
    for n = 1, #scene.navmeshes do
        self.navmesh = scene.navmeshes[n]
    end

    entity.health = self.health
    self.health = nil

    return true
end

function FPSPlayer:Update()
    if not self:GetEnabled() then return end
    if self.entity.health <= 0 then return end

    -- Disable running if it is not allowed
    if self.running and self.weapon and not self.weapon:PlayerCanRun() then
        self.running = false
    end
    self.movement = Vec3(0, 0, 0)

    local jump = 0
    local crouchkey = false
    local crouched = false

    local entity = self.entity
    local world = entity:GetWorld()
    local window = ActiveWindow()

    if window then
        self.running = window:KeyDown(KEY_SHIFT)

        local framebuffer = window:GetFramebuffer()
        local fbsize = framebuffer:GetSize()

        local cx = Round(fbsize.x / 2)
        local cy = Round(fbsize.y / 2)
        local mpos = window:GetMousePosition()
        window:SetMousePosition(cx, cy)
        local centerpos = window:GetMousePosition()

        if self.freelookstarted then
            local looksmoothing = self.mousesmoothing
            local lookspeed = self.mouselookspeed / 10.0

            local dx = mpos.x - centerpos.x
            local dy = mpos.y - centerpos.y

            if looksmoothing > 0.0 then
                self.mousedelta.x = CurveValue(dx, self.mousedelta.x, 1.0 + looksmoothing)
                self.mousedelta.y = CurveValue(dy, self.mousedelta.y, 1.0 + looksmoothing)
            else
                self.mousedelta.x = dx
                self.mousedelta.y = dy
            end

            self.freelookrotation.x = Clamp(self.freelookrotation.x + self.mousedelta.y * lookspeed, -90.0, 90.0)
            self.freelookrotation.y = self.freelookrotation.y + self.mousedelta.x * lookspeed
            self.camera:SetRotation(self.freelookrotation, true)
            self.freelookmousepos = Vec3(mpos.x, mpos.y)
        else
            self.freelookstarted = true
            self.freelookrotation = self.camera:GetRotation(true)
            self.freelookmousepos = Vec3(window:GetMousePosition().x, window:GetMousePosition().y)
            window:SetCursor(CURSOR_NONE)
        end

        if window:KeyHit(KEY_G) then
            local a = Random(360.0)
            self.camerashakerotation = Quat(Vec3(Cos(a) * 30.0, Sin(a) * 30.0, 0.0))
        end

        -- Camera shake when hit
        local speed = 0.1
        local q = Vec4(self.camerashakerotation.x, self.camerashakerotation.y, self.camerashakerotation.z, self.camerashakerotation.w)
        local diff = q:Length()
        self.camerashakerotation = self.camerashakerotation:Slerp(Quat(0, 0, 0, 1), math.min(1.0, speed / diff))
        self.smoothedcamerashakerotation = self.smoothedcamerashakerotation:Slerp(self.camerashakerotation, 0.5)
        self.camera:Turn(self.smoothedcamerashakerotation:ToEuler(), false)

        -- We use the base class' enabled bool to lock the movement.
        if self:GetEnabled() then
            local speed = self.movespeed
            crouchkey = window:KeyDown(KEY_C)
            if entity:GetAirborne() then
                speed = speed * 0.25
            else
                if self.running then
                    speed = speed * 2.0
                elseif crouched then
                    speed = speed * 0.5
                end

                if self.jumpkey and not crouched then
                    jump = self.jumpforce
                    if self.sound_jump then self.sound_jump:Play() end
                end
            end

            if window:KeyDown(KEY_D) then self.movement.x = self.movement.x + speed end
            if window:KeyDown(KEY_A) then self.movement.x = self.movement.x - speed end
            if window:KeyDown(KEY_W) then self.movement.z = self.movement.z + speed end
            if window:KeyDown(KEY_S) then self.movement.z = self.movement.z - speed end
            if self.movement.x ~= 0.0 and self.movement.z ~= 0.0 then
                self.movement = self.movement * 0.707
            end
            if jump ~= 0.0 then
                self.movement.x = self.movement.x * self.jumplunge
                if self.movement.z > 0.0 then
                    self.movement.z = self.movement.z * self.jumplunge
                end
            end
        end
    end

    entity:SetInput(self.camera.rotation.y, self.movement.z, self.movement.x, jump, crouchkey)

    if self.agent then self.agent:SetPosition(entity:GetPosition(true)) end

    local eye = self.eyeheight
    if entity:GetCrouched() then
        if not entity:GetAirborne() then eye = self.croucheyeheight end
        crouched = true
    else
        eye = self.eyeheight
        crouched = false
    end

    local y = TransformPoint(self.currentcameraposition, nil, entity).y
    local h = eye
    if not entity:GetAirborne() and (y < eye or eye ~= self.eyeheight) then
        h = Mix(y, eye, 0.25)
    end
    self.currentcameraposition = TransformPoint(0, h, 0, entity, nil)
    self.camera:SetPosition(self.currentcameraposition, true)

    if self.maxlean > 0.0 then
        local localpos = TransformPoint(self.camera:GetPosition(true), nil, entity)
        if window:KeyDown(KEY_E) then self.lean = self.lean - self.leanspeed end
        if window:KeyDown(KEY_Q) then self.lean = self.lean + self.leanspeed end
        self.lean = Clamp(self.lean, -self.maxlean, self.maxlean)
        if self.lean ~= 0.0 then
            self.camera:SetPosition(entity:GetPosition(true), true)
            local r = self.camera:GetRotation(true)
            self.camera:SetRotation(0, r.y, 0, true)
            self.camera:Turn(0, 0, self.lean)
            self.camera:Move(localpos)
            self.camera:Turn(r.x, 0, 0)
        end
        if not window:KeyDown(KEY_E) and not window:KeyDown(KEY_Q) then
            if self.lean > 0.0 then
                self.lean = self.lean - self.leanspeed
                self.lean = math.max(self.lean, 0.0)
            elseif self.lean < 0.0 then
                self.lean = self.lean + self.leanspeed
                self.lean = math.min(self.lean, 0.0)
            end
        end
    end

    self:UpdateFlashlight()
    self:UpdateFootsteps()

    self.jumpkey = false
end

function FPSPlayer:UpdateFootsteps()
    local entity = self.entity
    local world = entity:GetWorld()
    if not world then return end
    if not entity:GetAirborne() and self.movement:Length() > 0.0 then
        local now = world:GetTime()
        local speed = entity:GetVelocity().xz:Length()
        local footsteptime = Clamp(500.0 * self.movespeed / speed, 250.0, 1000.0)
        if now - self.lastfootsteptime > footsteptime and #self.sound_step > 0 then
            self.lastfootsteptime = now
            local index = Floor(math.random(1, #self.sound_step))
            if self.sound_step[index] then self.sound_step[index]:Play() end
        end
    end
end

function FPSPlayer:UpdateFlashlight()
    if self.flashlight then
        local pos = self.camera:GetPosition(true)
        pos = pos + TransformNormal(0, -1, 0, self.camera, nil) * 0.25
        pos = pos + TransformNormal(1, 0, 0, self.camera, nil) * 0.25
        self.flashlight:SetPosition(pos, true)
        self.flashlightrotation = self.flashlightrotation:Slerp(self.camera:GetQuaternion(true), 0.2)
        self.flashlight:SetRotation(self.flashlightrotation, true)
    end
end

function FPSPlayer:Damage(amount, attacker)
    local a = math.random() * 360.0
    self.camerashakerotation = Quat(Vec3(math.cos(a) * 45.0, math.sin(a) * 45.0, 0.0))
    if #self.sound_hit > 0 then
        local index = Floor(math.random(1, #self.sound_hit))
        if self.sound_hit[index] then
            self.sound_hit[index]:Play()
        end
    end
end

RegisterComponent("FPSPlayer", FPSPlayer)
return FPSPlayer