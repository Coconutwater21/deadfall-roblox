--!strict
-- Ported from lib/game/survival_upgrades.dart (SurvivalUpgrades).
local ClassDataModule = require(script.Parent.ClassData)
local WeaponDataModule = require(script.Parent.WeaponData)

type ClassId = ClassDataModule.ClassId
type WeaponId = WeaponDataModule.WeaponId
type WeaponMastery = WeaponDataModule.WeaponMastery

local MAX_LEVEL = 5

local function isMastered(level: number): boolean
	return level >= MAX_LEVEL
end

local function scale(base: number, currentLevel: number): number
	local level = math.clamp(currentLevel, 0, MAX_LEVEL)
	return math.round(base * (1.45 ^ level))
end

local function classMoneyCost(id: ClassId, currentLevel: number): number
	local classDef = ClassDataModule.Classes[id]
	local base = math.max(140, math.round(classDef.moneyCost * 0.95))
	return scale(base == 0 and 160 or base, currentLevel)
end

local function classKillCost(id: ClassId, currentLevel: number): number
	local classDef = ClassDataModule.Classes[id]
	local base = math.max(3, math.round(classDef.killCost * 0.22))
	return scale(base == 0 and 3 or base, currentLevel)
end

local function abilityMoneyCost(id: ClassId, currentLevel: number): number
	local classDef = ClassDataModule.Classes[id]
	return scale(math.round(classDef.abilityMoneyCost * 0.48), currentLevel)
end

local function abilityKillCost(id: ClassId, currentLevel: number): number
	local classDef = ClassDataModule.Classes[id]
	return scale(math.round(classDef.abilityKillCost * 0.12), currentLevel)
end

local WEAPON_MONEY_BASE: { [WeaponDataModule.WeaponRarity]: number } = {
	common = 150,
	uncommon = 230,
	rare = 360,
	epic = 560,
	legendary = 780,
	mythic = 1050,
	ascendant = 1450,
}

local WEAPON_KILL_BASE: { [WeaponDataModule.WeaponRarity]: number } = {
	common = 4,
	uncommon = 6,
	rare = 9,
	epic = 12,
	legendary = 16,
	mythic = 20,
	ascendant = 26,
}

local function weaponMoneyCost(id: WeaponId, currentLevel: number): number
	local weapon = WeaponDataModule.Weapons[id]
	return scale(WEAPON_MONEY_BASE[weapon.rarity], currentLevel)
end

local function weaponKillCost(id: WeaponId, currentLevel: number): number
	local weapon = WeaponDataModule.Weapons[id]
	return scale(WEAPON_KILL_BASE[weapon.rarity], currentLevel)
end

local function classHealthMult(level: number): number
	return 1 + level * 0.1
end

local function classSpeedMult(level: number): number
	return 1 + level * 0.04
end

local function abilityCooldownMult(level: number): number
	return math.max(0.55, 1 - level * 0.08)
end

local function abilityPowerMult(level: number): number
	return 1 + level * 0.14
end

local function weaponDamageMult(level: number): number
	return 1 + level * 0.12
end

local function weaponMagBonus(level: number): number
	return level -- +1 round per level
end

local function weaponReloadMult(level: number): number
	return math.max(0.6, 1 - level * 0.07)
end

local function weaponCooldownMult(level: number): number
	return math.max(0.7, 1 - level * 0.05)
end

-- Max-level class passive name + blurb.
local ClassMasteryName: { [ClassId]: string } = {
	survivor = "Phoenix Protocol",
	scout = "Phantom Stride",
	tank = "Adamant Aegis",
	assault = "Bottomless Mag",
	berserker = "Blood Sovereign",
	reaper = "Soul Tyrant",
	demolitions = "Cataclysm",
	ghost = "Living Shadow",
	juggernaut = "Earthquake Heart",
	ranger = "Deadeye Pierce",
	commander = "War Marshal",
}

local ClassMasteryBlurb: { [ClassId]: string } = {
	survivor = "Kills restore a huge chunk of HP (can overheal)",
	scout = "Kills grant a long speed surge + brief invulnerability",
	tank = "Take half damage and pulse back when hit",
	assault = "Most shots cost no ammo",
	berserker = "Below 60% HP deal double damage",
	reaper = "Souls fill faster; surges heal a bit more",
	demolitions = "Explosions become enormous",
	ghost = "Reloading phases you for a long window",
	juggernaut = "Frequent devastating quake pulses",
	ranger = "Always pierces and deals bonus damage",
	commander = "Gunline fires extremely fast",
}

