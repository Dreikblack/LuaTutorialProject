FPSGun = {}
FPSGun.name = "FPSGun"
FPSGun.viewmodelfov = 54
FPSGun.reloading = false
FPSGun.automatic = false
FPSGun.puttingaway = false
FPSGun.getting = false
FPSGun.clipsize = 20
FPSGun.ammo = 2000
FPSGun.loadedammo = FPSGun.clipsize
FPSGun.firetime = 0
FPSGun.muzzleflashsize = 0.05
FPSGun.lastfiretime = 0
FPSGun.muzzleflashduration = 34
FPSGun.inaccuracy = 2

function FPSGun.AnimationDone(name, weapon)
	if weapon then
		weapon.reloading = false;
	end
end

function FPSGun:DetachFromPlayer(playercomponent)
	if muzzlelight then muzzlelight:SetHidden(true) end
	if muzzlesprite then muzzlesprite:SetHidden(true) end
end

function FPSGun:CanReload()
	if self.ammo == 0 then return false end;
	if self.puttingaway or self.getting then return false end
	if self.reloading then return false end
	if self.loadedammo >= self.clipsize then return false end
	if self:GetFiring() then return false end
	return true;
end

function FPSGun:ProcessEvent(e)
    if not self.equipped then return true end

    if e.id == EVENT_MOUSEDOWN then
        if e.data == MOUSE_LEFT then
            if self:CanFire() then
                if self.loadedammo > 0 then
                    self:Fire()
                else
                    if self.sound_empty then self.sound_empty:Play() end
                end
            end
        end
    elseif e.id == EVENT_KEYDOWN then
        if e.data == KEY_R then
            if not self.reloading and not self:GetFiring() then
                self:Reload()
            end
        end
    end

    return true
end

function FPSGun:PlayerCanRun()
    if self.puttingaway or self.getting or self.reloading then return false end
    local world = self.entity:GetWorld()
    if self.world and world:GetTime() < self.firetime then return false end
    return true
end

function FPSGun:CanFire()
    if self.puttingaway or self.getting or self.reloading then return false end
    if self.refirerate > 0 then
        local world = self.entity:GetWorld()
        if world and world:GetTime() < self.firetime then return false end
    end
    return true
end

function FPSGun.HideHook(skeleton, gun)
    local gun = Component(gun)
    gun.puttingaway = false
    local nextweapon = gun.nextweapon
    if nextweapon then
        local entity = gun.playerentity
        local player = entity:GetComponent("Player")
        gun:DetachFromPlayer(player)
        nextweapon:AttachToPlayer(player)
        gun.nextweapon = nil  -- Resetting the next weapon
    end
end

function FPSGun.ReloadHook(skeleton, gun)
    local gun = Component(gun)
	gun.reloading = false;
end

function FPSGun:Start()

    -- Make sure this only gets called once, since some other components may call it early
    if self.started then return end
    self.started = true

    --self.bullets = {}

    -- Now find the model we'll be animating. It's possible that the model will be parented to a pivot.
    local entity = self.entity    
    local model = Model(entity)
    if not model then RuntimeError("FPSGun component must be attached to a model") end

    self.muzzle = entity:FindChild("Muzzle", false)

    entity:SetShadows(false)

    local frame
    local seq = model:FindAnimation("reload")
    if seq ~= 0 then
        frame = model:CountAnimationFrames(seq)
        model.skeleton:AddHook(seq, frame - 1, FPSGun.ReloadHook, self)
    end

    seq = model:FindAnimation("hide")
    if seq ~= 0 then
        frame = model:CountAnimationFrames(seq)
        model.skeleton:AddHook(seq, frame - 1, FPSGun.HideHook, self)
    end

    seq = model:FindAnimation("get")
    if seq ~= 0 then
        frame = model:CountAnimationFrames(seq)
        model.skeleton:AddHook(seq, frame - 1, FPSGun.GetHook, self)
    end

    entity:SetHidden(true)

    local world = entity:GetWorld()
    -- Uncomment and implement particle emitter setup if needed
    -- if self.muzzle and world then
    --     for n = 1, #self.emitters do
    --         self.emitters[n] = CreateParticleEmitter(world, 6)
    --         self.emitters[n]:SetEmissionQuantity(6)
    --         self.emitters[n]:SetEmissionFrequency(800)
    --         self.emitters[n]:SetParticleRadius(0.2, 0.2)
    --         self.emitters[n]:SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0))
    --         self.emitters[n]:SetParticleRandomVelocity(0.15, 0.15, 0)
    --         self.emitters[n]:SetLooping(false)
    --         self.emitters[n]:SetMaterial(LoadMaterial("Materials/Effects/smoke.mat"))
    --         self.emitters[n]:Pause()
    --         self.emitters[n]:SetParent(self.muzzle, false)
    --     end
    -- end

    -- Right now, skip decals. Maybe we want exclusive decals on the gun in the future?
    entity:SetDecalLayers(0, true)
    entity:SetMass(0)
    entity:SetCollider(nil)
    entity:SetPickMode(PICK_NONE)
    entity:SetNavObstacle(false)
    entity:SetCollisionType(COLLISION_NONE)

    -- This ensures the weapon is ready to be drawn
    if model then
       -- model:Animate("get", 1.0, 0, ANIMATION_ONCE, 0)
    end

    -- Listen for events we will use
    self:Listen(EVENT_MOUSEDOWN, nil)
    self:Listen(EVENT_KEYDOWN, nil)
	
