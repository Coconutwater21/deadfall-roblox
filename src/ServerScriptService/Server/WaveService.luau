--!strict
-- Ported from survival_engine.dart _startWave / _updateWaves (see the
-- porting-spec §6 for full numbers). MVP spawns walkers only -- mini-boss/
-- boss/elite injection and the weighted zombie-kind roll table are follow-
-- ups (ZombieData already has every kind's numbers ready for that pass; see
-- MIGRATION.md).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Config)
local ZombieService = require(script.Parent.ZombieService)

local WaveService = {}

local rng = Random.new()

local state = {
	wave = 0,
	waveActive = false,
	remainingToSpawn = 0,
	spawnTimer = 0,
	nextWaveTimer = 1, -- short delay before wave 1 so players can look around.
	waveBannerTimer = 0,
}

local function gameStateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = "GameState"
	local function num(name: string, v: number)
		local val = Instance.new("NumberValue")
		val.Name = name
		val.Value = v
		val.Parent = folder
	end
	local function bool(name: string, v: boolean)
		local val = Instance.new("BoolValue")
		val.Name = name
		val.Value = v
		val.Parent = folder
	end
	num("Wave", 0)
	bool("WaveActive", false)
	num("NextWaveTimer", state.nextWaveTimer)
	num("EnemiesRemaining", 0)
	num("WaveBannerTimer", 0)
	folder.Parent = ReplicatedStorage
	return folder
end

local function syncGameState()
	local folder = gameStateFolder()
	local waveValue = folder.Wave :: NumberValue
	local waveActiveValue = folder.WaveActive :: BoolValue
	local nextWaveTimerValue = folder.NextWaveTimer :: NumberValue
	local enemiesRemainingValue = folder.EnemiesRemaining :: NumberValue
	local waveBannerTimerValue = folder.WaveBannerTimer :: NumberValue

	waveValue.Value = state.wave
	waveActiveValue.Value = state.waveActive
	nextWaveTimerValue.Value = math.max(0, state.nextWaveTimer)
	enemiesRemainingValue.Value = state.remainingToSpawn + ZombieService.count()
	waveBannerTimerValue.Value = math.max(0, state.waveBannerTimer)
end

-- _edgeSpawnPoint: random side, random position along that edge, just
-- outside the wrap boundary.
local function edgeSpawnPointStuds(): Vector3
	local side = rng:NextInteger(0, 3)
	local along = (rng:NextNumber() * 2 - 1) * (Config.ARENA_HALF_UNITS - 0.2)
	local outside = Config.ARENA_HALF_UNITS + 0.18
	local x, z
	if side == 0 then
		x, z = along, -outside
	elseif side == 1 then
		x, z = outside, along
	elseif side == 2 then
		x, z = along, outside
	else
		x, z = -outside, along
	end
	return Vector3.new(x * Config.STUD_SCALE, 4, z * Config.STUD_SCALE)
end

local function startWave()
	state.wave += 1
	state.waveActive = true
	state.waveBannerTimer = Config.WAVE_BANNER_SECONDS
	state.remainingToSpawn = 6 + state.wave * 3
	if state.wave % 5 == 0 then
		state.remainingToSpawn += 4
	end
	state.spawnTimer = 0
end

function WaveService.update(dt: number)
	if state.waveBannerTimer > 0 then
		state.waveBannerTimer = math.max(0, state.waveBannerTimer - dt)
	end

	if not state.waveActive then
		state.nextWaveTimer -= dt
		if state.nextWaveTimer <= 0 then
			startWave()
		end
		syncGameState()
		return
	end

	if state.remainingToSpawn > 0 then
		state.spawnTimer -= dt
		if state.spawnTimer <= 0 then
			ZombieService.spawn("walker", state.wave, edgeSpawnPointStuds())
			state.remainingToSpawn -= 1
			state.spawnTimer = math.max(0.22, 0.75 - state.wave * 0.02)
		end
	end

	if state.remainingToSpawn == 0 and ZombieService.count() == 0 then
		state.waveActive = false
		state.nextWaveTimer = Config.WAVE_INTERMISSION_SECONDS
		WaveService.onWaveCleared(state.wave)
	end

	syncGameState()
end

local waveClearedCallback: ((number) -> ())? = nil
function WaveService.setOnWaveCleared(fn: (number) -> ())
	waveClearedCallback = fn
end
function WaveService.onWaveCleared(wave: number)
	if waveClearedCallback then
		waveClearedCallback(wave)
	end
end

function WaveService.currentWave(): number
	return state.wave
end

return WaveService
