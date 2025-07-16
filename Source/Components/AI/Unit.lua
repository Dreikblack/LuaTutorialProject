Unit = {}
Unit.name = "Unit"
Unit.team = 0 -- 0 neutral, 1 player team, 2 enemy
Unit.isPlayer = false
-- so it could be added for entity with FPS Player component
Unit.isFullPlayerControl = false
Unit.health = 100
Unit.maxHealth = 100
-- used for AI navigation
Unit.navMesh = nil
-- NavAgent used to create to plot navigation paths in NavMesh
Unit.agent = nil
-- how far AI see its enemies in meters
Unit.perceptionRadius = 10
-- how long to pursue when out of radius
Unit.chaseMaxDistance = Unit.perceptionRadius * 2
-- is target a priority
Unit.isForcedTarget = false
-- target to follow and attack if possible
Unit.targetWeak = nil
-- to avoid fighting
Unit.isForcedMovement = false
-- which distance to point should be to reach it
Unit.targetPointDistance = 0.5
-- place to reach
Unit.targetPoint = nil
-- is attack animation playing
Unit.isAttacking = false
-- when attack started
Unit.meleeAttackTime = 0
-- do damage in meleeAttackTiming after attack start
Unit.attackFrame = 5
Unit.attackRange = 2.0
Unit.attackDamage = 30
-- pain/git hit state
Unit.isInPain = false
-- can't start new pain animation immediately to avoid infinite stugger
Unit.painCooldown = 300
-- when pain animation started
Unit.painCooldownTime = 0
-- how fast unit is
Unit.speed = 3.0
-- when to try scan again
Unit.nextScanForTargetTime = 0
-- health bar above unit
Unit.healthBar = nil
Unit.healthBarBackground = nil
Unit.isSelected = false
-- to keep camera pointer for unit health bars
Unit.camera = nil
-- to be able to remove entity inside of component later
Unit.sceneWeak = nil
-- time in ms before delete model after a death, 0 of disabled
Unit.decayTime = 10000
Unit.removeEntityTimer = nil
-- animations
Unit.attackName = "Attack"
Unit.idleName = "Idle"
Unit.painName = "Pain"
Unit.deathName = "Death"
Unit.runName = "Run"

function Unit:Start()
    local entity = self.entity
    local model = Model(entity)
    entity:AddTag("Unit")
    -- for custom save/load system
    entity:AddTag("Save")
    if (self.isFullPlayerControl == false) then
        if (self.navMesh ~= nil) then
            -- 0.5 m radius because of Beast long model, 0.5 would better otherwise, 2 m height
            self.agent = CreateNavAgent(self.navMesh, 0.5, 2)
            self.agent:SetMaxSpeed(self.speed)
            self.agent:SetPosition(entity:GetPosition(true))
            self.agent:SetRotation(entity:GetRotation(true).y)
            self.entity:SetPosition(0, 0, 0)
            -- becase models rotated by back
            self.entity:SetRotation(0, 180, 0)
            self.entity:Attach(self.agent)
        end
        entity:SetCollisionType(COLLISION_PLAYER)
        entity:SetMass(0)
        entity:SetPhysicsMode(PHYSICS_RIGIDBODY)
    end
    if (model ~= nil) then
        local seq = model:FindAnimation(self.attackName)
        if (seq ~= -1) then
            local count = model:CountAnimationFrames(seq)
            -- to disable attack state at end of attack animation
            model.skeleton:AddHook(seq, count - 1, Unit.EndAttackHook, self)
            -- to deal damage to target at range at specific animation frame
            model.skeleton:AddHook(seq, self.attackFrame, Unit.AttackHook, self)
        end
        seq = model:FindAnimation(self.painName)
        if (seq ~= -1) then
            local count = model:CountAnimationFrames(seq)
            -- to disable pain state at end of pain animation
            model.skeleton:AddHook(seq, count - 1, Unit.EndPainHook, self)
        end
        if (self.health <= 0) then
            seq = model:FindAnimation(self.deathName)
            local count = model:CountAnimationFrames(seq)
            model:Animate(self.deathName, 1.0, 250, ANIMATION_ONCE, count - 1)
        end
    end
    local world = entity:GetWorld()
    local cameras = world:GetTaggedEntities("Camera")
    for i = 1, #cameras do
        if (Camera(cameras[i]) ~= nil) then
            self.camera = Camera(cameras[i])
            break
        end
    end
    if (self.camera == nil) then
        local entities = world:GetEntities()
        for i = 1, #entities do
            if (Camera(entities[i]) ~= nil) then
                self.camera = Camera(entities[i])
                break
            end
        end
    end
    if (self.isFullPlayerControl == false) then
        local healthBarHeight = 5
        self.healthBar = CreateTile(self.camera, self.maxHealth, healthBarHeight)
        if (self.team == 1) then
            self.healthBar:SetColor(0, 1, 0)
        else
            self.healthBar:SetColor(1, 0, 0)
        end
        self.healthBar:SetPosition(0, 0)
        self.healthBarBackground = CreateTile(self.camera, self.maxHealth, healthBarHeight)
        self.healthBarBackground:SetColor(0.1, 0.1, 0.1)
        self.healthBar:SetScale(self.health / self.maxHealth, 1)
        -- to put it behind health bar
        self.healthBarBackground:SetOrder(0)
        self.healthBar:SetOrder(1)
    end
