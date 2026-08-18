--!strict
-- Maps mouse/keyboard input to the combat RemoteEvents. Movement itself is
-- left to Roblox's default WASD character controller (it moves relative to
-- Camera.CFrame automatically, which CameraController keeps at a fixed
-- angle) -- porting spec §3 notes Dart's own movement was just "screen-space
-- WASD rotated into world space," which is exactly what the default
-- controller already gives us for free against a fixed-angle camera.
--
-- Keybinds (documented choice, not from Dart's keybind_settings.dart which
-- wasn't read in full -- see MIGRATION.md): hold left mouse to fire, R to
-- reload, Q to activate class ability.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)
local CameraController = require(script.Parent.CameraController)

local InputController = {}

local player = Players.LocalPlayer
local firing = false

local function currentAimDirection(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local groundPoint = CameraController.mouseWorldPoint()
	if not groundPoint then
		return nil
	end
	local origin = (root :: BasePart).Position
	local delta = Vector3.new(groundPoint.X - origin.X, 0, groundPoint.Z - origin.Z)
	if delta.Magnitude < 0.01 then
		return nil
	end
	return delta.Unit
end

function InputController.start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = true
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.RequestReload:FireServer()
		elseif input.KeyCode == Enum.KeyCode.Q then
			Remotes.RequestAbility:FireServer()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = false
			Remotes.RequestFireStop:FireServer()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not firing then
			return
		end
		local dir = currentAimDirection()
		if dir then
			Remotes.RequestFire:FireServer(dir)
		end
	end)
end

return InputController
