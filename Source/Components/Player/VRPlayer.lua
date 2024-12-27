-- Define the VRPlayer table
VRPlayer = {}
VRPlayer.name = "VRPlayer"

--Component start function
function VRPlayer:Start()

    self.entity:SetHidden(true)

    --Initialize VR mode
    self.hmd = GetHmd(self.world)

    --Set the starting offset
    self.hmd:SetOffset(self.entity.position, self.entity.rotation)

end

--Register the component
RegisterComponent("VRPlayer", VRPlayer)

-- Return the VRPlayer table
return VRPlayer