----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------
 
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
 
----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
 
local FOLDER_NAME = "WindShake"
 
local RENDER_DISTANCE = 150
local MAX_REFRESH_RATE = 1 / 60
local VOXEL_SIZE = 50
 
----------------------------------------------------------------------
-- VECTORMAP
----------------------------------------------------------------------
 
local VectorMap = {}
VectorMap.__index = VectorMap
 
function VectorMap.new(voxelSize)
    return setmetatable({
    _voxelSize = voxelSize,
    _voxels = {},
    }, VectorMap)
end
 
function VectorMap:AddObject(position, object)
    local voxelSize = self._voxelSize
    local key = Vector3.new(
    math.floor(position.X / voxelSize),
    math.floor(position.Y / voxelSize),
    math.floor(position.Z / voxelSize)
    )
    
    local voxel = self._voxels[key]
    if not voxel then
        voxel = {}
        self._voxels[key] = voxel
    end
    
    local class = object.ClassName
    if not voxel[class] then
        voxel[class] = {}
    end
    
    table.insert(voxel[class], object)
    return key
end
 
function VectorMap:RemoveObject(key, object)
    local voxel = self._voxels[key]
    if not voxel then return end
    
    local bucket = voxel[object.ClassName]
    if not bucket then return end
    
    for i, v in ipairs(bucket) do
        if v == object then
            bucket[i] = bucket[#bucket]
            bucket[#bucket] = nil
            break
        end
    end
    
    if #bucket == 0 then
        voxel[object.ClassName] = nil
        if next(voxel) == nil then
            self._voxels[key] = nil
        end
    end
end
 
function VectorMap:ForEachObjectInView(camera, distance, callback)
    local voxelSize = self._voxelSize
    local camCF = camera.CFrame
    local camPos = camCF.Position
    
    local farPos = (camCF * CFrame.new(0, 0, -distance)).Position
    local minBound = camPos:Min(farPos)
    local maxBound = camPos:Max(farPos)
    
    minBound = Vector3.new(
    math.floor(minBound.X / voxelSize),
    math.floor(minBound.Y / voxelSize),
    math.floor(minBound.Z / voxelSize)
    )
    
    maxBound = Vector3.new(
    math.floor(maxBound.X / voxelSize),
    math.floor(maxBound.Y / voxelSize),
    math.floor(maxBound.Z / voxelSize)
    )
    
    for x = minBound.X, maxBound.X do
        for y = minBound.Y, maxBound.Y do
            for z = minBound.Z, maxBound.Z do
                local voxel = self._voxels[Vector3.new(x, y, z)]
                if voxel then
                    for _, objects in pairs(voxel) do
                        for _, object in ipairs(objects) do
                            callback(object)
                        end
                    end
                end
            end
        end
    end
end
 
function VectorMap:Clear()
    self._voxels = {}
end
 
----------------------------------------------------------------------
-- WIND SHAKE CORE
----------------------------------------------------------------------
 
local WindFolder = Workspace:WaitForChild(FOLDER_NAME)
 
local VectorMapInstance = VectorMap.new(VOXEL_SIZE)
local Metadata = {}
 
local PartList = {}
local CFrameList = {}
 
----------------------------------------------------------------------
-- OBJECT MANAGEMENT
----------------------------------------------------------------------
 
local function addObject(object)
    if not (object:IsA("BasePart") or object:IsA("Bone")) then return end
    if Metadata[object] then return end
    
    Metadata[object] = {
    Key = VectorMapInstance:AddObject(
    object:IsA("Bone") and object.WorldPosition or object.Position,
    object
    ),
    Origin = object:IsA("Bone") and object.WorldCFrame or object.CFrame,
    PivotOffset = object:IsA("BasePart") and object.PivotOffset or nil,
    PivotOffsetInverse = object:IsA("BasePart") and object.PivotOffset:Inverse() or nil,
    Seed = math.random() * 5000,
    LastUpdate = 0,
    }
end
 
local function removeObject(object)
    local meta = Metadata[object]
    if not meta then return end
    
    VectorMapInstance:RemoveObject(meta.Key, object)
    
    if object:IsA("Bone") then
        object.WorldCFrame = meta.Origin
    else
        object.CFrame = meta.Origin
    end
    
    Metadata[object] = nil
end
 
----------------------------------------------------------------------
-- FOLDER WATCHING
----------------------------------------------------------------------
 
for _, obj in ipairs(WindFolder:GetDescendants()) do
    addObject(obj)
end
 
WindFolder.DescendantAdded:Connect(addObject)
WindFolder.DescendantRemoving:Connect(removeObject)
 
----------------------------------------------------------------------
-- UPDATE LOOP
----------------------------------------------------------------------
 
RunService.Heartbeat:Connect(function(dt)
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    local now = os.clock()
    local camPos = camera.CFrame.Position
    local bulkIndex = 0
    
    table.clear(PartList)
    table.clear(CFrameList)
    
    local globalWind = Workspace.GlobalWind
    local windMagnitude = globalWind.Magnitude
    if windMagnitude <= 0.01 then return end
    
    local windDir = globalWind.Unit
    local windPower = math.clamp(math.log10(windMagnitude + 1), 0.1, 2)
    local windSpeed = math.clamp(windMagnitude * 0.12 + 6, 6, 120)
    
    VectorMapInstance:ForEachObjectInView(camera, RENDER_DISTANCE, function(object)
        local meta = Metadata[object]
        if not meta then return end
        
        local worldCF = object:IsA("Bone") and object.WorldCFrame or object.CFrame
        local dist = (camPos - worldCF.Position).Magnitude
        local refresh = (dt * 3) * (dist / RENDER_DISTANCE)^2 + MAX_REFRESH_RATE
        
        if now - meta.LastUpdate < refresh then return end
        meta.LastUpdate = now
        
        local freq = now * (windSpeed * 0.08)
        local amp = windPower * 0.2
        local seed = meta.Seed
        
        local anim = (math.noise(freq, 0, seed) + 0.4) * amp
        local lowAmp = amp / 3
        
        local origin = meta.Origin * (meta.PivotOffset or CFrame.identity)
        local localDir = origin:VectorToObjectSpace(windDir)
        
        local transform =
        CFrame.fromAxisAngle(localDir:Cross(Vector3.yAxis), -anim)
        * CFrame.Angles(
        math.noise(seed, 0, freq) * lowAmp,
        math.noise(seed, freq, 0) * lowAmp,
        math.noise(freq, seed, 0) * lowAmp
        )
        
        if object:IsA("Bone") then
            object.Transform = object.Transform:Lerp(
            transform + localDir * anim * amp,
            dt * 5
            )
        else
            bulkIndex = bulkIndex + 1
            PartList[bulkIndex] = object
            CFrameList[bulkIndex] =
            worldCF:Lerp(
            origin * transform * (meta.PivotOffsetInverse or CFrame.identity)
            + windDir * anim * (amp * 2),
            dt * 5
            )
        end
    end)
    
    if bulkIndex > 0 then
        Workspace:BulkMoveTo(PartList, CFrameList, Enum.BulkMoveMode.FireCFrameChanged)
    end
end)
