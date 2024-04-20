local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera :: Camera

local rad = math.rad
local CF = CFrame.new
local ANG = CFrame.Angles
local V3 = Vector3.new
local V3Z = Vector3.zero

local preference = 15 -- Multiply offset provided in settings by this for easier offset apply

export type GUISettings = {
    Offset : CFrame,
    Size : Vector3,
    LerpDelta : number
}

local _3DGUi = {}
_3DGUi.__index = _3DGUi

local Spring = require(script.Spring)

local function ConvertScreenToWorld(ScreenPosition : Vector2) : Vector3
    local ray = Camera:ScreenPointToRay(ScreenPosition.X, ScreenPosition.Y, 0)
    local world = ray.Origin
    return world
end

local function FindActualOffset(x, y, z)
    x /= preference
    y /= preference
    z = z
   return Vector3.new(x, y, z) 
end

function _3DGUi.new(gui:SurfaceGui, Settings : GUISettings)
   local self = setmetatable({}, _3DGUi)
   self.offset = Settings.Offset
   self.__lerpdelta = Settings.LerpDelta
   self.size = Settings.Size

   self.__part = Instance.new("Part")
   self.__part.Transparency = 1
   self.__part.CanCollide = false
   self.__part.CanQuery = false
   self.__part.CanTouch = false
   self.__part.Anchored = true
   self.__part.Parent = Camera
   self.__part.Name = gui.Name

   self.gui = gui:Clone()
   self.gui.Parent = Player.PlayerGui
   self.gui.Adornee = self.__part
   self.gui.AlwaysOnTop = true
   self.gui.ResetOnSpawn = false

   self.__currentOffset = Settings.Offset
   self.__currentSize = Settings.Size

   self.__springPos = Spring.new(V3Z)
   self.__springRot = Spring.new(V3Z)
   self.__springSize = Spring.new(V3Z)

   self.__springPos._damper = .35
   self.__springPos._speed = 16

   self.__springRot._damper = .35
   self.__springRot._speed = 16

   self.__springSize._damper = .35
   self.__springSize._speed = 16

   self.__update = RunService.PreRender:Connect(function(deltaTimeRender)
        local screenRatio = CF(ConvertScreenToWorld(Camera.ViewportSize))
        local relativeToCamera = Camera.CFrame:ToObjectSpace(screenRatio)

        local posSpring = self.__springPos.Position :: Vector3
        local rotSpring = self.__springRot.Position :: Vector3
        local sizeSpring = self.__springSize.Position :: Vector3
        local offsetPosition = self.offset.Position
        local offsetSize = self.size

        local rx, ry, rz =  self.offset:ToOrientation()
        local offsetRotation = Vector3.new(math.deg(rx), math.deg(ry),math.deg(rz))

        local offset = Vector3.new(
            (offsetPosition.X * preference) * relativeToCamera.X,
            (offsetPosition.Y * preference) * relativeToCamera.Y,
            -offsetPosition.Z
        )

        local rotation = ANG(
            rad(offsetRotation.X),
            rad(offsetRotation.Y),
            rad(offsetRotation.Z)
        )

        local size = V3(
            offsetSize.X * sizeSpring.X,
            offsetSize.Y * sizeSpring.Y,
            offsetSize.Z * sizeSpring.Z
        )


        local springCF = CF(posSpring) * ANG(rad(rotSpring.X), rad(rotSpring.Y), rad(rotSpring.Z))
        local newOffset = Camera.CFrame * CF(offset) * rotation
        self.__currentOffset = self.__currentOffset:Lerp(newOffset, self.__lerpdelta) * springCF

        self.__part.CFrame = self.__currentOffset
        self.__part.Size = self.__currentSize
   end)

   return self
end

function _3DGUi:GetSpringPos()
    return self.__springPos
end

function _3DGUi:GetSpringRot()
    return self.__springRot
end

function _3DGUi:GetSpringSize()
    return self.__springSize
end

function _3DGUi:SetOffset(v3)
    self.offset = v3
end

function _3DGUi.Impulse(self, Position, Rotation)
    if self.__update then
        self.__springPos:Impulse(Position)
        self.__springRot:Impulse(Rotation)
    end
end

function _3DGUi.Destroy(self)
    if self.__update then
        self.__update:Disconnect()
        self.__part:Destroy()
        self.gui:Destroy()
    end
    self = nil
    return self
end

return _3DGUi