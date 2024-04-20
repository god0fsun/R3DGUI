local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera :: Camera

local rad = math.rad
local CF = CFrame.new
local ANG = CFrame.Angles
local V3 = Vector3.new
local V3Z = Vector3.zero

export type GUISettings = {
    Offset : CFrame,
    Size : Vector3,
    LerpDelta : number
}

local _3DGUi = {}
_3DGUi.__index = _3DGUi

local Spring = require(script.Spring)

function _3DGUi.new(gui:BillboardGui, Settings : GUISettings)
   local self = setmetatable({}, _3DGUi)
   self.offset = Settings.Offset
   self.__lerpdelta = Settings.lerpdelta
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

   self.__currentOffset = Settings.Offset
   self.__currentSize = Settings.Size

   self.__springPos = Spring.new(V3Z)
   self.__springRot = Spring.new(V3Z)
   self.__springSize = Spring.new(V3Z)

   self.__update = RunService.RenderStepped:Connect(function(deltaTime)
        local ratios = {
            X = Camera.ViewportSize.X/Camera.ViewportSize.Y,
            Y = Camera.ViewportSize.Y/Camera.ViewportSize.X
        }

        local posSpring = self.__springPos.Position :: Vector3
        local rotSpring = self.__springRot.Position :: Vector3
        local sizeSpring = self.__springSize.Position :: Vector3
        local offsetPosition = self.offset.Position
        local offsetSize = self.size
        local offsetRotation = Vector3.new(self.offset:ToEulerAnglesXYZ())

        local offset = Vector3.new(
            offsetPosition.X * ratios.X,
            offsetPosition.Y * ratios.Y,
            offsetPosition.Z
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


        local springCF = CF(posSpring) * ANG(rotSpring)
        local newOffset = CF(offset) * rotation
        self.__currentOffset = self.__currentOffset:Lerp(newOffset, self.__lerpdelta) * springCF

        self.__part.CFrame = self.__currentOffset
        self.__part.Size = self.__currentSize
   end)

   return self
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