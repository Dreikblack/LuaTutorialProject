TopDownCamera = {}
TopDownCamera.name = "TopDownCamera"
TopDownCamera.targetPivot = nil
TopDownCamera.scene = nil
TopDownCamera.borderMoveThickness = 5
TopDownCamera.borderMove = 0.01
TopDownCamera.oldScrollPos = 0
TopDownCamera.moveSpeed = 8.0
TopDownCamera.scrollSpeed = 0.2
TopDownCamera.minHeight = 4.0
TopDownCamera.maxHeight = 10.0

local CAMERA_PITCH = 54.736

function TopDownCamera:getCirleCenter(cameraPosition, cameraRotaion) 
	local distance = cameraPosition.y * Tan(CAMERA_PITCH)
	distance = math.sqrt(distance * distance / 2.0)
	local center = cameraPosition
	center.x = cameraPosition.x + distance * Cos(cameraRotaion.y)
	center.z = cameraPosition.z + distance * Sin(cameraRotaion.y)
	return center
end

function TopDownCamera:Start() 
	self.entity:AddTag("Camera")
	self:init()
end

function TopDownCamera:Load(properties, binstream, scene, flags, extra)
    self.scene = scene
    if type(properties.minHeight) == "number" then
        self.minHeight = properties.minHeight
    end
    if type(properties.maxHeight) == "number" then
        self.maxHeight = properties.maxHeight
    end
    return true
end

function TopDownCamera:Save(properties, binstream, scene, flags, extra)
    properties.minHeight = self.minHeight
    properties.maxHeight = self.maxHeight
    return true
end


function TopDownCamera:init() 
	local gameCamera = Camera(self.entity)
	if (gameCamera == nil) then
		return false
    end
	local window = ActiveWindow()
	if (window) then
		local framebuffer = window:GetFramebuffer()
		local sz = framebuffer:GetSize()
		self.borderMoveThickness = sz.x * self.borderMove
    end
	
	if (gameCamera ~= nil and self.targetPivot == nil) then
		gameCamera:Listen()--for positional sound 
		gameCamera:SetSweptCollision(true)--for removing pop up effect after quick move/turn
		gameCamera:SetRotation(CAMERA_PITCH, gameCamera:GetRotation(true).y, gameCamera:GetRotation(true).z)
		local targetPivotShared = CreatePivot(gameCamera:GetWorld())
		targetPivotShared:SetPickMode(PICK_NONE)	
		self.scene:AddEntity(targetPivotShared)
		self.targetPivot = targetPivotShared
    end
	--setting position and rotation here in case of game load
	gameCamera:SetParent(nil)
	local targetPivotShared = self.targetPivot
	local targetPosition = self:getCirleCenter(gameCamera:GetPosition(true), gameCamera:GetRotation(true))
	targetPosition.y = 0
	targetPivotShared:SetPosition(targetPosition)
	targetPivotShared:SetRotation(0, gameCamera:GetRotation(true).y, gameCamera:GetRotation(true).z)
	gameCamera:SetParent(targetPivotShared)
	return true
end


function TopDownCamera:Update() 
	local window = ActiveWindow()
	if (window == nil or self.entity == nil or self.entity:GetWorld() == nil) then
		return
    end
	local speed = self.moveSpeed / 60.0
	local mousePosition = window:GetMousePosition()
	local pivot = self.targetPivot

	local moveLeft = window:KeyDown(KEY_A)
	local moveRight = window:KeyDown(KEY_D)
	local moveUpward = window:KeyDown(KEY_W)
	local moveDown = window:KeyDown(KEY_S)

	local clientSize = window:ClientSize()

	if (mousePosition.y > 0 and mousePosition.y < self.borderMoveThickness) then
        moveUpward = true
    end
	if (mousePosition.y < clientSize.y and mousePosition.y >(clientSize.y - self.borderMoveThickness)) then
        moveDown = true
    end 
	if (mousePosition.x > 0 and mousePosition.x < self.borderMoveThickness) then
        moveLeft = true
    end
	if (mousePosition.x < clientSize.x and mousePosition.x >(clientSize.x - self.borderMoveThickness)) then
         moveRight = true
    end
	if (moveLeft) then
        pivot:Move(-speed * 2, 0, 0)
    end
	if (moveRight) then
        pivot:Move(speed * 2, 0, 0)
    end
	if (moveUpward) then 
        pivot:Move(0, 0, speed * 2)
    end
	if (moveDown) then
        pivot:Move(0, 0, -speed * 2)
    end
	if (window:KeyDown(KEY_Q)) then
        self:rotate(true, 1)
    end
	if (window:KeyDown(KEY_E)) then
        self:rotate(false, 1)
    end

	local zoomDelta = self.oldScrollPos - mousePosition.z
	self:zoom(-zoomDelta)
	self.oldScrollPos = mousePosition.z
end

function TopDownCamera:rotateByAngle(angle) 
	local rotation = self.targetPivot:GetRotation(true)
	rotation.y = self:normalizeAngle(rotation.y + angle)
	self.targetPivot:SetRotation(rotation)
end

function TopDownCamera:rotate(isLeft, coeff) 
	local heightCoeff = self.entity:GetPosition(true).y / self.minHeight
	local angleStep = coeff * 360.0 / (60.0 * heightCoeff * 2.0)--40 per 1 sec
    if (isLeft) then
        self:rotateByAngle(angleStep)
    else
        self:rotateByAngle(-angleStep)
    end
end

function TopDownCamera:normalizeAngle(angle) 
	local twoPi = 360.0
	while (angle > twoPi) do
		angle = angle - twoPi
    end

	while (angle < 0.0) do
		angle = angle + twoPi
    end
	return angle
end

function TopDownCamera:zoom(scrollData)
    local zoomDelta = scrollData * self.scrollSpeed
    local window = ActiveWindow()
    local world = self.entity:GetWorld()

    if not window or not self.entity or not world then
        return
    end

    local cameraPosition = self.entity:GetPosition(true)
    local newCameraHeight = cameraPosition.y + zoomDelta

    if cameraPosition.y > self.maxHeight then
        newCameraHeight = self.maxHeight
    elseif cameraPosition.y < self.minHeight then
        newCameraHeight = self.minHeight
    end

    local cameraTargetBottomPick = cameraPosition
    cameraTargetBottomPick.y = self.minHeight
    cameraPosition.y = self.maxHeight

    local cameraPick = world:Pick(cameraPosition, cameraTargetBottomPick, 0, true)
    if cameraPick.success and newCameraHeight < cameraPick.position.y + 2 then
        newCameraHeight = cameraPick.position.y + 2
    end

    if newCameraHeight <= self.maxHeight and newCameraHeight >= self.minHeight then
        cameraPosition.y = newCameraHeight
        local camera = Camera(self.entity)
        local pick = camera:Pick(window:GetFramebuffer(), Round(window:ClientSize().x / 2), Round(window:ClientSize().y / 2), 0, true)

        local targetPosition
        if pick.success then
            targetPosition = pick.position
            if targetPosition.y < 0 and self.minHeight > 0 then
                targetPosition.y = 0
            end
        else
            targetPosition = TopDownCamera:getCirleCenter(cameraPosition, self.entity:GetRotation(true))
        end

        self.targetPivot:SetPosition(targetPosition, true)
        self.entity:SetPosition(cameraPosition, true)
    end
end

RegisterComponent("TopDownCamera", TopDownCamera)

return TopDownCamera