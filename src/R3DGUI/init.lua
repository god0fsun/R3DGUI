local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera :: Camera

local rad = math.rad
local CF = CFrame.new
local ANG = CFrame.Angles

export type GUISettings = {
    Offset : CFrame,
    LerpDelta : number
}

local _3DGUi = {}
_3DGUi.__index = _3DGUi

local Spring = require(script.Spring)

function _3DGUi.new(gui:BillboardGui, Settings : GUISettings)
   local self = setmetatable({}, _3DGUi)
   self.offset = Settings.Offset
   self.__lerpdelta = Settings.lerpdelta

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

   self.__springPos = Spring.new(Vector3.zero)
   self.__springRot = Spring.new(Vector3.zero)

   self.__update = RunService.RenderStepped:Connect(function(deltaTime)
        local ratios = {
            X = Camera.ViewportSize.X/Camera.ViewportSize.Y,
            Y = Camera.ViewportSize.Y/Camera.ViewportSize.X
        }

        local posSpring = self.__springPos.Position :: Vector3
        local rotSpring = self.__springRot.Position :: Vector3
        local offsetPosition = self.offset.Position
        local offsetRotation = Vector3.new(self.offset:ToEulerAnglesXYZ())

        local offset = Vector3.new(
            offsetPosition.X * ratios.X,
            offsetPosition.Y * ratios.Y,
            offsetPosition.Z * posSpring.Z
        )

        local rotation = ANG(
            rad(offsetRotation.X),
            rad(offsetRotation.Y),
            rad(offsetRotation.Z)
        )

        local springCF = CF(posSpring) * ANG(rotSpring)
        local newOffset = CF(offset) * rotation
        self.__currentOffset = self.__currentOffset:Lerp(newOffset, self.__lerpdelta) * springCF

        self.__part.CFrame = self.__currentOffset
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