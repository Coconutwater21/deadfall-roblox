--!strict
-- Ported from lib/game/survival_content.dart (ZombieKind + ZombieKindStats).
-- hpCore/speedCore/reward are the raw per-kind constants; baseHp/baseSpeed/
-- reward below reproduce the exact Dart formulas that scale them by wave.

export type EliteSkill = "dash" | "block" | "groundPound"

export type ZombieId = string

export type ZombieDef = {
	id: ZombieId,
	label: string,
	color: Color3,
	hpCore: number,
	speedCore: number,
	rewardBase: number,
	rewardPerWave: number,
	radius: number,
	meleeDamage: number,
	meleeReach: number,
	prefersRange: boolean,
	preferredRange: number,
	damageTakenFactor: number,
	isMiniBoss: boolean,
	isBoss: boolean,
	isImmobile: boolean,
	eliteSkills: { EliteSkill },
}

local DEFAULT_MELEE_REACH = 0.055

local function rgb(hex: number): Color3
	return Color3.fromRGB(bit32.rshift(hex, 16) % 256, bit32.rshift(hex, 8) % 256, hex % 256)
end

-- label, hex color, hpCore, speedCore, rewardBase, rewardPerWave, radius, meleeDamage,
-- [meleeReach], [prefersRange, preferredRange], [damageTakenFactor], [isMiniBoss],
-- [isBoss], [isImmobile], [eliteSkills]
local Zombies: { [ZombieId]: ZombieDef } = {}

local function add(id: string, def: {
	label: string,
	color: number,
	hpCore: number,
	speedCore: number,
	rewardBase: number,
	rewardPerWave: number,
	radius: number,
	meleeDamage: number,
	meleeReach: number?,
	preferredRange: number?,
	damageTakenFactor: number?,
	isMiniBoss: boolean?,
	isBoss: boolean?,
	isImmobile: boolean?,
	eliteSkills: { EliteSkill }?,
})
	Zombies[id] = {
		id = id,
		label = def.label,
		color = rgb(def.color),
		hpCore = def.hpCore,
		speedCore = def.speedCore,
		rewardBase = def.rewardBase,
		rewardPerWave = def.rewardPerWave,
		radius = def.radius,
		meleeDamage = def.meleeDamage,
		meleeReach = def.meleeReach or DEFAULT_MELEE_REACH,
		prefersRange = def.preferredRange ~= nil,
		preferredRange = def.preferredRange or 0,
		damageTakenFactor = def.damageTakenFactor or 1.0,
		isMiniBoss = def.isMiniBoss or false,
		isBoss = def.isBoss or false,
		isImmobile = def.isImmobile or false,
		eliteSkills = def.eliteSkills or {},
	}
end

