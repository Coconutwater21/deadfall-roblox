--!strict
-- Renders a brief neon tracer line for every shot the server resolves.
-- Combat itself is fully server-authoritative (CombatService.luau) and has
-- no client-visible projectile by default -- this is pure presentation,
-- fired to all clients via Remotes.ShootEffect after each pellet resolves.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)

local ShotEffects = {}

local TRACER_LIFETIME = 0.08
local TRACER_THICKNESS = 0.18

local function drawTracer(origin: Vector3, endPoint: Vector3)
	local distance = (endPoint - origin).Magnitude
	if distance < 0.05 then
		return
	end
	local part = Instance.new("Part")
	part.Name = "Tracer"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 235, 170)
	part.Size = Vector3.new(TRACER_THICKNESS, TRACER_THICKNESS, distance)
	part.CFrame = CFrame.new(origin, endPoint) * CFrame.new(0, 0, -distance / 2)
	part.Parent = workspace
	Debris:AddItem(part, TRACER_LIFETIME)
end

function ShotEffects.start()
	Remotes.ShootEffect.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.origin) == "Vector3" and typeof(payload.endPoint) == "Vector3" then
			drawTracer(payload.origin, payload.endPoint)
		end
	end)
end

return ShotEffects
