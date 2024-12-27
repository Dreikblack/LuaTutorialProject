Relay = {}
Relay.name = "Relay"
Relay.signaltime = 0
Relay.delay = 0
Relay.once = false
Relay.fastrefiring = true

function Relay:Start()
    self.Signal = Relay.Signal-- This is a bit of a hack to prevent the Signal outputs from automatically being fired immediately
end

function Relay:Update()
    if self.signaltime > 0 then
        local now = self.entity.world:GetTime() 
        if now > self.signaltime then
            self:FireOutputs("Signal")
            self.signaltime = 0
        end
    end
end

function Relay:Signal()
    if not self:GetEnabled() then return end    
    if self.delay > 0 then
        local now = self.entity.world:GetTime() 
        self.signaltime = now + self.delay * 1000
        if self.once then
            self:Disable()
        end
    else
        self:FireOutputs("Signal")
        self.signaltime = 0
    end
end

RegisterComponent("Relay", Relay)
return Relay