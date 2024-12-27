AmbientNoise = {}
AmbientNoise.name = "AmbientNoise"
AmbientNoise.volume = 1
AmbientNoise.targetvolume = 1
AmbientNoise.modulatedvolume = 1
AmbientNoise.play = true
AmbientNoise.range = 10
AmbientNoise.pitch = 1
AmbientNoise.loop = true

function AmbientNoise:Start()
    if self.sound and self:GetEnabled() and self.play then
        -- This will give us a small delay so the listener will be positioned before sounds start playing
        self.timer = CreateTimer(1000)
        self:Listen(EVENT_TIMERTICK, self.timer)
    else
        a=3
    end
    if not self:GetEnabled() then
        b=3
    end
end

function AmbientNoise:ProcessEvent(e)
    if e.id == EVENT_TIMERTICK then
        self.timer:Stop()
        self.timer = nil
        self:Play()
    end
    return false;
end

function AmbientNoise:Update()    
    self.modulatedvolume = MoveTowards(self.modulatedvolume, self.targetvolume, 0.01)
    if self.speaker then
        if self.modulatedvolume == 0.0 then
            self.speaker = nil
        else
            self.speaker:SetVolume(self.volume * self.modulatedvolume);
        end
    end
end

function AmbientNoise:FadeIn()
    self.targetvolume = 1
end

function AmbientNoise:FadeOut()
    self.targetvolume = 0
end

function AmbientNoise:EndLoop()
    if self.speaker then self.speaker:SetLooping(false) end
    self.speaker = nil
end

function AmbientNoise:Load(properties, binstream, scene, flags, extra)
    if type(properties.range) == "number" then
        self.range = properties.range / 100
    end
    if type(properties.volume) == "number" then
        self.volume = properties.volume / 100
    end
    if type(properties.pitch) == "number" then
        self.pitch = properties.pitch / 100
    end
    if type(properties.sound) == "string" then
        self.sound = LoadSound(properties.sound)
    else
        self.sound = nil
    end
    return true
end

function AmbientNoise:Stop()
    self:FadeOut()
end

function AmbientNoise:Play()
    if not self.sound then return end
    if not self:GetEnabled() then return end

    self.targetvolume = 1.0
    if not self.speaker then self.modulatedvolume = 1.0 end

    -- If a looping sound is already being played, don't play it again
    if self.loop and self.speaker and self.speaker:GetState() == SPEAKER_PLAYING then
        self.speaker:SetVolume(self.volume * self.modulatedvolume)
        self.speaker:SetPitch(self.pitch)
        self.speaker:SetRange(self.range)
        return
    end

    self.speaker = self.entity:EmitSound(self.sound, self.range, self.volume, self.pitch, self.loop)
    if not self.loop then self.speaker = nil end
end

function AmbientNoise:Save(properties, binstream, scene, flags, extra)
    if self.sound then properties.sound = self.sound.path end
    return true
end

RegisterComponent("AmbientNoise", AmbientNoise)