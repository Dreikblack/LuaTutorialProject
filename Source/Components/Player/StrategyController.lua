StrategyController = {}
StrategyController.name = "StrategyController"
StrategyController.selectedUnits = {}
-- Control key state
StrategyController.isControlDown = false
StrategyController.playerTeam = 1
StrategyController.camera = nil
StrategyController.unitSelectionBox = nil
-- first mouse position when Mouse Left was pressed
StrategyController.unitSelectionBoxPoint1 = iVec2(0, 0)
-- height of selection box
StrategyController.selectHeight = 4
-- mouse left button state
StrategyController.isMouseLeftDown = false

function StrategyController:Start()
    self.entity:AddTag("StrategyController")
    self.entity:AddTag("Save") -- For custom save/load system

    -- Listen() needed for calling ProcessEvent() in component when event happen
    self:Listen(EVENT_MOUSEDOWN, nil)
    self:Listen(EVENT_MOUSEUP, nil)
    self:Listen(EVENT_MOUSEMOVE, nil)
    self:Listen(EVENT_KEYUP, nil)
    self:Listen(EVENT_KEYDOWN, nil)

    -- optimal would be setting component to a camera
    if Camera(self.entity) ~= nil then
        self.camera = Camera(self.entity)
    else
        -- Otherwise, find the camera by tag
        for _, cameraEntity in ipairs(self.entity:GetWorld():GetTaggedEntities("Camera")) do
            self.camera = Camera(cameraEntity)
            break
        end
    end

    -- Create a 1x1 sprite for pixel-accurate scaling
    self.unitSelectionBox = CreateTile(self.camera, 1, 1)

    -- Set the sprite's color to transparent green
    self.unitSelectionBox:SetColor(0, 0.4, 0.2, 0.5)
    self.unitSelectionBox:SetPosition(0, 0, 0.00001)
    self.unitSelectionBox:SetHidden(true)

    -- Create a material for transparency
    local material = CreateMaterial()
    material:SetShadow(false)
    material:SetTransparent(true)
    -- material:SetPickMode(false)

    -- Use an unlit shader family
    material:SetShaderFamily(LoadShaderFamily("Shaders/Unlit.fam"))

    -- Assign the material to the sprite
    self.unitSelectionBox:SetMaterial(material)
end

function StrategyController.RayFilter(entity, extra)
    local pickedUnit = nil
    if (entity ~= nil) then
        pickedUnit = entity:GetComponent("Unit")
    end
	--skip if it's unit
	return pickedUnit == nil
end

