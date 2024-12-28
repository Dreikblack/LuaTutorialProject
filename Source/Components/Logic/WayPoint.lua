WayPoint = {}
-- name should always match class name for correct component work
WayPoint.name = "WayPoint"
WayPoint.nextPoint = nil
--  wait for command before moving to next WayPoint
WayPoint.doStayOnPoint = false

-- Start is called when Load() of all components was called already
function WayPoint:Start()

end

-- will be called on map load
function WayPoint:Load(properties, binstream, scene, flags, extra)
    -- internally entity saves in the Editor as String unique id
    -- can be empty if this way point is final
    if type(properties.nextPoint) == "string" then
        for _, entity in ipairs(scene.entities) do
            if properties.nextPoint == entity:GetUuid() then
                self.nextPoint = entity
                break
            end
        end
        -- self.nextPoint = scene:GetEntity(properties.nextPoint)
        if type(properties.doStayOnPoint) == "boolean" then
            self.doStayOnPoint = properties.doStayOnPoint
        end
    end
    return true
end

-- Can be used to save current component state on map save
function WayPoint:Save(properties, binstream, scene, flags, extra)
    if self.nextPoint ~= nil then
        properties.nextPoint = self.nextPoint:GetUuid()
        properties.doStayOnPoint = self.doStayOnPoint;
    end
    return true
end

-- Can be used to get copy of this component
function WayPoint:Copy()
    local t = {}
    local k
    local v
    for k, v in pairs(self) do
        t[k] = v
    end
    return t
end

-- needed for correct work, when loaded from a map
RegisterComponent("WayPoint", WayPoint)

return WayPoint