-- Regulars
add("walker", { label = "Walker", color = 0x668B52, hpCore = 58.0, speedCore = 0.20, rewardBase = 8, rewardPerWave = 1, radius = 0.05, meleeDamage = 9 })
add("runner", { label = "Runner", color = 0x9CCC65, hpCore = 38.0, speedCore = 0.38, rewardBase = 10, rewardPerWave = 1, radius = 0.045, meleeDamage = 8 })
add("brute", { label = "Brute", color = 0x8E3B31, hpCore = 145.0, speedCore = 0.13, rewardBase = 24, rewardPerWave = 1, radius = 0.075, meleeDamage = 18, meleeReach = 0.09 })
add("spitter", { label = "Spitter", color = 0x8BC34A, hpCore = 52.0, speedCore = 0.16, rewardBase = 14, rewardPerWave = 1, radius = 0.05, meleeDamage = 6, preferredRange = 1.15 })
add("skyCaller", { label = "Sky Caller", color = 0x7E57C2, hpCore = 70.0, speedCore = 0.15, rewardBase = 18, rewardPerWave = 1, radius = 0.055, meleeDamage = 8, preferredRange = 1.35 })
add("necromancer", { label = "Necromancer", color = 0x5E35B1, hpCore = 85.0, speedCore = 0.14, rewardBase = 22, rewardPerWave = 1, radius = 0.058, meleeDamage = 7, preferredRange = 1.25 })
add("exploder", { label = "Exploder", color = 0xFF7043, hpCore = 44.0, speedCore = 0.29, rewardBase = 12, rewardPerWave = 1, radius = 0.048, meleeDamage = 10 })
add("screamer", { label = "Screamer", color = 0xFFCA28, hpCore = 48.0, speedCore = 0.18, rewardBase = 16, rewardPerWave = 1, radius = 0.052, meleeDamage = 7 })
add("bloater", { label = "Bloater", color = 0x6D4C41, hpCore = 190.0, speedCore = 0.10, rewardBase = 20, rewardPerWave = 1, radius = 0.085, meleeDamage = 14, meleeReach = 0.1 })
add("stalker", { label = "Stalker", color = 0x455A64, hpCore = 32.0, speedCore = 0.44, rewardBase = 15, rewardPerWave = 1, radius = 0.042, meleeDamage = 16, meleeReach = 0.07 })
add("jumper", { label = "Jumper", color = 0x26A69A, hpCore = 50.0, speedCore = 0.22, rewardBase = 13, rewardPerWave = 1, radius = 0.05, meleeDamage = 12, meleeReach = 0.08 })
add("wraith", { label = "Wraith", color = 0x90A4AE, hpCore = 40.0, speedCore = 0.33, rewardBase = 17, rewardPerWave = 1, radius = 0.046, meleeDamage = 11 })
add("hiveMother", { label = "Hive Mother", color = 0x8D6E63, hpCore = 120.0, speedCore = 0.12, rewardBase = 26, rewardPerWave = 1, radius = 0.08, meleeDamage = 10 })
add("acidBomber", { label = "Acid Bomber", color = 0xCDDC39, hpCore = 55.0, speedCore = 0.21, rewardBase = 15, rewardPerWave = 1, radius = 0.05, meleeDamage = 8, preferredRange = 1.1 })
add("shieldBearer", { label = "Shield Bearer", color = 0x78909C, hpCore = 110.0, speedCore = 0.14, rewardBase = 19, rewardPerWave = 1, radius = 0.07, meleeDamage = 9, meleeReach = 0.085, damageTakenFactor = 0.55 })
add("frostbite", { label = "Frostbite", color = 0x4FC3F7, hpCore = 65.0, speedCore = 0.17, rewardBase = 16, rewardPerWave = 1, radius = 0.052, meleeDamage = 10, preferredRange = 1.2 })
add("swarmling", { label = "Swarmling", color = 0xC5E1A5, hpCore = 22.0, speedCore = 0.48, rewardBase = 6, rewardPerWave = 1, radius = 0.032, meleeDamage = 5 })
add("globling", { label = "Globling", color = 0x76FF03, hpCore = 26.0, speedCore = 0.36, rewardBase = 7, rewardPerWave = 1, radius = 0.036, meleeDamage = 4 })
add("boneGolem", { label = "Bone Golem", color = 0xECEFF1, hpCore = 210.0, speedCore = 0.09, rewardBase = 28, rewardPerWave = 1, radius = 0.09, meleeDamage = 22, meleeReach = 0.11 })
add("hammerMauler", { label = "Hammer Mauler", color = 0xA1887F, hpCore = 150.0, speedCore = 0.14, rewardBase = 30, rewardPerWave = 1, radius = 0.082, meleeDamage = 12, meleeReach = 0.13 })
add("plagueDoctor", { label = "Plague Doc", color = 0x9CCC65, hpCore = 75.0, speedCore = 0.15, rewardBase = 20, rewardPerWave = 1, radius = 0.055, meleeDamage = 8, preferredRange = 1.3 })
add("pyrofiend", { label = "Pyrofiend", color = 0xFF6D00, hpCore = 68.0, speedCore = 0.19, rewardBase = 18, rewardPerWave = 1, radius = 0.052, meleeDamage = 12 })
add("riftWalker", { label = "Rift Walker", color = 0xB388FF, hpCore = 55.0, speedCore = 0.28, rewardBase = 21, rewardPerWave = 1, radius = 0.05, meleeDamage = 14 })
add("hasteMage", { label = "Haste Mage", color = 0x00E5FF, hpCore = 95.0, speedCore = 0.14, rewardBase = 28, rewardPerWave = 1, radius = 0.056, meleeDamage = 6, preferredRange = 1.55 })

