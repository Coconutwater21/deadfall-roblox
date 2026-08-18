--!strict
-- Fixed-angle overhead "iso-ish" camera that always frames the character
-- from the same direction, rather than rotating behind the player's facing
-- -- this is the closest Roblox-native equivalent to Deadfall's fixed
-- top-down projection (porting spec §1: the Dart sim itself is flat 2D,
-- iso-ness was purely a rendering rotation we don't need in true 3D).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraController = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera

-- Direction the camera sits relative to the character; fixed so the whole
-- arena keeps a consistent readable orientation like the original.
local OFFSET_DIR = Vector3.new(0.55, 1, 0.55).Unit
local DISTANCE_STUDS = 46

local groundPlaneY = 3 -- roughly character waist height, matches shoulder-height shot origin.

function CameraController.start()
	camera.CameraType = Enum.CameraType.Scriptable

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local focus = (root :: BasePart).Position
		local eye = focus + OFFSET_DIR * DISTANCE_STUDS
		camera.CFrame = CFrame.lookAt(eye, focus)
	end)
end

-- Projects the mouse cursor onto the y = groundPlaneY plane so InputController
-- can derive a world-space aim direction from 2D mouse position.
function CameraController.mouseWorldPoint(): Vector3?
	local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local direction = ray.Direction
	if math.abs(direction.Y) < 1e-4 then
		return nil
	end
	local t = (groundPlaneY - ray.Origin.Y) / direction.Y
	if t < 0 then
		return nil
	end
	return ray.Origin + direction * t
end

return CameraController