function StrategyController:Load(properties, binstream, scene, flags, extra)
    if type(properties.playerTeam) == "number" then
        self.playerTeam = properties.playerTeam
    end
    for k in pairs (self.selectedUnits) do
        self.selectedUnits[k] = nil
    end
    if type(properties.selectedUnits) == "array" then
		for i = 1, #properties.selectedUnits do
			local unit = scene:GetEntity(properties.selectedUnits[i]);
			if (unit ~= nil) then
				self.selectedUnits[#self.selectedUnits+1] = unit;
            end
		end
    end
    return true
end

function StrategyController:Save(properties, binstream, scene, flags, extra)
    properties.playerTeam = self.playerTeam
    properties.selectedUnits = {};
	for i=1, #self.selectedUnits do
        properties.selectedUnits[i] = self.selectedUnits[i]:GetUuid()
    end
    return true
end

function StrategyController:ProcessEvent(e)
    local window = ActiveWindow()
    if not window then
        return true
    end

    local mousePosition = window:GetMousePosition()

    if e.id == EVENT_MOUSEDOWN then
        if not self.camera then
            return
        end
        if e.data == MOUSE_LEFT then
            self.unitSelectionBoxPoint1 = iVec2(mousePosition.x, mousePosition.y)
            self.isMouseLeftDown = true
            -- Move or attack on Right Click
        elseif e.data == MOUSE_RIGHT then
            -- Get entity under cursor
            local pick = self.camera:Pick(window:GetFramebuffer(), mousePosition.x, mousePosition.y, 0, true)
            if pick.success and pick.entity then
                local unit = pick.entity:GetComponent("Unit")
                if unit and unit:isAlive() and unit.team ~= self.playerTeam then
                    -- Attack the selected entity
                    for _, entityWeak in ipairs(self.selectedUnits) do
                        local entityUnit = entityWeak
                        if entityUnit and entityUnit:GetComponent("Unit") then
                            entityUnit:GetComponent("Unit"):attack(pick.entity, true)
                        end
                    end
                --checking if we have selected units
                elseif (#self.selectedUnits ~= 0) then
                    local flag = LoadPrefab(self.camera:GetWorld(), "Prefabs/FlagWayPoint.pfb")
                    if (flag ~= nil) then
						flag:SetPosition(pick.position)
					end
                    -- Move to the selected position
                    for _, entityWeak in ipairs(self.selectedUnits) do
                        local entityUnit = entityWeak
                        if entityUnit and entityUnit:GetComponent("Unit") then
                            if (flag ~= nil) then
                                entityUnit:GetComponent("Unit"):goToEntity(flag, true)
                            else
                                entityUnit:GetComponent("Unit"):goToPosition(pick.position, true)

                            end
                        end
                    end
                end
            end
        end
    elseif e.id == EVENT_MOUSEUP then
        if not self.camera then
            return
        end
        -- Unit selection on Left Click
        if e.data == MOUSE_LEFT then
            if not self:selectUnitsByBox(self.camera, window:GetFramebuffer(), iVec2(mousePosition.x, mousePosition.y)) then
                local pick = self.camera:Pick(window:GetFramebuffer(), mousePosition.x, mousePosition.y, 0, true)
                if pick.success and pick.entity then
                    local unit = pick.entity:GetComponent("Unit")
                    if unit and unit.isPlayer and unit:isAlive() then
                        if not self.isControlDown then
                            self:deselectAllUnits()
                        end
                        table.insert(self.selectedUnits, pick.entity)
                        unit:select(true)
                    else
                        self:deselectAllUnits()
                    end
                else
                    self:deselectAllUnits()
                end
            end
            self.isMouseLeftDown = false
        end
    elseif e.id == EVENT_KEYUP then
        if e.data == KEY_CONTROL then
            self.isControlDown = false
        end

    elseif e.id == EVENT_KEYDOWN then
        if e.data == KEY_CONTROL then
            self.isControlDown = true
        end
    end

    return true
end

function StrategyController:deselectAllUnits()
    for _, entityWeak in ipairs(self.selectedUnits) do
        local entityUnit = entityWeak
        if entityUnit and entityUnit:GetComponent("Unit") then
            entityUnit:GetComponent("Unit"):select(false)
        end
    end
    self.selectedUnits = {}
end

function StrategyController:Update()
    if not self.isMouseLeftDown then
        self.unitSelectionBox:SetHidden(true)
    else
        local window = ActiveWindow()
        if window then
            local mousePosition = window:GetMousePosition()
            local unitSelectionBoxPoint2 = iVec2(mousePosition.x, mousePosition.y)
            local upLeft = iVec2(math.min(self.unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), math.min(self.unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y))
            local downRight = iVec2(math.max(self.unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), math.max(self.unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y))
            -- Don't show the selection box if it's too small (could be a single click)
            if (downRight.x - upLeft.x < 4) or (downRight.y - upLeft.y < 4) then
                self.unitSelectionBox:SetHidden(true)
                return
            end
            -- Set the position of the selection box
            self.unitSelectionBox:SetPosition(upLeft.x, upLeft.y)
            -- Calculate the width and height of the selection box
            local width = downRight.x - upLeft.x
            local height = downRight.y - upLeft.y
            -- Change the sprite size via scale (size is read-only)
            self.unitSelectionBox:SetScale(width, height)
            -- Make the selection box visible
            self.unitSelectionBox:SetHidden(false)
        end
    end
end

function StrategyController:selectUnitsByBox(camera, framebuffer, unitSelectionBoxPoint2)
    if not self.unitSelectionBox or self.unitSelectionBox:GetHidden() or not camera or not framebuffer then
        return false
    end

    -- Calculate the top-left and bottom-right corners of the selection box
    local upLeft = iVec2(Min(self.unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Min(self.unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y))
    local downRight = iVec2(Max(self.unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x),  Max(self.unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y))

    -- Perform raycasting at the corners of the selection box
    local pick1 = camera:Pick(framebuffer, upLeft.x, upLeft.y, 0, true, StrategyController.RayFilter, nil)
    local pick2 = camera:Pick(framebuffer, downRight.x, downRight.y, 0, true, StrategyController.RayFilter, nil)

    if not pick1.success or not pick2.success then
        return false
    end

    -- Deselect all currently selected units
    self:deselectAllUnits()

    -- Calculate the lower and upper bounds of the selection area
    local positionLower = Vec3(
        math.min(pick1.position.x, pick2.position.x),
        math.min(pick1.position.y, pick2.position.y),
        math.min(pick1.position.z, pick2.position.z)
    )
    local positionUpper = Vec3(
        math.max(pick1.position.x, pick2.position.x),
        math.max(pick1.position.y, pick2.position.y) + self.selectHeight,
        math.max(pick1.position.z, pick2.position.z)
    )

    -- Find entities within the selection area
    for _, foundEntity in ipairs(camera:GetWorld():GetEntitiesInArea(positionLower, positionUpper)) do
        local foundUnit = foundEntity:GetComponent("Unit")
        -- Only select alive, player-controlled, and enemy units
        if foundUnit and foundUnit:isAlive() and foundUnit.isPlayer and foundUnit.team == self.playerTeam then
            table.insert(self.selectedUnits, foundUnit.entity)
            foundUnit:select(true)
        end
    end

    return true
end

RegisterComponent("StrategyController", StrategyController)

return StrategyController