end

function FPSGun:GetFiring()
    local entity = self.entity
    local world = entity:GetWorld()
    if world and world:GetTime() < self.firetime then
        return true
    end
    return false
end

function FPSGun:Update()

    --self:UpdateBullets()

    if not self.equipped then return end
    local player = self.playerentity

    local moving = false
    -- local reloading = false

    local entity = self.entity
    local model = Model(entity)

    -- Let's do this before movement...
    local window = ActiveWindow()
    if window then
        --window:SetText(tostring(#self.bullets))
        if self.loadedammo > 0 and self.automatic == true and window:MouseDown(MOUSE_LEFT) == true and self:CanFire() then
            self:Fire()
        end
    end

    if not self.reloading and not self:GetFiring() and not self.getting and not self.puttingaway then
        if player and player:GetAirborne() then
            model:Animate("idle")
        else
            local velo = self.playerentity.velocity.xz:Length()
            if velo > 5.0 then
                if not self.playerentity:GetAirborne() then
                    model:Animate("run")
                    moving = true
                end
            elseif velo > 0.1 then
                model:Animate("walk")
                moving = false
            else
                model:Animate("idle")
            end
        end
    end

    -- Update muzzle flash
    self:UpdateMuzzleLight()
    if self.muzzlelight then
        local world = entity:GetWorld()
        if world:GetTime() > self.lastfiretime + self.muzzleflashduration then
            self.muzzlelight:SetHidden(true)
            if self.muzzlesprite then self.muzzlesprite:SetHidden(true) end
        end
    end
end

--[[
function FPSGun:UpdateBullets()
    local it = 1
    while it <= #self.bullets do
        if self.bullets[it]:GetHidden() then
            table.remove(self.bullets, it)
            it = it - 1
        end
        it = it + 1
    end
end
]]

function FPSGun.CleanupBullet(event)
    local entity = Entity(event.extra)
    entity:SetHidden(true)
    local n
    for n = 1, #entity.components do
        entity.components[n]:Disable()
    end
end

function FPSGun:Load(properties, binstream, scene, flags, extra)
	
	local world = self.entity:GetWorld()

	self.projectile = nil
	self.sound_empty = nil
	self.sound_reload = nil
	self.sound_shoot = nil

	if type(properties.emptysound) == "string" then
		self.sound_empty = LoadSound(properties.emptysound);
	end
	if type(properties.reloadsound) == "string" then
		self.sound_reload = LoadSound(properties.reloadsound);
	end
	if type(properties.firesound) == "string" then
		self.sound_shoot = LoadSound(properties.firesound);
	end
	if type(properties.projectile) == "string" then
		self.projectile = LoadPrefab(world, properties.projectile);
        if self.projectile then
            local n
            for n = 1, #self.projectile.components do
                self.projectile.components[n]:Disable()
            end
        end
	end
	return true
end

function FPSGun:Save(properties, binstream, scene, flags, extra)
	
	if self.projectile then
		local prefab = self.projectile:GetPrefab()
		if prefab then
			properties.projectile = prefab.path
		end
	end

	--[[
	for _, bullet in ipairs(self.bullets) do
		if bullet:GetHidden(false) then 
			goto continue 
		end
		
		if not properties.bullets then 
			properties.bullets = {} 
		end
		
		local t = {}
		-- if not bullet:Save(t, binstream, scene, flags, extra) then return false end
		table.insert(properties["bullets"], t)
	
		::continue::
	end
	]]

	return true
end

function FPSGun:Fire()
    self.loadedammo = self.loadedammo - 1 -- Decrease ammo count
    self.running = false
    local entity = self.entity
    if not entity then return end

    -- Trigger shooting animation
    local model = Model(entity)
    if model then model:Animate("shoot", 1.0, 0, ANIMATION_ONCE) end

    -- Update firing time
    local world = entity:GetWorld()
    if world then
        self.lastfiretime = world:GetTime()
        self.firetime = self.lastfiretime + self.refirerate
    end

    -- Handle muzzle flash and sound
    if self.muzzle then
        if not self.muzzlesprite then
            self.muzzlesprite = CreateSprite(world, self.muzzleflashsize, self.muzzleflashsize)
            self.muzzlesprite:SetHandle(-self.muzzleflashsize * 0.5, -self.muzzleflashsize * 0.5)
            self.muzzlesprite:SetViewMode(SPRITEVIEW_DEFAULT)
            self.muzzlesprite:SetMaterial(LoadMaterial("Materials/Effects/muzzleflash.mat"))
			self.muzzlesprite:SetParent(self.muzzle)
            self.muzzlesprite:SetPosition(0, 0, 0)
        end
        self.muzzlesprite:SetRotation(0, 0, 0)
        self.muzzlesprite:Turn(0, 0, math.random(0, 360))
        self.muzzlesprite:SetHidden(false)
    end

    if not self.muzzlelight then
        self.muzzlelight = CreatePointLight(world)
        self.muzzlelight:SetColor(1 * 2.0, 0.9 * 2.0, 0.6 * 2.0)
        self.muzzlelight:SetShadows(false)
    end

    self.muzzlelight:SetHidden(false)
    if self.sound_shoot then
        self.sound_shoot:Play()
    end

    self:UpdateMuzzleLight()

    if self.muzzle and self.projectile then
        local world = self.muzzle:GetWorld()
        local bullet = self.projectile:Instantiate(world)
        bullet:SetHidden(false)
        bullet:SetColor(0, 1, 0, 1)
        bullet:SetPosition(self.muzzle:GetPosition(true), true)
        bullet:SetRotation(self.muzzle:GetRotation(true), true)
        bullet:Turn(0, 0, math.random(0, 360))
        bullet:Turn(math.random(-self.inaccuracy, self.inaccuracy), 0, 0)

        local n
        for n = 1, #bullet.components do
            bullet.components[n].owner = self.playerentity
        end
        
        --We don't really need any tween effects here, but this will automatically manage the bullet and clean it up after a few seconds
        local t = CreateTween(bullet, 3000, TWEEN_COLOR, Vec4(1))
        ListenEvent(EVENT_TWEENEND, t, FPSGun.CleanupBullet)
        
        --table.insert(self.bullets, bullet) -- Track the bullet
    end

    -- Uncomment if needed for particle emitters
    -- emittercycle = (emittercycle + 1) % #emitters
    -- if emitters[emittercycle] then
    --     emitters[emittercycle]:Reset()
    --     emitters[emittercycle]:Play()
    --     local v = entity:GetVelocity()
    --     v = TransformNormal(v, nil, entity) * v.Length()
    --     emitters[emittercycle]:SetParticleVelocity(v, false)
    -- end
end

function FPSGun:UpdateMuzzleLight()
    if self.muzzlelight then
        local player = self.playerentity:GetComponent("FPSPlayer")
        local pos = player.camera:GetPosition(true) + TransformNormal(0, -0.1, 1, player.camera, nil) * 0.5
        self.muzzlelight:SetPosition(pos)
    end
end

function FPSGun:GetReloading()
    return self.reloading
end

function FPSGun:Reload()
    if self.loadedammo >= self.clipsize then return end
    self.loadedammo = self.loadedammo + math.min(self.ammo, self.clipsize - self.loadedammo)
    self.ammo = math.max(0, self.ammo - self.clipsize)
    self.reloading = true
    local world = self.entity:GetWorld()
    if self.world then
        self.reloadtime = world:GetTime() + reloadspeed
    end
    local model = Model(self.entity)
    model:Animate("reload", 1.0, 250, ANIMATION_ONCE)
    if self.sound_reload then
        self.sound_reload:Play()
    end
end

function FPSGun.GetHook(skeleton, gun)
    local gun = Component(gun)
    gun.getting = false
end 

function FPSGun:DetachFromPlayer(playercomponent)
    local model = Model(self.entity)
    if model then model:StopAnimation() end
    self.entity:SetHidden(true)
    self.entity:SetParent(nil, false)
    self.equipped = false
end

function FPSGun:PutAway()
    self.puttingaway = true
    local entity = self.entity
    if not entity then return end
    local model = Model(entity)
    if model then model:Animate("hide", 2.0, 250, ANIMATION_ONCE) end
end

function FPSGun:GetOut()
    self.getting = true
    local entity = self.entity
    if not entity then return end
    local model = Model(entity)
    if model then
        model:StopAnimation()
        model:Animate("get", 1.0, 0, ANIMATION_STOP, 0)
        model:Animate("get", 2.0, 0, ANIMATION_ONCE, 0)
    end
end

function FPSGun:AttachToPlayer(playercomponent)
    -- Set up the camera for the viewmodel.
    self:Start()

    local entity = self.entity
    local world = entity:GetWorld()

    local player = playercomponent
    if player then
        local playercam = player.camera
        if playercam then
            playercam:SetRange(0.01, playercam:GetRange().y)
            entity:SetParent(playercam, false)
        end

        entity:SetHidden(false)
        player.weapon = self
        self.equipped = true
        self.playerentity = player.entity

        local model = Model(entity)
        if model then
            self:GetOut()
        end
    end
end

function FPSGun:PlayerCanRun()
    return true
end

RegisterComponent("FPSGun", FPSGun)
return FPSGun