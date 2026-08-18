--!strict
-- Server boot. Wires up the world, player lifecycle, combat, waves, economy,
-- abilities, and progression services, then runs the single authoritative
-- simulation Heartbeat -- mirrors survival_engine.dart's update(dt) order
-- (see porting spec §2): timers/buffs, player state, waves, zombies, sync.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
require(ReplicatedStorage.Modules.Net.Remotes) -- ensure RemoteEvents exist before anyone connects.

local WorldBuilder = require(script.WorldBuilder)
local PlayerState = require(script.PlayerState)
local PlayerService = require(script.PlayerService)
local ZombieService = require(script.ZombieService)
local WaveService = require(script.WaveService)
local EconomyService = require(script.EconomyService)
local AbilityService = require(script.AbilityService)
local CombatService = require(script.CombatService)
local ProgressionService = require(script.ProgressionService)

local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)

WorldBuilder.build()

ZombieService.onPlayerHurt(function(player: Player, amount: number)
	local state = PlayerState.get(player)
	if not state or state.health <= 0 then
		return
	end
	state.health = math.max(0, state.health - math.max(1, math.round(amount)))
end)

WaveService.setOnWaveCleared(function(wave: number)
	EconomyService.awardWaveClearBonus(wave)
end)

PlayerService.start()
CombatService.start()
ProgressionService.start()

Remotes.RequestAbility.OnServerEvent:Connect(function(player: Player)
	AbilityService.activate(player)
end)

local lastWave = 0
RunService.Heartbeat:Connect(function(rawDt: number)
	local dt = math.min(rawDt, Config.MAX_DT)

	AbilityService.update(dt)
	WaveService.update(dt)
	ZombieService.update(dt)
	CombatService.update(dt)

	local currentWave = WaveService.currentWave()
	if currentWave ~= lastWave and currentWave > 0 then
		lastWave = currentWave
		Remotes.WaveBanner:FireAllClients({ wave = currentWave })
	end

	for player, state in PlayerState.all() do
		if state.health <= 0 then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end
		PlayerService.syncStats(state)
	end
end)
