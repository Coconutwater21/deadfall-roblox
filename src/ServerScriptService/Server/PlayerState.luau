--!strict
-- Server-authoritative per-player state. Replicated stat instances (for the
-- client HUD) live under Player.Combat / Player.leaderstats; fast-changing
-- simulation-only fields (aim direction, timers, buffs) stay in a plain Lua
-- table here -- mirrors survival_engine.dart's SurvivalEngine fields, split
-- into "the UI needs to see this" vs "internal only".

local ClassData = require(game:GetService("ReplicatedStorage").Modules.Data.ClassData)
local WeaponData = require(game:GetService("ReplicatedStorage").Modules.Data.WeaponData)
local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

export type State = {
	player: Player,
	classId: ClassData.ClassId,
	weaponId: WeaponData.WeaponId,
	classLevel: number,
	weaponLevels: { [WeaponData.WeaponId]: number },
	abilityLevel: number,
	abilityUnlocked: boolean,
	unlockedClasses: { [ClassData.ClassId]: boolean },
	unlockedWeapons: { [WeaponData.WeaponId]: boolean },
	health: number,
	maxHealth: number,
	money: number,
	kills: number,
	totalMoneyEarned: number,
	totalKills: number,
	ammoInMag: number,
	reloadTimer: number,
	shotCooldown: number,
	firing: boolean,
	aimDirection: Vector3,
	abilityCooldown: number,
	speedBuffTimer: number,
	speedBuffMult: number,
	regenTimer: number,
	baseWalkSpeed: number,
}

local PlayerState = {}
local states: { [Player]: State } = {}

local BASE_WALKSPEED_STUDS = 16 -- Roblox default; class moveSpeed multiplies this.

function PlayerState.init(player: Player): State
	local classId: ClassData.ClassId = "survivor"
	local classDef = ClassData.Classes[classId]
	local weaponId: WeaponData.WeaponId = "pistol"
	local weapon = WeaponData.Weapons[weaponId]

	local state: State = {
		player = player,
		classId = classId,
		weaponId = weaponId,
		classLevel = 0,
		weaponLevels = { [weaponId] = 0 },
		abilityLevel = 0,
		abilityUnlocked = true, -- MVP: Adrenaline is free so the milestone is playable immediately.
		unlockedClasses = { survivor = true },
		unlockedWeapons = { pistol = true },
		health = classDef.maxHealth,
		maxHealth = classDef.maxHealth,
		money = 0,
		kills = 0,
		totalMoneyEarned = 0,
		totalKills = 0,
		ammoInMag = weapon.magazineSize,
		reloadTimer = 0,
		shotCooldown = 0,
		firing = false,
		aimDirection = Vector3.new(0, 0, -1),
		abilityCooldown = 0,
		speedBuffTimer = 0,
		speedBuffMult = 1,
		regenTimer = 0,
		baseWalkSpeed = BASE_WALKSPEED_STUDS,
	}
	states[player] = state
	return state
end

function PlayerState.get(player: Player): State?
	return states[player]
end

function PlayerState.remove(player: Player)
	states[player] = nil
end

function PlayerState.all(): { [Player]: State }
	return states
end

function PlayerState.effectiveWalkSpeed(state: State): number
	local classDef = ClassData.Classes[state.classId]
	local speedMult = 1 + state.classLevel * 0.04 -- UpgradeCurves.classSpeedMult
	return classDef.moveSpeed * speedMult * state.speedBuffMult * state.baseWalkSpeed
end

return PlayerState
