--!strict
-- Player lifecycle: join/leave, character spawning, and the replicated stat
-- instances the client HUD reads. See MIGRATION.md for why death here is a
-- "respawn after a few seconds" instead of Dart's single-player game-over --
-- this port defaults to shared co-op survival (per the project brief).
local Players = game:GetService("Players")
local ClassData = require(game:GetService("ReplicatedStorage").Modules.Data.ClassData)
local WeaponData = require(game:GetService("ReplicatedStorage").Modules.Data.WeaponData)
local PlayerState = require(script.Parent.PlayerState)

local PlayerService = {}

local RESPAWN_DELAY = 3
local SPAWN_RADIUS_STUDS = 8

local function buildStatInstances(player: Player, state: PlayerState.State)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = state.money
	money.Parent = leaderstats
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = state.kills
	kills.Parent = leaderstats
	leaderstats.Parent = player

	local combat = Instance.new("Folder")
	combat.Name = "Combat"
	local function num(name: string, value: number): NumberValue
		local v = Instance.new("NumberValue")
		v.Name = name
		v.Value = value
		v.Parent = combat
		return v
	end
	local function str(name: string, value: string): StringValue
		local v = Instance.new("StringValue")
		v.Name = name
		v.Value = value
		v.Parent = combat
		return v
	end
	num("Health", state.health)
	num("MaxHealth", state.maxHealth)
	num("AmmoInMag", state.ammoInMag)
	num("MagazineSize", WeaponData.Weapons[state.weaponId].magazineSize)
	num("ReloadTimer", 0)
	num("AbilityCooldown", 0)
	num("AbilityCooldownMax", ClassData.Classes[state.classId].abilityCooldown)
	num("ClassLevel", state.classLevel)
	num("WeaponLevel", 0)
	str("ClassId", state.classId)
	str("WeaponId", state.weaponId)
	combat.Parent = player
end

-- Keeps the replicated instances in sync with the authoritative Lua state.
-- Called by the main Heartbeat loop rather than on every single mutation, to
-- keep this cheap (mirrors Dart's "everything re-reads every frame" model).
function PlayerService.syncStats(state: PlayerState.State)
	local player = state.player
	local leaderstats = player:FindFirstChild("leaderstats")
	local combat = player:FindFirstChild("Combat")
	if leaderstats then
		local ls = leaderstats :: Folder
		local moneyValue = ls.Money :: IntValue
		local killsValue = ls.Kills :: IntValue
		moneyValue.Value = state.money
		killsValue.Value = state.kills
	end
	if combat then
		local c = combat :: Folder
		local healthValue = c.Health :: NumberValue
		local maxHealthValue = c.MaxHealth :: NumberValue
		local ammoValue = c.AmmoInMag :: NumberValue
		local magSizeValue = c.MagazineSize :: NumberValue
		local reloadTimerValue = c.ReloadTimer :: NumberValue
		local abilityCooldownValue = c.AbilityCooldown :: NumberValue
		local abilityCooldownMaxValue = c.AbilityCooldownMax :: NumberValue
		local classLevelValue = c.ClassLevel :: NumberValue
		local weaponIdValue = c.WeaponId :: StringValue
		local classIdValue = c.ClassId :: StringValue

		healthValue.Value = state.health
		maxHealthValue.Value = state.maxHealth
		ammoValue.Value = state.ammoInMag
		magSizeValue.Value = WeaponData.Weapons[state.weaponId].magazineSize
		reloadTimerValue.Value = state.reloadTimer
		abilityCooldownValue.Value = state.abilityCooldown
		abilityCooldownMaxValue.Value = ClassData.Classes[state.classId].abilityCooldown
		classLevelValue.Value = state.classLevel
		weaponIdValue.Value = state.weaponId
		classIdValue.Value = state.classId
	end
end

local function spawnCharacter(player: Player, state: PlayerState.State)
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.WalkSpeed = PlayerState.effectiveWalkSpeed(state)
	humanoid.MaxHealth = math.huge -- we manage HP ourselves via state.health, not the Roblox humanoid.
	humanoid.Health = humanoid.MaxHealth

	local angle = math.random() * math.pi * 2
	root.CFrame = CFrame.new(math.cos(angle) * SPAWN_RADIUS_STUDS, 4, math.sin(angle) * SPAWN_RADIUS_STUDS)

	humanoid.Died:Connect(function()
		task.wait(RESPAWN_DELAY)
		if player.Parent then
			state.health = state.maxHealth
			state.ammoInMag = WeaponData.Weapons[state.weaponId].magazineSize
			spawnCharacter(player, state)
		end
	end)
end

function PlayerService.onPlayerAdded(player: Player)
	local state = PlayerState.init(player)
	buildStatInstances(player, state)
	spawnCharacter(player, state)
end

function PlayerService.onPlayerRemoving(player: Player)
	PlayerState.remove(player)
end

function PlayerService.start()
	-- We call LoadCharacter() ourselves in spawnCharacter(); without this,
	-- Roblox's automatic join-spawn would race it and create an extra
	-- throwaway character.
	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(PlayerService.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerService.onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		PlayerService.onPlayerAdded(player)
	end
end

return PlayerService
