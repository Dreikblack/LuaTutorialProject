Monster = {}
Monster.name = "Monster"
Monster.team = 2
Monster.alive = true
Monster.nextscanfortargettime = 0
Monster.scanrange = 100
Monster.eyeheight = 1.65
Monster.sound_attack = {}
Monster.navmeshindex = 1
Monster.damage = 20
Monster.health = 100
Monster.meleedamage = 20

function Monster:Enable()
    if self.sound_alert then self.sound_alert:Play() end
     Component(self):Enable()
end

function Monster:Start()
    local entity = self.entity
    local model = Model(entity)

    entity.team = self.team
    entity.health = self.health
    self.health = nil

    if model then
        local seq = model:FindAnimation("attack1")
        if seq ~= 0 then
            local count = model:CountAnimationFrames(seq)
            model.skeleton:AddHook(seq, count - 1, Monster.EndAttackHook, self)
        end
        
        seq = model:FindAnimation("attack2")
        if seq ~= 0 then
            local count = model:CountAnimationFrames(seq)
            model.skeleton:AddHook(seq, count - 1, Monster.EndAttackHook, self)
        end
    end
    
    if self.navmesh then
        self.agent = CreateNavAgent(self.navmesh, 0.5, 1.8)
        self.agent:SetPosition(entity:GetPosition(true))
        self.agent:SetRotation(entity:GetRotation(true).y)
        entity:SetPosition(0, 0, 0)
        entity:SetRotation(0, 180, 0)
        entity:Attach(self.agent)
    end
    
    entity:SetNavObstacle(false)
    entity:SetCollisionType(COLLISION_PLAYER)
    entity:SetMass(0)
    entity:SetPhysicsMode(PHYSICS_RIGIDBODY)

    entity:AddTag("player")
end

function Monster:Load(properties, binstream, scene, flags, extra)

    if type(properties.alertsound) == "string" then
        self.sound_alert = LoadSound(properties.alertsound)
    end

    for n = 1, 2 do
        local key = "attacksound" .. tostring(n)
        if type(properties[key]) == "string" then
            self.sound_attack[n] = LoadSound(properties[key])
        end
    end

    self.navmesh = nil
    if #scene.navmeshes > 0 then
        self.navmesh = scene.navmeshes[self.navmeshindex]
    end

    return true
end

function Monster.EndAttackHook(skeleton, monster)  
    -- Uncomment the following block if you want to implement the attack logic
    -- if not monster.attackfinished then
    --     monster.attackfinished = true
    --     local target = monster.target:lock()
    --     local entity = monster:GetEntity()
    --     local attackrange = 2.5
    --     if entity:GetDistance(target) < attackrange then
    --         for _, c in ipairs(target.components) do
    --             local base = c:As("BaseComponent")
    --             if base then base:Damage(1, entity) end
    --         end
    --     end
    -- end
    local monster = Component(monster)
    monster.attacking = false
end

function Monster:Damage(amount, attacker)
    if self.entity.health <= 0 then return end
    if self.entity.health <= 0 then
        local n
        --[[for n = 1, #self.entity.components do
            if type(self.entity.components[n].Kill) == "function" then
                self.entity.components[n]:Kill(attacker)
            end
        end]]
        return
    end
    if self.target == nil and attacker ~= self.entity then self.target = attacker end --Make him angry if someone hurts him!    
end

function Monster:Kill()
    if not self.alive then return end
    local model = Model(self.entity)
    self.alive = false
    if model then model:Animate("death", 1, 250, ANIMATION_ONCE) end
    if self.agent then
        self.agent:Stop()
        self.entity:Detach()
        self.agent = nil
    end
    self.entity:SetCollisionType(COLLISION_NONE)
    self.entity:SetPickMode(PICK_NONE)
    self:Disable()
end