-- Ranged specialists
add("knifeThrower", { label = "Knife Thrower", color = 0x90A4AE, hpCore = 62.0, speedCore = 0.17, rewardBase = 18, rewardPerWave = 1, radius = 0.048, meleeDamage = 8, preferredRange = 1.8 })
add("knifeFanatic", { label = "Knife Fanatic", color = 0xFF8A65, hpCore = 118.0, speedCore = 0.30, rewardBase = 24, rewardPerWave = 1, radius = 0.055, meleeDamage = 10, preferredRange = 1.05 })
add("sharpshooter", { label = "Sharpshooter", color = 0x5D4037, hpCore = 70.0, speedCore = 0.13, rewardBase = 20, rewardPerWave = 1, radius = 0.05, meleeDamage = 7, preferredRange = 1.9 })
add("scatterGunner", { label = "Scatter Gunner", color = 0x8D6E63, hpCore = 80.0, speedCore = 0.18, rewardBase = 17, rewardPerWave = 1, radius = 0.054, meleeDamage = 9, preferredRange = 0.85 })
add("emberCaster", { label = "Ember Caster", color = 0xFF5722, hpCore = 72.0, speedCore = 0.15, rewardBase = 19, rewardPerWave = 1, radius = 0.052, meleeDamage = 7, preferredRange = 1.25 })
add("iceLancer", { label = "Ice Lancer", color = 0x29B6F6, hpCore = 68.0, speedCore = 0.16, rewardBase = 18, rewardPerWave = 1, radius = 0.05, meleeDamage = 7, preferredRange = 1.3 })
add("hexWitch", { label = "Hex Witch", color = 0xAB47BC, hpCore = 78.0, speedCore = 0.14, rewardBase = 22, rewardPerWave = 1, radius = 0.054, meleeDamage = 6, preferredRange = 1.4 })
add("railSniper", { label = "Rail Sniper", color = 0x26C6DA, hpCore = 58.0, speedCore = 0.12, rewardBase = 21, rewardPerWave = 1, radius = 0.046, meleeDamage = 6, preferredRange = 2.1 })
add("harpooner", { label = "Harpooner", color = 0x78909C, hpCore = 88.0, speedCore = 0.15, rewardBase = 19, rewardPerWave = 1, radius = 0.056, meleeDamage = 9, preferredRange = 1.45 })
add("boltSlinger", { label = "Bolt Slinger", color = 0xA1887F, hpCore = 64.0, speedCore = 0.19, rewardBase = 15, rewardPerWave = 1, radius = 0.049, meleeDamage = 7, preferredRange = 1.2 })
add("toxinDart", { label = "Toxin Dart", color = 0x9CCC65, hpCore = 60.0, speedCore = 0.20, rewardBase = 16, rewardPerWave = 1, radius = 0.047, meleeDamage = 6, preferredRange = 1.15 })
add("zapper", { label = "Zapper", color = 0xFFEE58, hpCore = 74.0, speedCore = 0.16, rewardBase = 20, rewardPerWave = 1, radius = 0.051, meleeDamage = 8, preferredRange = 1.35 })
add("missileer", { label = "Missileer", color = 0xFF8F00, hpCore = 82.0, speedCore = 0.14, rewardBase = 23, rewardPerWave = 1, radius = 0.053, meleeDamage = 7, preferredRange = 1.75 })

