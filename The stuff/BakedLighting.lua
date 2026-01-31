--==================================================
-- Axl Engine Baked Lighting System
--==================================================

-- Services
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--==================================================
-- CONFIG
--==================================================
local renderScale = 2
local halfRenderScale = renderScale * 0.5
local extendedRenderScale = (renderScale * 2) + (renderScale * 0.6)
local surfaceScale = 0.01
local textureId = "rbxassetid://9300220537"
local shadowDarkness = 0.5
local shadowColor = Color3.fromRGB(10, 10, 10)
local ambientColor = Color3.fromRGB(140, 140, 140)
local ambientMultiplier = 0.3
local rayDistance = 200
local epsilon = 0.001
local renderType = "Shadows+AllLights" -- Options: OnlyShadow, FullLightMap, Shadows+AllLights

-- Soft shadow settings
local sunSamples = 16       -- Sun soft shadow rays
local jitterAmount = 0.25   -- Sun ray jitter for penumbra

local pointLightSamples = 12  -- Point light soft shadow rays
local pointLightJitter = 0.15 -- Point light ray jitter

--==================================================
-- STORAGE
--==================================================
local lightmapStorage = Workspace:FindFirstChild("LightMapStorage")
if not lightmapStorage then
    lightmapStorage = Instance.new("Folder", Workspace)
    lightmapStorage.Name = "LightMapStorage"
end

--==================================================
-- GLOBALS
--==================================================
local SunDirection = Lighting:GetSunDirection().Unit