-- Max-level ability bonus name + blurb (extra effect on cast).
local AbilityMasteryName: { [ClassId]: string } = {
	survivor = "Nova Rally",
	scout = "Guillotine Dash",
	tank = "Seismic Reprise",
	assault = "Full Auto Reset",
	berserker = "Crimson Ascension",
	reaper = "Harvest Apocalypse",
	demolitions = "Triple Payload",
	ghost = "Rift Guillotine",
	juggernaut = "Tectonic Aftershock",
	ranger = "Glacial Erasure",
	commander = "Death Squad",
}

local AbilityMasteryBlurb: { [ClassId]: string } = {
	survivor = "Huge heal + massive damage nova",
	scout = "Dash obliterates everything in the path",
	tank = "Both shoves deal heavy damage",
	assault = "Full reload + longer overdrive",
	berserker = "Huge heal and stronger rage",
	reaper = "Longer scythe + opening wipe cleave",
	demolitions = "Three overlapping satchel blasts",
	ghost = "Phase path deals lethal damage",
	juggernaut = "Delayed second quake nearly as strong",
	ranger = "Beam freezes and shreds every target",
	commander = "Five elite gunners with huge HP",
}

-- Max-level weapon special, keyed off the arsenal symbol / mastery family.
local WeaponMasteryName: { [WeaponMastery]: string } = {
	ricochet = "Ricochet Sovereign",
	storm = "Bullet Storm",
	creed = "Killshot Creed",
	shotgun = "Point-Blank Tyrant",
	rail = "Rail Judgment",
	brand = "Hunter's Brand",
	inferno = "Eternal Inferno",
	launcher = "Apocalypse Core",
	overheat = "Overheat Fury",
	beam = "Prism Cascade",
	exotic = "Reality Fracture",
}

local WeaponMasteryBlurb: { [WeaponMastery]: string } = {
	ricochet = "Shots ricochet to nearby foes and execute the wounded",
	storm = "Free bullets + kill-triggered fire-rate frenzy",
	creed = "Frequent critical hits and low-HP executions",
	shotgun = "Close range deals crushing bonus damage + knockback",
	rail = "Always pierces; hits detonate past the target",
	brand = "Marks prey for massive bonus damage",
	inferno = "Infernal burns and huge fire pits on kill",
	launcher = "Gigantic blasts with delayed cluster bombs",
	overheat = "Heat builds into piercing mega-damage",
	beam = "Chains across multiple enemies and chills them",
	exotic = "Random void pull, execute, or nova on hit",
}

local function classMasteryName(id: ClassId): string
	return ClassMasteryName[id]
end

local function classMasteryBlurb(id: ClassId): string
	return ClassMasteryBlurb[id]
end

local function abilityMasteryName(id: ClassId): string
	return AbilityMasteryName[id]
end

local function abilityMasteryBlurb(id: ClassId): string
	return AbilityMasteryBlurb[id]
end

local function weaponMasteryName(id: WeaponId): string
	return WeaponMasteryName[WeaponDataModule.mastery(id)]
end

local function weaponMasteryBlurb(id: WeaponId): string
	return WeaponMasteryBlurb[WeaponDataModule.mastery(id)]
end

return {
	MAX_LEVEL = MAX_LEVEL,
	isMastered = isMastered,
	classMoneyCost = classMoneyCost,
	classKillCost = classKillCost,
	abilityMoneyCost = abilityMoneyCost,
	abilityKillCost = abilityKillCost,
	weaponMoneyCost = weaponMoneyCost,
	weaponKillCost = weaponKillCost,
	classHealthMult = classHealthMult,
	classSpeedMult = classSpeedMult,
	abilityCooldownMult = abilityCooldownMult,
	abilityPowerMult = abilityPowerMult,
	weaponDamageMult = weaponDamageMult,
	weaponMagBonus = weaponMagBonus,
	weaponReloadMult = weaponReloadMult,
	weaponCooldownMult = weaponCooldownMult,
	classMasteryName = classMasteryName,
	classMasteryBlurb = classMasteryBlurb,
	abilityMasteryName = abilityMasteryName,
	abilityMasteryBlurb = abilityMasteryBlurb,
	weaponMasteryName = weaponMasteryName,
	weaponMasteryBlurb = weaponMasteryBlurb,
}
