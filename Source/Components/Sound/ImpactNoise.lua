ImpactNoise = {}
ImpactNoise.name = "ImpactNoise"
ImpactNoise.sounds = {}
ImpactNoise.lastplaytime = 0
ImpactNoise.MaxSounds = 3
ImpactNoise.minspeed = 2
ImpactNoise.range = 10

function ImpactNoise:Collide(collidedentity, position, normal, speed)
    if speed < self.minspeed then return end
    if #self.sounds == 0 then return end
    local world = self.entity:GetWorld()
    local now = world:GetTime()
    if now - self.lastplaytime < 200 then return end
    self.lastplaytime = now
    local index = Round(Random(1, #self.sounds))
    if self.sounds[index] then self.entity:EmitSound(self.sounds[index]) end
end

function ImpactNoise:Load(properties, binstream, scene, flags, extra)
    if type(properties.range) == "number" then
        self.range = properties.range / 100
    end

    local n
    for n = 1, self.MaxSounds do
        local key = "sound" .. tostring(n)
        if type(properties[key]) == "string" then
            local sound = LoadSound(properties[key])
            if sound then table.insert(self.sounds, sound) end
        end
    end

    return true
end

function ImpactNoise:Save(properties, binstream, scene, flags, extra)
    properties.range = self.range * 100

    local n
    for n = 1, #self.sounds do
        if self.sounds[n] then
            local key = "sound" .. tostring(n);
            properties[key] = RelativePath(self.sounds[n].path)
        end
    end

    return true
end

RegisterComponent("ImpactNoise", ImpactNoise)
return ImpactNoise