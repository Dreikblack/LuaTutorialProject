Bullet = {}
Bullet.name = "Bullet"
Bullet.damage = 10
Bullet.decalmaterial = LoadMaterial("Materials/Decals/Bullet Holes/Concrete/bullethole_concrete.mat");
Bullet.smokematerial = LoadMaterial("Materials/Particles/smoke.mat");

function Bullet.PickFilter(entity, extra)
    local ctype = entity:GetCollisionType()
    if ctype == COLLISION_PROP or ctype == COLLISION_PLAYER or ctype == COLLISION_SCENE then
        return entity ~= extra
    else
        return false
    end
end

function Bullet.Cleanup(event)
    local entity = Entity(event.extra)
    entity:SetParent(nil)
    entity:SetHidden(true)
    entity:SetCollisionType(0)
end

function Bullet:Start()
    local entity = self.entity
    entity:SetNavObstacle(false)
    entity:SetGravityMode(false)
    entity:SetMass(0)
    entity:SetCollisionType(COLLISION_NONE)
    entity:SetPickMode(PICK_NONE)

    local world = entity:GetWorld()

    self.decal = CreateDecal(world)
    self.decal:SetMaterial(self.decalmaterial)
    self.decal:SetScale(0.08)

    self.emitters = {}
    self.emitters[1] = CreateParticleEmitter(world, 10)
    self.emitters[1]:SetEmissionQuantity(10)
    self.emitters[1]:SetEmissionFrequency(800)
    self.emitters[1]:SetParticleRadius(0.1, 0.5)
    self.emitters[1]:SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0))
    self.emitters[1]:SetParticleRandomVelocity(0.5, 0.5, 0.5)
    self.emitters[1]:SetLooping(false)
    self.emitters[1]:SetMaterial(self.smokematerial)
    self.emitters[1]:Pause()
    self.emitters[1]:SetHidden(true)

    -- TODO - Ricochet debris particles
    --[[
    self.emitters[2] = CreateParticleEmitter(world, 10)
    self.emitters[2]:SetEmissionQuantity(10)
    self.emitters[2]:SetEmissionFrequency(500)
    self.emitters[2]:SetParticleTurbulence(0)
    self.emitters[2]:SetParticleRadius(0.25, 0.25)
    self.emitters[2]:SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0))
    self.emitters[2]:SetParticleAcceleration(0, -9.8, 0)
    self.emitters[2]:SetParticleRandomVelocity(3, 3, 3)
    self.emitters[2]:SetLooping(false)
    self.emitters[2]:SetMaterial(LoadMaterial("Materials/Particles/bulletfragments.mat"))
    self.emitters[2]:Pause()
    self.emitters[2]:SetHidden(true)
    ]]
end

function Bullet:Load(properties, binstream, scene, flags, extra)
    self.impactsounds = {}
    for n = 1, 3 do
        local key = "impactsound" .. tostring(n)
        if properties[key] and type(properties[key]) == "string" then
            local impactsoundpath = properties[key]
            if impactsoundpath ~= "" then
                local sound = LoadSound(impactsoundpath)
                if sound then
                    table.insert(self.impactsounds, sound)
                end
            end
        end
    end
    return true
end

function Bullet:Save(properties, binstream, scene, flags, extra)
	for n = 1, #self.impactsounds do
		if self.impactsounds[n] then
			local key = "impactsound" .. tostring(n)
			properties[key] = self.impactsounds[n].path
		end
	end
    return true
end

function Bullet:Update()
    
    local entity = self.entity
    
    local world = entity:GetWorld()
    if not world then return end

    local pos = entity:GetPosition(true)
    local nextpos = pos + TransformNormal(0, 0, 1, entity, nil) * self.speed / 60.0

    local pickinfo = world:Pick(pos, nextpos, 0.0, true, Bullet.PickFilter, self.owner)
    if pickinfo.entity then
        self:Disable()
        
        if pickinfo.entity:GetMass() > 0.0 then
            local force = 20.0
            pickinfo.entity:AddPointForce((nextpos - pos):Normalize() * force, pickinfo.position)
        end

		local n
        if type(pickinfo.entity.health) == "number" then
            pickinfo.entity.health = pickinfo.entity.health - self.damage
            for n = 1, #pickinfo.entity.components do
                if type(pickinfo.entity.components[n].Damage) == "function" then
                    pickinfo.entity.components[n]:Damage(self.damage, entity)
                end
                if pickinfo.entity.health <= 0 and type(pickinfo.entity.components[n].Kill) == "function" then
                    pickinfo.entity.components[n]:Kill()
                end
            end
        end
        
        entity:SetPosition(pickinfo.position)
        entity:SetHidden(true)

        -- Bullet hole decal
        self.decal:SetPosition(pickinfo.position, true)
        local scale = self.decal.scale
        scale = scale / TransformVector(1, 0, 0, nil, pickinfo.entity):Length()
        self.decal:SetParent(pickinfo.entity)
        self.decal:SetScale(scale)
        self.decal:SetHidden(false)
        self.decal:AlignToVector(pickinfo.normal)
        self.decal:Turn(0.0, 0.0, Random(360.0))

        -- Smoke particles
        self.emitters[1]:SetPosition(pickinfo.position)
        self.emitters[1]:SetParticleVelocity(pickinfo.normal)
        self.emitters[1]:SetHidden(false)
        self.emitters[1]:Play()

        --[[
        --TODO: Add ricochet / chunks
        self.emitters[2]:SetPosition(pickinfo.position)
        self.emitters[2]:SetParticleVelocity(pickinfo.normal * 4.0)
        self.emitters[2]:SetHidden(false)
        self.emitters[2]:Play()
        ]]

        self.decal:SetColor(1,1,1,4)
        local t = CreateTween(self.decal, 8000, TWEEN_COLOR, Vec4(1, 1, 1, 0))
        ListenEvent(EVENT_TWEENEND, t, Bullet.Cleanup)
        
        t = CreateTween(self.emitters[1], 800, TWEEN_COLOR, Vec4(1))
        ListenEvent(EVENT_TWEENEND, t, Bullet.Cleanup)

        if #self.impactsounds > 0 then
            local index = Floor(Random(1, #self.impactsounds))
            local sound = self.impactsounds[index]
            if sound then entity:EmitSound(sound) end
        end
    else
        entity:SetPosition(nextpos)
    end
end

RegisterComponent("Bullet", Bullet)
return Bullet