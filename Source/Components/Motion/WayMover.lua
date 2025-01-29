WayMover = {}
-- name should always match class name for correct component work
WayMover.name = "WayMover"
WayMover.moveSpeed = 4.0
WayMover.isMoving = false
WayMover.nextPoint = nil
WayMover.scene = nil

function WayMover:Copy()
    local t = {}
    local k
    local v
    for k, v in pairs(self) do
        t[k] = v
    end
    return t
end

-- will be called on map load
function WayMover:Load(properties, binstream, scene, flags, extra)
    if type(properties.moveSpeed) == "number" then
        self.moveSpeed = properties.moveSpeed
    end
    if type(properties.isMoving) == "boolean" then
        self.isMoving = properties.isMoving
    end
    if type(properties.doDeleteAfterMovement) == "boolean" then
        self.doDeleteAfterMovement = properties.doDeleteAfterMovement
    end
    if type(properties.nextPoint) == "string" then
        for _, entity in ipairs(scene.entities) do
            if properties.nextPoint == entity:GetUuid() then
                self.nextPoint = entity
                break
            end
        end   
        -- self.nextPoint = scene:GetEntity(properties.nextPoint)
        -- need scene for removing entity on doDeleteAfterMovement condition
        self.scene = scene
        return true
    end
end

-- Can be used to save current component state on map save
function WayMover:Save(properties, binstream, scene, flags, extra)
    if self.nextPoint ~= nil then
        properties.nextPoint = self.nextPoint:GetUuid()
        properties.doStayOnPoint = self.doStayOnPoint;
    end
    properties.moveSpeed = self.moveSpeed;
    properties.isMoving = self.isMoving;
    properties.doDeleteAfterMovement = self.doDeleteAfterMovement;
    return true
end

function WayMover:DoMove()
    self.isMoving = true
end

function WayMover:MoveEnd()
    local doStay = false
    if (self.nextPoint ~= nil) then
        doStay = self.nextPoint:GetComponent("WayPoint").doStayOnPoint
        self.nextPoint = self.nextPoint:GetComponent("WayPoint").nextPoint
    end
    if (doStay or self.nextPoint == nil) then
        self.isMoving = false;
        self:FireOutputs("EndMove")
        -- deleting entity if need to, after reaching final way point
        if (not doStay and self.nextPoint == nil and self.doDeleteAfterMovement and self.scene ~= nil) then
            self.scene:RemoveEntity(self.entity)
        end
    end
end

function WayMover:Update() 
	if (not self.isMoving) then
		return;
    end
	local wayPoint = self.nextPoint
	if (self.entity == nil or wayPoint == nil) then
		return
    end
	--60 HZ game loop, change to own value if different to keep same final speed
	local speed = self.moveSpeed / 60.0
	local targetPosition = wayPoint:GetPosition(true)

	--moving to point with same speed directly to point no matter which axis
	local pos = self.entity:GetPosition(true);
	local distanceX = Abs(targetPosition.x - pos.x);
	local distanceY = Abs(targetPosition.y - pos.y);
	local distanceZ = Abs(targetPosition.z - pos.z);
	local biggestDelta = distanceZ;
	if (distanceX > distanceY and distanceX > distanceZ) then
		biggestDelta = distanceX;
	elseif (distanceY > distanceX and distanceY > distanceZ) then
		biggestDelta = distanceY;
    end

	local moveX = MoveTowards(pos.x, targetPosition.x, speed * (distanceX / biggestDelta));
	local moveY = MoveTowards(pos.y, targetPosition.y, speed * (distanceY / biggestDelta));
	local moveZ = MoveTowards(pos.z, targetPosition.z, speed * (distanceZ / biggestDelta));

	self.entity:SetPosition(moveX, moveY, moveZ)
	if (self.entity:GetPosition(true) == targetPosition) then
		self:MoveEnd()
    end

end

-- needed for correct work, when loaded from a map
RegisterComponent("WayMover", WayMover)

return WayMover