end

function Unit:Load(properties, binstream, scene, flags, extra)
    self.sceneWeak = scene
    self.navMesh = nil
    if #scene.navmeshes > 0 then
        self.navMesh = scene.navmeshes[1]
    end
    if type(properties.isFullPlayerControl) == "boolean" then
        self.isFullPlayerControl = properties.isFullPlayerControl
    end
    if type(properties.isPlayer) == "boolean" then
        self.isPlayer = properties.isPlayer
    end
    if type(properties.isSelected) == "boolean" then
        self.isSelected = properties.isSelected
    end
    if type(properties.team) == "number" then
        self.team = properties.team
    end
    if type(properties.health) == "number" then
        self.health = properties.health
    end
    if type(properties.maxHealth) == "number" then
        self.maxHealth = properties.maxHealth
    end
    if type(properties.attackDamage) == "number" then
        self.attackDamage = properties.attackDamage
    end
    if type(properties.attackRange) == "number" then
        self.attackRange = properties.attackRange
    end
    if type(properties.attackFrame) == "number" then
        self.attackFrame = properties.attackFrame
    end
    if type(properties.painCooldown) == "number" then
        self.painCooldown = properties.painCooldown
    end
    if type(properties.enabled) == "boolean" then
        self.enabled = properties.enabled
    end
    if type(properties.painCooldown) == "number" then
        self.painCooldown = properties.painCooldown
    end
    if type(properties.decayTime) == "number" then
        self.decayTime = properties.decayTime
    end
    if type(properties.target) == "string" then
        self.targetWeak = scene:GetEntity(properties.target)
    end
    if type(properties.isForcedMovement) == "boolean" then
        self.isForcedMovement = properties.isForcedMovement
    end

    if type(properties.attackName) == "string" then
        self.attackName = properties.attackName
    end
    if type(properties.idleName) == "string" then
        self.idleName = properties.idleName
    end
    if type(properties.deathName) == "string" then
        self.deathName = properties.deathName
    end
    if type(properties.painName) == "string" then
        self.painName = properties.painName
    end
    if type(properties.runName) == "string" then
        self.runName = properties.runName
    end
    return true
end

function Unit:Save(properties, binstream, scene, flags, extra)
    properties.isFullPlayerControl = self.isFullPlayerControl
    properties.isPlayer = self.isPlayer
    properties.isSelected = self.isSelected
    properties.team = self.team
    properties.health = self.health
    if (self.targetWeak ~= nil) then
        properties.target = self.targetWeak:GetUuid()
    end
    properties.health = self.health
    properties.isForcedMovement = self.isForcedMovement
end

