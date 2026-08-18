--!strict
-- Minimal HUD mirroring the elements identified in the UI porting spec §2:
-- health bar, ammo/reload, money, kills, wave/enemies-remaining, ability
-- cooldown, plus the wave-start banner and generic notification toast.
-- Built with plain Instance.new rather than a UI framework to keep the MVP
-- dependency-free; every value is re-read from the replicated stat folders
-- each frame (matches the "poll and rebuild" pattern from the UI spec §7).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)

local HUDMain = {}

local player = Players.LocalPlayer

local function makeLabel(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = false
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

local function makeBar(parent: Instance, position: UDim2, size: UDim2, fillColor: Color3): (Frame, Frame)
	local back = Instance.new("Frame")
	back.Position = position
	back.Size = size
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	back.BorderSizePixel = 0
	back.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = back

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	return back, fill
end

function HUDMain.start()
	local playerGui = player:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "DeadfallHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui

	-- Health bar (top-left).
	local healthBack, healthFill = makeBar(screen, UDim2.fromOffset(16, 16), UDim2.fromOffset(240, 22), Color3.fromRGB(90, 200, 100))
	local healthText = makeLabel(healthBack, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 15,
		Text = "100 / 100",
	})

	-- Ability cooldown bar (under health).
	local abilityBack, abilityFill = makeBar(screen, UDim2.fromOffset(16, 44), UDim2.fromOffset(240, 14), Color3.fromRGB(120, 170, 255))
	local abilityText = makeLabel(abilityBack, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 11,
		Text = "ADRENALINE READY (Q)",
	})

	-- Money / kills (top-left, under ability bar).
	local moneyLabel = makeLabel(screen, {
		Position = UDim2.fromOffset(16, 64),
		Size = UDim2.fromOffset(240, 20),
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 221, 120),
		Text = "$0",
	})
	local killsLabel = makeLabel(screen, {
		Position = UDim2.fromOffset(16, 84),
		Size = UDim2.fromOffset(240, 20),
		TextSize = 16,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		Text = "0 kills",
	})

	-- Ammo (bottom-right).
	local ammoLabel = makeLabel(screen, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(200, 26),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 22,
		Text = "12 / 12",
	})

	-- Wave / enemies (top-center).
	local waveLabel = makeLabel(screen, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(300, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 18,
		Text = "WAVE 0",
	})

	-- Wave banner (big centered, fades via WaveBannerTimer).
	local banner = makeLabel(screen, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(500, 60),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 40,
		TextColor3 = Color3.fromRGB(255, 90, 90),
		TextTransparency = 1,
		Text = "",
	})

	-- Notification toast (below wave banner spot).
	local toast = makeLabel(screen, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(500, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 16,
		TextTransparency = 1,
		Text = "",
	})

	local toastTimer = 0
	Remotes.Notify.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.text) == "string" then
			toast.Text = payload.text
			toastTimer = 2.2
		end
	end)

	local bannerText = ""
	Remotes.WaveBanner.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.wave) == "number" then
			bannerText = "WAVE " .. payload.wave
		end
	end)

	RunService.RenderStepped:Connect(function(dt: number)
		local combat = player:FindFirstChild("Combat")
		local leaderstats = player:FindFirstChild("leaderstats")
		local gameState = ReplicatedStorage:FindFirstChild("GameState")

		if combat then
			local c = combat :: Folder
			local health = (c.Health :: NumberValue).Value
			local maxHealth = (c.MaxHealth :: NumberValue).Value
			local pct = maxHealth > 0 and math.clamp(health / maxHealth, 0, 1) or 0
			healthFill.Size = UDim2.fromScale(pct, 1)
			healthFill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(90, 200, 100)
				or pct > 0.25 and Color3.fromRGB(230, 170, 60)
				or Color3.fromRGB(220, 70, 70)
			healthText.Text = string.format("%d / %d", math.ceil(health), maxHealth)

			local ammo = (c.AmmoInMag :: NumberValue).Value
			local magSize = (c.MagazineSize :: NumberValue).Value
			local reloadTimer = (c.ReloadTimer :: NumberValue).Value
			ammoLabel.Text = reloadTimer > 0 and "RELOADING..." or string.format("%d / %d", ammo, magSize)

			local abilityCd = (c.AbilityCooldown :: NumberValue).Value
			local abilityCdMax = math.max(0.001, (c.AbilityCooldownMax :: NumberValue).Value)
			local ready = abilityCd <= 0
			abilityFill.Size = UDim2.fromScale(1 - math.clamp(abilityCd / abilityCdMax, 0, 1), 1)
			abilityFill.BackgroundColor3 = ready and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(90, 90, 100)
			abilityText.Text = ready and "ADRENALINE READY (Q)" or string.format("ADRENALINE %.1fs", abilityCd)
		end

		if leaderstats then
			local ls = leaderstats :: Folder
			moneyLabel.Text = "$" .. tostring((ls.Money :: IntValue).Value)
			killsLabel.Text = tostring((ls.Kills :: IntValue).Value) .. " kills"
		end

		if gameState then
			local gs = gameState :: Folder
			local wave = (gs.Wave :: NumberValue).Value
			local waveActive = (gs.WaveActive :: BoolValue).Value
			local nextTimer = (gs.NextWaveTimer :: NumberValue).Value
			local remaining = (gs.EnemiesRemaining :: NumberValue).Value
			if waveActive then
				waveLabel.Text = string.format("WAVE %d - %d LEFT", wave, remaining)
			else
				waveLabel.Text = string.format("WAVE %d CLEARED - NEXT IN %.0fs", wave, math.max(0, nextTimer))
			end

			local bannerTimer = (gs.WaveBannerTimer :: NumberValue).Value
			if bannerTimer > 0 then
				banner.Text = bannerText
				banner.TextTransparency = 1 - math.clamp(bannerTimer / 2.4, 0, 1)
			else
				banner.TextTransparency = 1
			end
		end

		if toastTimer > 0 then
			toastTimer = math.max(0, toastTimer - dt)
			toast.TextTransparency = toastTimer > 0.3 and 0 or (1 - toastTimer / 0.3)
		else
			toast.TextTransparency = 1
		end
	end)
end

return HUDMain
