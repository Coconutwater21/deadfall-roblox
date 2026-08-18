--!strict
-- Ported from the zombie half of survival_engine.dart's _updateZombies /
-- _tickZombieAbility. MVP scope: straight-line chase + instant melee punch
-- (the Dart "default walker-style punch: instant, no wind-up, cooldown
-- brute?1.15:0.8") for whichever ZombieData kinds WaveService spawns.
-- Ranged specials, elite skills, and wave-based AI variety are follow-ups
-- (see MIGRATION.md) -- the data module already has every kind's numbers,
-- this loop just doesn't branch on them yet beyond speed/hp/melee/reward.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Config)
local ZombieData = require(ReplicatedStorage.Modules.Data.ZombieData)
local PlayerState = require(script.Parent.PlayerState)

local ZombieService = {}

local TAG = "Zombie"
local DEFAULT_ATTACK_COOLDOWN = 0.8
local BRUTE_ATTACK_COOLDOWN = 1.15
local BRUTE_LIKE: { [string]: boolean } = {
	brute = true, bloater = true, hiveMother = true, shieldBearer = true,
	boneGolem = true, hammerMauler = true,
}

type ZombieRuntime = {
	model: Model,
	root: BasePart,
	kind: ZombieData.ZombieId,
	wave: number,
	health: number,
	maxHealth: number,
	speedStuds: number,
	meleeDamage: number,
	meleeReachStuds: number,
	radiusStuds: number,
	attackCooldown: number,
	lastHitBy: Player?,
}

local runtimes: { [Model]: ZombieRuntime } = {}
local onDeathCallback: ((ZombieRuntime) -> ())? = nil

function ZombieService.onDeath(fn: (ZombieRuntime) -> ())
	onDeathCallback = fn
end

local function buildHealthBar(root: BasePart): Frame
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.fromOffset(50, 6)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root

	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	back.BorderSizePixel = 0
	back.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back

	return fill
end

function ZombieService.spawn(kind: ZombieData.ZombieId, wave: number, worldPosStuds: Vector3): Model
	local def = ZombieData.Zombies[kind]
	local radiusUnits = def.radius
	local radiusStuds = math.max(1.5, radiusUnits * Config.STUD_SCALE)

	local model = Instance.new("Model")
	model.Name = def.label

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Shape = Enum.PartType.Block
	root.Size = Vector3.new(radiusStuds * 1.6, radiusStuds * 3.2, radiusStuds * 1.6)
	root.Anchored = true
	root.CanCollide = false
	root.Color = def.color
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(worldPosStuds)
	root.Parent = model
	model.PrimaryPart = root

	buildHealthBar(root)

	local hp = ZombieData.baseHp(kind, wave)
	local runtime: ZombieRuntime = {
		model = model,
		root = root,
		kind = kind,
		wave = wave,
		health = hp,
		maxHealth = hp,
		speedStuds = ZombieData.baseSpeed(kind, wave) * Config.STUD_SCALE,
		meleeDamage = def.meleeDamage,
		meleeReachStuds = def.meleeReach * Config.STUD_SCALE,
		radiusStuds = radiusStuds,
		attackCooldown = 0,
		lastHitBy = nil,
	}
	runtimes[model] = runtime
	model.Parent = workspace.Arena
	CollectionService:AddTag(model, TAG)
	return model
end

function ZombieService.getRuntime(model: Model): ZombieRuntime?
	return runtimes[model]
end

function ZombieService.applyDamage(model: Model, amount: number, fromPlayer: Player?)
	local runtime = runtimes[model]
	if not runtime then
		return
	end
	runtime.health = math.max(0, runtime.health - amount)
	if fromPlayer then
		runtime.lastHitBy = fromPlayer
	end
	local gui = runtime.root:FindFirstChild("HealthBar")
	if gui then
		local back = gui:FindFirstChildOfClass("Frame")
		local fill = back and back:FindFirstChild("Fill")
		if fill then
			(fill :: Frame).Size = UDim2.fromScale(math.clamp(runtime.health / runtime.maxHealth, 0, 1), 1)
		end
	end
	if runtime.health <= 0 then
		runtimes[model] = nil
		if onDeathCallback then
			onDeathCallback(runtime)
		end
		model:Destroy()
	end
end

function ZombieService.count(): number
	local n = 0
	for _ in runtimes do
		n += 1
	end
	return n
end

local function nearestPlayerRoot(fromPos: Vector3): (BasePart?, Player?)
	local best: BasePart? = nil
	local bestPlayer: Player? = nil
	local bestDist = math.huge
	for player, state in PlayerState.all() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and state.health > 0 then
			local dist = Config.wrappedDelta(fromPos, root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = root :: BasePart
				bestPlayer = player
			end
		end
	end
	return best, bestPlayer
end

local hurtPlayerCallback: ((Player, number) -> ())? = nil
function ZombieService.onPlayerHurt(fn: (Player, number) -> ())
	hurtPlayerCallback = fn
end

function ZombieService.update(dt: number)
	for model, runtime in runtimes do
		if runtime.attackCooldown > 0 then
			runtime.attackCooldown -= dt
		end

		local targetRoot, targetPlayer = nearestPlayerRoot(runtime.root.Position)
		if not targetRoot or not targetPlayer then
			continue
		end

		local delta = Config.wrappedDelta(runtime.root.Position, targetRoot.Position)
		local distance = delta.Magnitude
		local reach = runtime.radiusStuds + runtime.meleeReachStuds

		if distance > reach then
			local dir = delta.Unit
			local step = dir * runtime.speedStuds * dt
			local newPos = Config.wrapPosition(runtime.root.Position + step)
			runtime.root.CFrame = CFrame.new(newPos, newPos + dir)
		elseif runtime.attackCooldown <= 0 then
			local cooldown = BRUTE_LIKE[runtime.kind] and BRUTE_ATTACK_COOLDOWN or DEFAULT_ATTACK_COOLDOWN
			runtime.attackCooldown = cooldown
			if hurtPlayerCallback then
				hurtPlayerCallback(targetPlayer, runtime.meleeDamage)
			end
		end
	end
end

return ZombieService