-- Mini-bosses (every 5 waves, not multiples of 10)
add("siegeBehemoth", { label = "Siege Behemoth", color = 0xBF360C, hpCore = 520.0, speedCore = 0.11, rewardBase = 90, rewardPerWave = 4, radius = 0.12, meleeDamage = 28, meleeReach = 0.14, isMiniBoss = true, eliteSkills = { "dash", "groundPound" } })
add("broodQueen", { label = "Brood Queen", color = 0xAD1457, hpCore = 480.0, speedCore = 0.22, rewardBase = 85, rewardPerWave = 4, radius = 0.11, meleeDamage = 20, meleeReach = 0.12, isMiniBoss = true, eliteSkills = { "dash" } })
add("ironColossus", { label = "Iron Colossus", color = 0x546E7A, hpCore = 620.0, speedCore = 0.08, rewardBase = 100, rewardPerWave = 4, radius = 0.13, meleeDamage = 32, meleeReach = 0.15, damageTakenFactor = 0.65, isMiniBoss = true, eliteSkills = { "block", "groundPound" } })
-- Waves 11-12, then packs of 2+ from wave 15 every 5 waves (spawn scheduling, not this table).
add("laserOverseer", { label = "Laser Overseer", color = 0xFF00E5, hpCore = 540.0, speedCore = 0.12, rewardBase = 95, rewardPerWave = 4, radius = 0.115, meleeDamage = 22, meleeReach = 0.12, isMiniBoss = true, eliteSkills = { "block" } })
-- Mid-range cluster fireballs; rare self-nova that splits twice (ability logic, not this table).
add("blazeburst", { label = "Blazeburst", color = 0xFF6D00, hpCore = 510.0, speedCore = 0.13, rewardBase = 90, rewardPerWave = 4, radius = 0.11, meleeDamage = 18, meleeReach = 0.11, preferredRange = 1.55, isMiniBoss = true, eliteSkills = { "dash", "block" } })

-- Bosses (every 10 waves, plus special milestone cases below)
add("dreadlord", { label = "Dreadlord", color = 0x6A1B9A, hpCore = 980.0, speedCore = 0.16, rewardBase = 180, rewardPerWave = 6, radius = 0.12, meleeDamage = 30, meleeReach = 0.13, isBoss = true, eliteSkills = { "dash", "block", "groundPound" } })
add("citadelTower", { label = "Citadel Tower", color = 0xFF1744, hpCore = 1500.0, speedCore = 0.0, rewardBase = 120, rewardPerWave = 5, radius = 0.16, meleeDamage = 20, meleeReach = 0.18, preferredRange = 99, damageTakenFactor = 0.85, isBoss = true, isImmobile = true, eliteSkills = { "block" } })
add("apocalypseLord", { label = "Apocalypse Lord", color = 0xD50000, hpCore = 1750.0, speedCore = 0.18, rewardBase = 260, rewardPerWave = 8, radius = 0.14, meleeDamage = 36, meleeReach = 0.15, damageTakenFactor = 0.75, isBoss = true, eliteSkills = { "dash", "groundPound" } })
-- Wave 20+ (every 20): katana teleport assassin.
add("shadowRonin", { label = "Shadow Ronin", color = 0x1A237E, hpCore = 2100.0, speedCore = 0.62, rewardBase = 320, rewardPerWave = 10, radius = 0.07, meleeDamage = 34, meleeReach = 0.16, isBoss = true, eliteSkills = { "block", "groundPound" } })
-- Wave 21 and every 25: strongest apex threat.
add("voidSovereign", { label = "Void Sovereign", color = 0xEA80FC, hpCore = 3200.0, speedCore = 0.48, rewardBase = 480, rewardPerWave = 14, radius = 0.13, meleeDamage = 42, meleeReach = 0.18, damageTakenFactor = 0.7, isBoss = true, eliteSkills = { "dash", "block", "groundPound" } })

local function baseHp(id: ZombieId, wave: number): number
	local def = Zombies[id]
	local scale = (def.isBoss or def.isMiniBoss) and (1 + wave * 0.18) or (1 + wave * 0.13)
	return def.hpCore * scale
end

local function baseSpeed(id: ZombieId, wave: number): number
	local def = Zombies[id]
	if def.isImmobile then
		return 0
	end
	return def.speedCore + math.min(wave * 0.0035, 0.07)
end

local function reward(id: ZombieId, wave: number): number
	local def = Zombies[id]
	return def.rewardBase + def.rewardPerWave * wave
end

local function hitRadius(id: ZombieId): number
	local def = Zombies[id]
	local mult = (def.isBoss or def.isMiniBoss) and 2.2 or 2.6
	return def.radius * mult
end

return {
	Zombies = Zombies,
	baseHp = baseHp,
	baseSpeed = baseSpeed,
	reward = reward,
	hitRadius = hitRadius,
}