function Unit:Damage(amount, attacker)
    if not self:isAlive() then
        return
    end
    self.health = self.health - amount
    local world = self.entity:GetWorld()
    if world == nil then
        return
    end
    local now = world:GetTime()
    if (self.health <= 0) then
        self:Kill(attacker)
    elseif (not self.isInPain and (now - self.painCooldownTime) > self.painCooldown) then
        self.isInPain = true
        self.isAttacking = false
        local model = Model(self.entity)
        if (model ~= nil) then
            model:StopAnimation()
            model:Animate(self.painName, 1.0, 100, ANIMATION_ONCE)
        end
        if (self.agent ~= nil) then
            self.agent:Stop()
        end
    end
    if (self.healthBar) then
        -- reducing health bar tile width
        self.healthBar:SetScale(self.health / self.maxHealth, 1)
    end
    -- attack an atacker
    if (self.isForcedMovement == false and self.isForcedTarget == false) then
        self:attack(attacker)
    end
end

function Unit:Kill(attacker)
    --need to remove pointer to other entity so it could be deleted
    self.targetWeak = nil
    local entity = self.entity
    if (entity == nil) then
        return
    end
    local model = Model(entity)
    if (model) then
        model:StopAnimation()
        model:Animate(self.deathName, 1.0, 250, ANIMATION_ONCE)
    end
    if (self.agent) then
        -- This method will cancel movement to a destination, if it is active, and the agent will smoothly come to a halt.
        self.agent:Stop()
    end
    -- to remove nav agent
    entity:Detach()
    self.agent = nil
    -- to prevent it being obstacle
    entity:SetCollisionType(COLLISION_NONE)
    -- to prevent selection
    entity:SetPickMode(PICK_NONE)
    self.isAttacking = false
    self.healthBar = nil
    self.healthBarBackground = nil
    if (self.decayTime > 0) then
        self.removeEntityTimer = CreateTimer(self.decayTime)
        ListenEvent(EVENT_TIMERTICK, self.removeEntityTimer, Unit.RemoveEntityCallback, self)
        -- not saving if supposed to be deleted anyway
        entity:RemoveTag("Save")
    end
end

function Unit:isAlive()
    return self.health > 0 and self.entity ~= nil
end

function Unit.RemoveEntityCallback(ev, extra)
    local unit = Component(extra)
    unit.removeEntityTimer:Stop()
    unit.removeEntityTimer = nil
    unit.sceneWeak:RemoveEntity(unit.entity)
    unit.sceneWeak = nil
    return false
end

function Unit:scanForTarget()
    local entity = self.entity
    local world = entity:GetWorld()
    if (world ~= nil) then
        -- We only want to perform this few times each second, staggering the operation between different entities.
        -- Pick() operation is kinda CPU heavy. It can be noticeable in Debug mode when too much Picks() happes in same game cycle.
        -- Did not notice it yet in Release mode, but it's better to have it optimized Debug as well anyway.
        local now = world:GetTime()
        if (now < self.nextScanForTargetTime) then
            return
        end
        self.nextScanForTargetTime = now + Random(100, 200)

        local entityPosition = entity:GetPosition(true)
        --simple copy would copy pointer to new var, so this case it's better recreate Vec3 here
        local positionLower = Vec3(entityPosition.x, entityPosition.y, entityPosition.z)
        positionLower.x = positionLower.x - self.perceptionRadius
        positionLower.z = positionLower.z - self.perceptionRadius
        positionLower.y = positionLower.y - self.perceptionRadius

        local positionUpper = Vec3(entityPosition.x, entityPosition.y, entityPosition.z)
        positionUpper.x = positionUpper.x + self.perceptionRadius
        positionUpper.z = positionUpper.z + self.perceptionRadius
        positionUpper.y = positionUpper.y + self.perceptionRadius
        -- will use it to determinate which target is closest
        local currentTargetDistance = -1
        -- GetEntitiesInArea takes positions of an opposite corners of a cube as params
        local entitiesInArea = world:GetEntitiesInArea(positionLower, positionUpper)
        for k, foundEntity in pairs(entitiesInArea) do
            local foundUnit = foundEntity:GetComponent("Unit")
            -- targets are only alive enemy units
            if not (foundUnit == nil or not foundUnit:isAlive() or not foundUnit:isEnemy(self.team) or foundUnit.entity == nil) then
                local dist = foundEntity:GetDistance(entity)
                if not (dist > self.perceptionRadius) then
                    -- check if no obstacles like walls between units
                    local pick = world:Pick(entity:GetBounds(BOUNDS_RECURSIVE).center,
                        foundEntity:GetBounds(BOUNDS_RECURSIVE).center, self.perceptionRadius, true, Unit.RayFilter,
                        self)
                    if (dist < 0 or currentTargetDistance < dist) then
                        self.targetWeak = foundEntity
                        currentTargetDistance = dist
                    end
                end
            end
        end
    end
