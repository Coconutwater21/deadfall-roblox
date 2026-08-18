--!strict
-- Ported from survival_engine.dart fire() / _applyWeaponHit() (porting spec
-- §4). MVP keeps hitscan + pierce + blast (the data-driven parts) but skips
-- status effects (ignite/virus/slow) and every weapon-mastery on-hit gimmick
-- -- those are pure additions once a weapon is equipped, see MIGRATION.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Modules.Config)
local WeaponData = require(ReplicatedStorage.Modules.Data.WeaponData)
local ZombieData = require(ReplicatedStorage.Modules.Data.ZombieData)
local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)
local PlayerState = require(script.Parent.PlayerState)
local ZombieService = require(script.Parent.ZombieService)
local EconomyService = require(script.Parent.EconomyService)

local CombatService = {}

local rng = Random.new()
local SHOULDER_HEIGHT_STUDS = 3

local function weaponDamageMult(level: number): number
	return 1 + level * 0.12
end
local function weaponCooldownMult(level: number): number
	return math.max(0.7, 1 - level * 0.05)
end
local function weaponReloadMult(level: number): number
	return math.max(0.6, 1 - level * 0.07)
end
local function weaponMagBonus(level: number): number
	return level
end

local function weaponLevel(state: PlayerState.State): number
	return state.weaponLevels[state.weaponId] or 0
end

local function rotateY(v: Vector3, angle: number): Vector3
	local c, s = math.cos(angle), math.sin(angle)
	return Vector3.new(v.X * c + v.Z * s, v.Y, -v.X * s + v.Z * c)
end

local function obstacleParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local arena = workspace:FindFirstChild("Arena")
	local props = arena and arena:FindFirstChild("Props")
	params.FilterDescendantsInstances = props and { props } or {}
	return params
end

-- Distance to the first obstacle along the ray, or maxDistance if clear.
local function occlusionDistance(origin: Vector3, direction: Vector3, maxDistance: number): number
	local result = workspace:Raycast(origin, direction * maxDistance, obstacleParams())
	if result then
		return (result.Position - origin).Magnitude
	end
	return maxDistance
end

type HitCandidate = { model: Model, along: number }

-- All zombies whose root lies within their hitRadius of the ray segment
-- [origin, origin + direction*occludedDist], sorted nearest-first. Mirrors
-- _rayHitDistance's closest-point-on-ray test (spec §4).
local function collectHitsAlongRay(origin: Vector3, direction: Vector3, occludedDist: number): { HitCandidate }
	local hits: { HitCandidate } = {}
	for _, model in CollectionService:GetTagged("Zombie") do
		local runtime = ZombieService.getRuntime(model :: Model)
		if runtime then
			local toZombie = runtime.root.Position - origin
			local along = toZombie:Dot(direction)
			if along >= 0 and along <= occludedDist then
				local perp = (toZombie - direction * along).Magnitude
				local hitRadiusStuds = math.max(1.5, ZombieData.hitRadius(runtime.kind) * Config.STUD_SCALE)
				if perp <= hitRadiusStuds then
					table.insert(hits, { model = model :: Model, along = along })
				end
			end
		end
	end
	table.sort(hits, function(a, b)
		return a.along < b.along
	end)
	return hits
end

local function applyHit(model: Model, damage: number, player: Player)
	local runtime = ZombieService.getRuntime(model)
	if not runtime then
		return
	end
	local def = ZombieData.Zombies[runtime.kind]
	local dealt = damage * def.damageTakenFactor
	local wasAlive = runtime.health > 0
	ZombieService.applyDamage(model, dealt, player)
	if wasAlive and ZombieService.getRuntime(model) == nil then
		-- Died from this hit.
		EconomyService.awardKill(player, runtime.kind, runtime.wave)
	end
end

local function detonateBlast(center: Vector3, damage: number, radiusStuds: number, player: Player)
	for _, model in CollectionService:GetTagged("Zombie") do
		local runtime = ZombieService.getRuntime(model :: Model)
		if runtime and (runtime.root.Position - center).Magnitude <= radiusStuds then
			applyHit(model :: Model, damage, player)
		end
	end
end

local function fire(player: Player, aimDirection: Vector3)
	local state = PlayerState.get(player)
	if not state or state.health <= 0 then
		return
	end
	if state.reloadTimer > 0 then
		return
	end
	if state.shotCooldown > 0 then
		return
	end
	if state.ammoInMag <= 0 then
		CombatService.startReload(player)
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local weapon = WeaponData.Weapons[state.weaponId]
	local level = weaponLevel(state)
	local dir = Vector3.new(aimDirection.X, 0, aimDirection.Z)
	if dir.Magnitude < 0.001 then
		return
	end
	dir = dir.Unit

	local origin = (root :: BasePart).Position + Vector3.new(0, SHOULDER_HEIGHT_STUDS, 0)
	local rangeStuds = weapon.range * Config.STUD_SCALE
	local damage = weapon.damage * weaponDamageMult(level)

	state.ammoInMag -= 1
	state.shotCooldown = weapon.cooldown * weaponCooldownMult(level)

	for _ = 1, weapon.pellets do
		local spreadAngle = (rng:NextNumber() - 0.5) * weapon.spread
		local pelletDir = rotateY(dir, spreadAngle)
		local occluded = occlusionDistance(origin, pelletDir, rangeStuds)
		local hits = collectHitsAlongRay(origin, pelletDir, occluded)

		if weapon.explosionRadius > 0 then
			local impact = origin + pelletDir * occluded
			if #hits > 0 then
				local firstRuntime = ZombieService.getRuntime(hits[1].model)
				if firstRuntime then
					impact = firstRuntime.root.Position
				end
			end
			detonateBlast(impact, damage, weapon.explosionRadius * Config.STUD_SCALE, player)
		elseif weapon.pierces then
			for _, hit in hits do
				applyHit(hit.model, damage, player)
			end
		elseif #hits > 0 then
			applyHit(hits[1].model, damage, player)
		end
	end
end

function CombatService.startReload(player: Player)
	local state = PlayerState.get(player)
	if not state or state.reloadTimer > 0 then
		return
	end
	local weapon = WeaponData.Weapons[state.weaponId]
	local level = weaponLevel(state)
	if state.ammoInMag >= weapon.magazineSize + weaponMagBonus(level) then
		return
	end
	state.reloadTimer = weapon.reloadSeconds * weaponReloadMult(level)
end

function CombatService.update(dt: number)
	for player, state in PlayerState.all() do
		if state.shotCooldown > 0 then
			state.shotCooldown = math.max(0, state.shotCooldown - dt)
		end
		if state.reloadTimer > 0 then
			state.reloadTimer = math.max(0, state.reloadTimer - dt)
			if state.reloadTimer == 0 then
				local weapon = WeaponData.Weapons[state.weaponId]
				state.ammoInMag = weapon.magazineSize + weaponMagBonus(weaponLevel(state))
			end
		end
		if state.firing and state.health > 0 then
			fire(player, state.aimDirection)
		end
	end
end

function CombatService.start()
	Remotes.RequestFire.OnServerEvent:Connect(function(player: Player, aimDirection: Vector3)
		local state = PlayerState.get(player)
		if not state or typeof(aimDirection) ~= "Vector3" then
			return
		end
		state.aimDirection = aimDirection
		state.firing = true
	end)

	Remotes.RequestFireStop.OnServerEvent:Connect(function(player: Player)
		local state = PlayerState.get(player)
		if state then
			state.firing = false
		end
	end)

	Remotes.RequestReload.OnServerEvent:Connect(function(player: Player)
		CombatService.startReload(player)
	end)
end

return CombatService
