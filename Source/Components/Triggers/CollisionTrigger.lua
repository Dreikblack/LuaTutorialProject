-- CollisionTrigger.lua
CollisionTrigger = {
    once = false,
    enabled = true,
    name = "CollisionTrigger"
}

function CollisionTrigger:Start()
    if self.entity:GetCollisionType() == COLLISION_TRIGGER then
        self.entity:SetRenderLayers(0)
        self.entity:SetShadows(false)
        self.entity:SetPickMode(PICK_NONE)
    end
end

function CollisionTrigger:Collide(collidedEntity, position, normal, speed)
    if not self.enabled then
        return
    end
    if self.once then
        self:Disable()
    end
end

function CollisionTrigger:Disable()
    self.enabled = false
end

function CollisionTrigger:Enable()
    self.enabled = true
end

RegisterComponent("CollisionTrigger", CollisionTrigger)

return CollisionTrigger