end

function Unit:Update()
    if self.entity == nil or not self:isAlive() then
        return
    end
    local world = self.entity:GetWorld()
    local model = Model(self.entity)
    if world == nil or model == nil then
        return
    end
    if self.isFullPlayerControl then
        return
    end
    -- making health bar follow the unit
    local window = ActiveWindow()
    if (window ~= nil and self.healthBar ~= nil and self.healthBarBackground ~= nil) then
        local framebuffer = window:GetFramebuffer()
        local position = self.entity:GetBounds().center
        position.y = position.y + self.entity:GetBounds().size.y / 2 -- take top position of unit
        if (self.camera ~= nil) then
            -- ransorming 3D position into 2D
            local unitUiPosition = self.camera:Project(position, framebuffer)
            unitUiPosition.x = unitUiPosition.x - self.healthBarBackground.size.x / 2
            self.healthBar:SetPosition(unitUiPosition.x, unitUiPosition.y, 0.99901)
            self.healthBarBackground:SetPosition(unitUiPosition.x, unitUiPosition.y, 0.99902)
            local doShow = self.isSelected or (self.health ~= self.maxHealth and not self.isPlayer)
            self.healthBar:SetHidden(not doShow)
            self.healthBarBackground:SetHidden(not doShow)
        end
    end
    -- can't attack or move while pain animation
    if (self.isInPain == true) then
        return
    end
    local isMoving = false
    -- ignore enemies and move
    if (self.isForcedMovement == true and self:goTo()) then
        return
    end
    -- atacking part
    if (not isMoving) then
        local target = self.targetWeak
        -- Stop attacking if target is dead
        if (target ~= nil) then
            local distanceToTarget = self.entity:GetDistance(target)
            local doResetTarget = false
            if (distanceToTarget > self.chaseMaxDistance and ~self.isForcedTarget) then
                doResetTarget = true
            else
                for k, targetComponent in pairs(target.components) do
                    local targetUnit = Component(targetComponent)
                    if (targetUnit and not targetUnit:isAlive()) then
                        doResetTarget = true
                        self.isForcedTarget = false
                    end
                    break
                end
            end
            if (doResetTarget) then
                target = nil
                self.targetWeak = nil
                if (self.agent ~= nil) then
                    self.agent:Stop()
                end
            end

        end
        if (self.isAttacking and target ~= nil) then
            -- rotating unit to target
            local a = ATan(self.entity.matrix.t.x - target.matrix.t.x, self.entity.matrix.t.z - target.matrix.t.z)
            if (self.agent) then
                self.agent:SetRotation(a + 180)
            end
        end
        if (target == nil) then
            self:scanForTarget()
        end
        if (target ~= nil) then
            local distanceToTarget = self.entity:GetDistance(target)
            -- run to target if out of range
            if (distanceToTarget > self.attackRange) then
                if (self.agent ~= nil) then
                    self.agent:Navigate(target:GetPosition(true))
                end
                self.isAttacking = false
                model:Animate(self.runName, 1.0, 250, ANIMATION_LOOP)
            else
                if (self.agent) then
                    self.agent:Stop()
                end
                -- start attack if did not yet
                if (self.isAttacking == false) then
                    self.meleeAttackTime = world:GetTime()
                    model:Animate(self.attackName, 1.0, 100, ANIMATION_ONCE)
                    self.isAttacking = true
                end
            end
            return
        end
    end
    if (self.targetPoint ~= nil and self:goTo()) then
        return
    end
    if (self.isAttacking == false) then
        model:Animate(self.idleName, 1.0, 250, ANIMATION_LOOP)
        if (self.agent ~= nil) then
            self.agent:Stop()
        end
    end