function Monster:Update()
    if self.entity.health <= 0 then
        self:Disable()
        return
    end    
    
    local entity = self.entity   
        
    local model = Model(self.entity)

    -- Stop attacking if target is dead
    if self.target then
        if self.target.health ~= nil and type(self.target.health) == "number" and self.target.health <= 0 then
            self.target = nil
            if self.agent then self.agent:Stop() end
        end
    end

    if self.attacking and self.target then
        if self.agent then
            local a = ATan(entity.matrix.t.x - self.target.matrix.t.x, entity.matrix.t.z - self.target.matrix.t.z)
            self.agent:SetRotation(a + 180)
        end
        if not self.attackfinished then
            local world = self.entity:GetWorld()
            if world then
                if world:GetTime() - self.meleeattacktime > 300 then
                    self.attackfinished = true
                    local pos = entity:GetPosition(true)
                    local dest = self.target:GetPosition(true) + self.target:GetVelocity()
                    local attackrange = 3.0
                    if pos:DistanceToPoint(dest) < attackrange then
                        self.target.health = self.target.health - self.meleedamage
                        for _, c in ipairs(self.target.components) do
                            if c.Damage and type(c.Damage) == "function" then
                                c:Damage(self.meleedamage, entity)
                                if self.target.health <= 0 and type(c.Kill) == "function" then
                                    c:Kill(entity)
                                end
                            end
                        end
                        if self.target.health <= 0 then
                            self.target = nil
                        end
                    end
                end
            end
        end
        return
    end
    
    if not self.target then self:ScanForTarget() end

    if self.target then
        if self.attacking == false and entity:GetDistance(self.target) > 3.0 then
            if self.agent then
                self.agent:Navigate(self.target:GetPosition(true))
                self.agent:SetMaxSpeed(6)
            end
            if model then
                model:Animate("run")
            end
        else
            if self.agent then self.agent:Stop() end
            if not self.attacking then
                local world = entity:GetWorld()
                if world then self.meleeattacktime = world:GetTime() end
                local index = Ceil(math.random(1, 2))
                if model then model:Animate("attack" .. tostring(index), 1, 100, ANIMATION_ONCE) end
                if Ceil(Random(0, 2)) == 0 then
                    index = Ceil(Random(1, 2))
                    if self.sound_attack[index] then entity:EmitSound(self.sound_attack[index]) end
                end
                self.attacking = true
                self.attackfinished = false
            end
        end
    else
        if model then model:Animate("idle", 1.0, 250, ANIMATION_LOOP, math.random(1000)) end
    end
end

function Monster.RayFilter(entity, extra)
    local ctype = entity:GetCollisionType()
    return ctype == COLLISION_SCENE or ctype == COLLISION_PROP
end

function Monster:ScanForTarget()
    local entity = self.entity
    local world = entity:GetWorld()
    if world then
        -- We only want to perform this about twice each second, staggering the operation between different entities
        local now = world:GetTime()
        if now < self.nextscanfortargettime then
            return
        end
        self.nextscanfortargettime = now + math.random(300, 500)

        local temp = entity:GetPickMode()
        entity:SetPickMode(PICK_NONE)

        local opposingteam = "good"
        local players = world:GetTaggedEntities("good")
        local dist
        for _, player in ipairs(players) do
            if player.health ~= nil and type(player.health) == "number" and player.health > 0 then                
                dist =player:GetDistance(entity)
                if dist < self.scanrange then             
                    local temp2 = player:GetPickMode()
                    player:SetPickMode(PICK_NONE)
                    local A = self.entity:GetPosition(true) + Vec3(0, self.eyeheight, 0)
                    local B =  player:GetPosition(true)
                    B.y = B.y + 0.5
                    local pick = world:Pick(A, B, 0, false)
                    player:SetPickMode(temp2)
                    if not pick.success then
                        self.target = player
                        if self.sound_alert then self.entity:EmitSound(self.sound_alert, 50) end
                        break
                    end
                end
            end
        end
        entity:SetPickMode(temp)
    end
end

function Monster:Save(properties, binstream, scene, flags, extra)
    properties.health = self.entity.health
end

RegisterComponent("Monster", Monster)
return Monster