--==================================================
-- UTILITIES
--==================================================
local function rayCast(origin, direction, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList or {}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    return Workspace:Raycast(origin, direction, rayParams)
end

local function jitterDirection(baseDir, amount)
    local rnd = Vector3.new(math.random(), math.random(), math.random()) * 2 - Vector3.new(1, 1, 1)
    local orthogonal = rnd - baseDir * baseDir:Dot(rnd)
    if orthogonal.Magnitude == 0 then orthogonal = Vector3.new(1, 0, 0) end
    return (baseDir + orthogonal.Unit * amount).Unit
end

-- Soft sunlight with gradual penumbra
local function calculateSunDiffuseSoft(normal, worldPos)
    local hitCount = 0
    for i = 1, sunSamples do
        local jitteredDir = jitterDirection(SunDirection, jitterAmount)
        local result = rayCast(worldPos + normal * epsilon, jitteredDir * rayDistance, {lightmapStorage})
        if result then
            hitCount += 1 
        end
    end
    local shadowFactor = hitCount / sunSamples
    local diffuse = ambientMultiplier * math.max(normal:Dot(SunDirection), 0)
    local penumbraBlend = 1 - shadowFactor
    return diffuse * penumbraBlend, shadowFactor
end

-- Soft point light shadows with quadratic falloff
local function calculatePointLightSoft(origin, normal, light)
    if not light.Parent then return nil end
    local dirToLight = (light.Parent.Position - origin)
    local distance = dirToLight.Magnitude
    if distance > light.Range then return nil end
    
    local hitCount = 0
    for i = 1, pointLightSamples do
        local jitteredDir = jitterDirection(dirToLight.Unit, pointLightJitter)
        local result = rayCast(origin + normal * epsilon, jitteredDir * distance, {light.Parent, lightmapStorage})
        if result then
            hitCount += 1
        end
    end
    local shadowFactor = hitCount / pointLightSamples
    
    local attenuation = 1 - (distance / light.Range)^2
    return math.clamp(attenuation * (1 - shadowFactor), 0, 1)
end

--==================================================
-- LIGHTMAP POINT CREATION
--==================================================
local function createLightPoint(position, normal)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Transparency = 1
    p.Size = Vector3.new(renderScale + extendedRenderScale, surfaceScale, renderScale + extendedRenderScale)
    p.CFrame = CFrame.new(position, position + normal) * CFrame.Angles(math.rad(-90), 0, 0)
    p.Parent = lightmapStorage
    
    local decal = Instance.new("Decal")
    decal.Face = Enum.NormalId.Top
    decal.Texture = textureId
    decal.Parent = p
    
    return p, decal
end

--==================================================
-- RENDER MAP POINT
--==================================================
local function renderMapPoint(part, worldPos, normal, lights)
    local point, decal = createLightPoint(worldPos, normal)
    
    -- Sun soft shadow
    local sunDiffuse, shadowFactor = calculateSunDiffuseSoft(normal, worldPos)
    if shadowFactor >= 1 then
        decal.Color3 = shadowColor
        decal.Transparency = shadowDarkness
    elseif shadowFactor > 0 then
        local blendedColor = shadowColor:Lerp(ambientColor, sunDiffuse)
        decal.Color3 = blendedColor
        decal.Transparency = 1 - sunDiffuse
    else
        decal.Transparency = 1
    end
    
    if renderType == "OnlyShadow" and shadowFactor < 1 then
        point:Destroy()
        return
    end
    
    -- Point lights
    for _, light in ipairs(lights) do
        if light.Parent and not light.Enabled then
            local localDiffuse = calculatePointLightSoft(worldPos, normal, light)
            if localDiffuse and localDiffuse > 0 then
                if renderType == "Shadows+AllLights" then
                    decal.Color3 = Color3.new(
                    math.min(light.Color.R * localDiffuse, 1),
                    math.min(light.Color.G * localDiffuse, 1),
                    math.min(light.Color.B * localDiffuse, 1)
                    )
                    decal.Transparency = 1 - localDiffuse
                elseif renderType == "FullLightMap" then
                    decal.Color3 = light.Color
                    decal.Transparency = 1 - localDiffuse
                elseif renderType == "OnlyShadow" then
                    local rayHit = rayCast(worldPos + normal * epsilon, light.Parent.Position - (worldPos + normal * epsilon), {part, lightmapStorage})
                    if rayHit then
                        decal.Color3 = shadowColor
                        decal.Transparency = shadowDarkness
                    end
                end
            end
        end
    end
    
    decal.Transparency = math.clamp(decal.Transparency, 0, 0.97)
    if decal.Transparency >= 0.95 then point:Destroy() end
end

--==================================================
-- SURFACE RENDER
--==================================================
local function renderSurface(part, normal, originCF, axisA, axisB, lights)
    local size = part.Size
    local sizeA = size[axisA]
    local sizeB = size[axisB]
    
    for a = renderScale, sizeA, renderScale do
        for b = renderScale, sizeB, renderScale do
            local offset = Vector3.new(
            axisA == "X" and a or 0,
            axisA == "Y" and a or 0,
            axisA == "Z" and a or 0
            ) + Vector3.new(
            axisB == "X" and b or 0,
            axisB == "Y" and b or 0,
            axisB == "Z" and b or 0
            )
            local worldPos = originCF * CFrame.new(offset)
            renderMapPoint(part, worldPos.Position, normal, lights)
        end
    end
end

--==================================================
-- PART BAKE
--==================================================
local function bakePart(part, lights)
    local cf = part.CFrame
    local s = part.Size
    renderSurface(part,  cf.UpVector,    cf * CFrame.new(-s.X/2,  s.Y/2, -s.Z/2), "X", "Z", lights)
    renderSurface(part, -cf.UpVector,    cf * CFrame.new(-s.X/2, -s.Y/2, -s.Z/2), "X", "Z", lights)
    renderSurface(part,  cf.RightVector, cf * CFrame.new( s.X/2, -s.Y/2, -s.Z/2), "Y", "Z", lights)
    renderSurface(part, -cf.RightVector, cf * CFrame.new(-s.X/2, -s.Y/2, -s.Z/2), "Y", "Z", lights)
    renderSurface(part, -cf.LookVector,  cf * CFrame.new(-s.X/2, -s.Y/2,  s.Z/2), "X", "Y", lights)
    renderSurface(part,  cf.LookVector,  cf * CFrame.new(-s.X/2, -s.Y/2, -s.Z/2), "X", "Y", lights)
end

--==================================================
-- EXECUTE BAKE
--==================================================
local function bakeAll()
    lightmapStorage:ClearAllChildren()
    local bakedFolder = Workspace:WaitForChild("BakedParts")
    local lights = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("PointLight") then table.insert(lights, obj) end
    end
    for _, obj in ipairs(bakedFolder:GetDescendants()) do
        if obj:IsA("BasePart") then bakePart(obj, lights) end
    end
    print("LightMap bake complete")
end

--==================================================
-- UI REBAKE BUTTON
--==================================================
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LightmapUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(120, 36)
button.Position = UDim2.new(1, -130, 0, 10)
button.AnchorPoint = Vector2.new(0, 0)
button.Text = "Rebake"
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 0
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Parent = gui
button.MouseButton1Click:Connect(function() bakeAll() end)
    
    --==================================================
    -- INITIAL BAKE
    --==================================================
    task.wait(1)
    bakeAll()