end

function Unit.RayFilter(entity, extra)
    local thisUnit = Component(extra)
    local pickedUnit = entity:GetComponent("Unit")
    --skip if it's same team
    return pickedUnit == nil or pickedUnit ~= nil and pickedUnit.team ~= thisUnit.team
end


function Unit.AttackHook(skeleton, extra)
	local unit = Component(extra)
	if (unit == nil) then
		return
    end
	local entity = unit.entity
	local target = unit.targetWeak
	if (target ~= nil) then
		local pos = entity:GetPosition(true)
		local dest = target:GetPosition(true) + target:GetVelocity(true)
		--attack in target in range
		if (pos:DistanceToPoint(dest) < unit.attackRange) then
			for k, targetComponent in pairs(target.components) do
                if targetComponent.Damage and type(targetComponent.Damage) == "function" then
                    targetComponent:Damage(unit.attackDamage, entity)
				end
			end
		end
	end	
end

function Unit.EndAttackHook(skeleton, extra)
    local unit = Component(extra)
    unit.attacking = false
end

function Unit.EndPainHook(skeleton, extra)
    local unit = Component(extra)
    if (unit ~= nil) then
        unit.isInPain = false
        if (unit:isAlive() and unit.entity:GetWorld()) then
            unit.painCooldownTime = unit.entity:GetWorld():GetTime()
        end
    end
end

function Unit:isEnemy(otherUnitTeam) 
	return self.team == 1 and otherUnitTeam == 2 or self.team == 2 and otherUnitTeam == 1
end

function Unit:goToEntity(targetPointEntity, isForced) 
	if (targetPointEntity ~= nil) then
		self.isForcedMovement = isForced
		self.targetPoint = targetPointEntity
		self:goTo()
    end
end

function Unit:goToPosition(positionToGo, isForced) 
	if (self.entity ~= nil) then
		self.isForcedMovement = isForced
		self.targetPoint = CreatePivot(self.entity:GetWorld())
		self.targetPoint:SetPosition(positionToGo)
		self:goTo()
    end
end

function Unit:goTo() 
	local doMove = false
	local model = Model(self.entity)
	if (self.targetPoint ~= nil and self.agent ~= nil) then
		doMove = self.agent:Navigate(self.targetPoint:GetPosition(true), 100, 2.0)
        --doMove is false if unit can't reach target point
		if (doMove) then
			--checking distance to target point on nav mesh
			local distanceToTarget = self.entity:GetDistance(self.agent:GetDestination(true))
            local resultMaxDistance = self.targetPointDistance
            if (self.isForcedMovement) then
                --so that the player's units don't push each other trying to reach the point
                resultMaxDistance = resultMaxDistance * 2
            end
            --stop moving to this point if close enough
			if (distanceToTarget < resultMaxDistance) then
				local wayPoint = self.targetPoint:GetComponent("WayPoint")
				if (wayPoint ~= nil and wayPoint.nextPoint ~= nil) then
                    --move to next one if exist
					self.targetPoint = wayPoint.nextPoint
					doMove = true
				else 
					self.targetPoint = nil
					doMove = false
                end
			else
				doMove = true
            end
		end	
		if (doMove and model) then
			model:Animate(self.runName, 1.0, 250, ANIMATION_LOOP)
        end
	end
	return doMove
end

function Unit:attack(entityToAttack, isForced)
	self.targetWeak = nil
	if (entityToAttack == nil or entityToAttack:GetComponent("Unit") == nil or entityToAttack:GetComponent("Unit").team == self.team) then
		return
    end
	self.targetPoint = nil
	self.isForcedMovement = false
	self.isForcedTarget = isForced
	self.targetWeak = entityToAttack
end

function Unit:select(doSelect) 
	self.isSelected = doSelect
end

RegisterComponent("Unit", Unit)
return Unit
