--!strict
-- Ported from lib/game/weapon_catalog.dart (WeaponKind, WeaponProfile, WeaponSymbol, WeaponMastery).
-- Target raw DPS bands (all pellets hitting one target):
-- Common 95-125 - Uncommon 145-185 - Rare 210-270 - Epic 300-360 -
-- Legendary 420-520 - Mythic 580-720 - Ascendant 820-980
-- Pierce / blast weapons sit lower on raw DPS because of multi-target value.

export type WeaponRarity = "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic" | "ascendant"

export type WeaponSymbol =
	"sidearm" | "revolver" | "smg" | "machinePistol" | "rifle" | "shotgun" | "burst"
	| "marksman" | "crossbow" | "flamer" | "cryo" | "toxin" | "minigun" | "rail"
	| "plasma" | "launcher" | "beam" | "thunder" | "voidCore" | "star"

export type WeaponMastery =
	"ricochet" | "storm" | "creed" | "shotgun" | "rail" | "brand" | "inferno"
	| "launcher" | "overheat" | "beam" | "exotic"

export type WeaponId = string

export type WeaponDef = {
	id: WeaponId,
	label: string,
	rarity: WeaponRarity,
	damage: number,
	cooldown: number,
	magazineSize: number,
	reloadSeconds: number,
	pellets: number,
	spread: number,
	range: number,
	pierces: boolean,
	explosionRadius: number,
	ignites: boolean,
	appliesVirus: boolean,
	appliesSlow: boolean,
	description: string,
	symbol: WeaponSymbol,
}

local RarityOrder: { WeaponRarity } = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "ascendant" }

local RarityColor: { [WeaponRarity]: Color3 } = {
	common = Color3.fromRGB(0xB0, 0xBE, 0xC5),
	uncommon = Color3.fromRGB(0x66, 0xBB, 0x6A),
	rare = Color3.fromRGB(0x42, 0xA5, 0xF5),
	epic = Color3.fromRGB(0xAB, 0x47, 0xBC),
	legendary = Color3.fromRGB(0xFF, 0xB3, 0x00),
	mythic = Color3.fromRGB(0x00, 0xE5, 0xFF),
	ascendant = Color3.fromRGB(0xFF, 0x17, 0x44),
}

-- Symbol families: weapons sharing a symbol share a mastery track.
local SymbolMastery: { [WeaponSymbol]: WeaponMastery } = {
	sidearm = "ricochet",
	revolver = "ricochet",
	smg = "storm",
	machinePistol = "storm",
	burst = "storm",
	rifle = "creed",
	shotgun = "shotgun",
	marksman = "rail",
	rail = "rail",
	crossbow = "brand",
	toxin = "brand",
	flamer = "inferno",
	cryo = "beam",
	beam = "beam",
	minigun = "overheat",
	launcher = "launcher",
	thunder = "launcher",
	plasma = "exotic",
	voidCore = "exotic",
	star = "exotic",
}

local Weapons: { [WeaponId]: WeaponDef } = {}

local function add(id: string, def: {
	label: string,
	rarity: WeaponRarity,
	damage: number,
	cooldown: number,
	magazineSize: number,
	reloadSeconds: number,
	pellets: number?,
	spread: number,
	range: number,
	pierces: boolean?,
	explosionRadius: number?,
	ignites: boolean?,
	appliesVirus: boolean?,
	appliesSlow: boolean?,
	description: string,
	symbol: WeaponSymbol,
})
	Weapons[id] = {
		id = id,
		label = def.label,
		rarity = def.rarity,
		damage = def.damage,
		cooldown = def.cooldown,
		magazineSize = def.magazineSize,
		reloadSeconds = def.reloadSeconds,
		pellets = def.pellets or 1,
		spread = def.spread,
		range = def.range,
		pierces = def.pierces or false,
		explosionRadius = def.explosionRadius or 0,
		ignites = def.ignites or false,
		appliesVirus = def.appliesVirus or false,
		appliesSlow = def.appliesSlow or false,
		description = def.description,
		symbol = def.symbol,
	}
end

-- Common
add("pistol", { label = "Pistol", rarity = "common", damage = 32, cooldown = 0.30, magazineSize = 12, reloadSeconds = 1.1, spread = 0.03, range = 2.4, symbol = "sidearm", description = "Steady sidearm. Reliable starter damage." })
add("revolver", { label = "Revolver", rarity = "common", damage = 55, cooldown = 0.48, magazineSize = 6, reloadSeconds = 1.55, spread = 0.02, range = 2.6, symbol = "revolver", description = "Heavy single shots. Slow, punchy common sidearm." })
add("smg", { label = "SMG", rarity = "common", damage = 11, cooldown = 0.095, magazineSize = 32, reloadSeconds = 1.35, spread = 0.09, range = 2.1, symbol = "smg", description = "Rapid spray. Best up close where spread still connects." })
add("machinePistol", { label = "M.Pistol", rarity = "common", damage = 9, cooldown = 0.08, magazineSize = 24, reloadSeconds = 1.2, spread = 0.12, range = 1.9, symbol = "machinePistol", description = "Compact auto-pistol. Faster than SMG, shorter reach." })
add("carbine", { label = "Carbine", rarity = "common", damage = 28, cooldown = 0.26, magazineSize = 18, reloadSeconds = 1.35, spread = 0.035, range = 2.7, symbol = "rifle", description = "Light rifle. Clean mid-range common pick." })
add("nailgun", { label = "Nailgun", rarity = "common", damage = 8, cooldown = 0.07, magazineSize = 40, reloadSeconds = 1.5, spread = 0.1, range = 2.0, symbol = "smg", description = "Industrial nail hose. Weak nails, huge volume." })
add("pepperbox", { label = "Pepperbox", rarity = "common", damage = 14, cooldown = 0.40, magazineSize = 8, reloadSeconds = 1.7, pellets = 3, spread = 0.14, range = 1.8, symbol = "shotgun", description = "Three-barrel scatter. Short-range common burst." })
add("dualPistols", { label = "Duals", rarity = "common", damage = 17, cooldown = 0.15, magazineSize = 20, reloadSeconds = 1.4, spread = 0.06, range = 2.2, symbol = "sidearm", description = "Twin pistols. Faster cadence than a single sidearm." })

-- Uncommon
add("shotgun", { label = "Shotgun", rarity = "uncommon", damage = 16, cooldown = 0.65, magazineSize = 6, reloadSeconds = 1.9, pellets = 6, spread = 0.24, range = 1.6, symbol = "shotgun", description = "Pellet cone. Melts anything in your face." })
add("assaultRifle", { label = "Assault", rarity = "uncommon", damage = 22, cooldown = 0.14, magazineSize = 28, reloadSeconds = 1.65, spread = 0.04, range = 3.0, symbol = "rifle", description = "Accurate automatic. Solid mid-range all-rounder." })
add("burstCarbine", { label = "Burst", rarity = "uncommon", damage = 18, cooldown = 0.32, magazineSize = 24, reloadSeconds = 1.5, pellets = 3, spread = 0.06, range = 2.6, symbol = "burst", description = "Controlled 3-round bursts. Steady uncommon DPS." })
add("combatShotgun", { label = "C.Shotty", rarity = "uncommon", damage = 14, cooldown = 0.58, magazineSize = 8, reloadSeconds = 1.85, pellets = 7, spread = 0.28, range = 1.5, symbol = "shotgun", description = "Wider blast pattern. Meaner at point-blank." })
add("battleRifle", { label = "Battle Rifle", rarity = "uncommon", damage = 36, cooldown = 0.22, magazineSize = 16, reloadSeconds = 1.7, spread = 0.025, range = 3.3, symbol = "rifle", description = "Semi-auto thumper. Accurate uncommon mid-long pick." })
add("pdw", { label = "PDW", rarity = "uncommon", damage = 14, cooldown = 0.085, magazineSize = 30, reloadSeconds = 1.45, spread = 0.07, range = 2.3, symbol = "smg", description = "Personal defense weapon. Tight spray for its class." })
add("leverAction", { label = "Lever", rarity = "uncommon", damage = 48, cooldown = 0.30, magazineSize = 8, reloadSeconds = 1.8, spread = 0.02, range = 3.1, symbol = "revolver", description = "Classic lever rifle. Hard hits, steady cadence." })
add("autoShotgun", { label = "Auto Shotty", rarity = "uncommon", damage = 12, cooldown = 0.38, magazineSize = 10, reloadSeconds = 2.0, pellets = 5, spread = 0.26, range = 1.55, symbol = "shotgun", description = "Semi-auto scatter. Faster follow-ups than pump guns." })

-- Rare
add("sniper", { label = "Sniper", rarity = "rare", damage = 145, cooldown = 0.62, magazineSize = 5, reloadSeconds = 2.2, spread = 0.004, range = 5.4, symbol = "marksman", description = "Long-range precision. Huge damage per click." })
add("crossbow", { label = "Crossbow", rarity = "rare", damage = 112, cooldown = 0.48, magazineSize = 5, reloadSeconds = 1.9, spread = 0.01, range = 4.1, appliesSlow = true, symbol = "crossbow", description = "Power bolts. Strong hits that briefly snare targets." })
add("flamethrower", { label = "Flamer", rarity = "rare", damage = 26, cooldown = 0.16, magazineSize = 55, reloadSeconds = 2.5, pellets = 3, spread = 0.3, range = 1.25, ignites = true, symbol = "flamer", description = "Short-range fire stream. Melts crowds up close." })
add("iceRifle", { label = "Ice Rifle", rarity = "rare", damage = 32, cooldown = 0.13, magazineSize = 22, reloadSeconds = 1.75, spread = 0.03, range = 3.2, appliesSlow = true, symbol = "cryo", description = "Chilling mid-range rounds. Slows whatever they hit." })
add("marksmanRifle", { label = "Marksman", rarity = "rare", damage = 55, cooldown = 0.22, magazineSize = 12, reloadSeconds = 1.85, spread = 0.012, range = 4.5, symbol = "marksman", description = "Precision mid-long rifle. Clean rare damage." })
add("toxinSprayer", { label = "Toxin", rarity = "rare", damage = 12, cooldown = 0.20, magazineSize = 40, reloadSeconds = 2.1, pellets = 4, spread = 0.22, range = 1.7, symbol = "toxin", description = "Toxic mist cone. Short range, high volume." })
add("harpoonGun", { label = "Harpoon", rarity = "rare", damage = 98, cooldown = 0.42, magazineSize = 4, reloadSeconds = 2.0, spread = 0.015, range = 3.8, appliesSlow = true, symbol = "crossbow", description = "Heavy spears. Hard punches that drag enemies to a crawl." })
add("pulseRifle", { label = "Pulse", rarity = "rare", damage = 28, cooldown = 0.11, magazineSize = 26, reloadSeconds = 1.7, spread = 0.035, range = 3.4, symbol = "rifle", description = "Energy automatic. Reliable rare mid-range DPS." })

-- Epic
add("minigun", { label = "Minigun", rarity = "epic", damage = 16, cooldown = 0.05, magazineSize = 100, reloadSeconds = 3.1, spread = 0.11, range = 2.8, symbol = "minigun", description = "Bullet hose. Huge mag, wide spray, long reload." })
add("railgun", { label = "Railgun", rarity = "epic", damage = 185, cooldown = 0.70, magazineSize = 4, reloadSeconds = 2.6, spread = 0.0, range = 5.6, pierces = true, symbol = "rail", description = "Piercing rail shot. Tears through every zombie in line." })
add("plasmaCannon", { label = "Plasma", rarity = "epic", damage = 42, cooldown = 0.26, magazineSize = 10, reloadSeconds = 2.0, pellets = 2, spread = 0.05, range = 3.5, symbol = "plasma", description = "Twin plasma bolts. Chunky epic mid-range fire." })
add("grenadeLauncher", { label = "Grenades", rarity = "epic", damage = 95, cooldown = 0.48, magazineSize = 5, reloadSeconds = 2.3, spread = 0.05, range = 3.1, explosionRadius = 0.62, symbol = "launcher", description = "Lobbed explosives. Detonates on impact with splash." })
add("rocketPod", { label = "Rockets", rarity = "epic", damage = 110, cooldown = 0.55, magazineSize = 4, reloadSeconds = 2.5, spread = 0.04, range = 3.6, explosionRadius = 0.7, symbol = "launcher", description = "Micro-rockets. Wider blast than grenades, slower fire." })
add("gaussRifle", { label = "Gauss", rarity = "epic", damage = 160, cooldown = 0.55, magazineSize = 6, reloadSeconds = 2.2, spread = 0.008, range = 5.0, pierces = true, symbol = "rail", description = "Magnetic pierce rifle. Line damage with less kick than rail." })
add("shredder", { label = "Shredder", rarity = "epic", damage = 18, cooldown = 0.16, magazineSize = 36, reloadSeconds = 2.0, pellets = 3, spread = 0.1, range = 2.6, symbol = "burst", description = "Triple-slice rounds. Tears packs at mid range." })
add("arcCaster", { label = "Arc Caster", rarity = "epic", damage = 30, cooldown = 0.09, magazineSize = 35, reloadSeconds = 1.95, spread = 0.06, range = 3.2, symbol = "minigun", description = "Lightning spray. High epic cadence." })

-- Legendary
add("laserLance", { label = "Laser", rarity = "legendary", damage = 38, cooldown = 0.085, magazineSize = 40, reloadSeconds = 1.8, spread = 0.015, range = 4.4, symbol = "beam", description = "Beam spray. Fast legendary firepower." })
add("thunderCannon", { label = "Thunder", rarity = "legendary", damage = 48, cooldown = 0.42, magazineSize = 8, reloadSeconds = 2.4, pellets = 4, spread = 0.14, range = 3.2, symbol = "thunder", description = "Storm volley. Clears packs with wide legendary spread." })
add("solarBeam", { label = "Solar", rarity = "legendary", damage = 52, cooldown = 0.11, magazineSize = 28, reloadSeconds = 2.0, spread = 0.02, range = 4.6, symbol = "beam", description = "Concentrated sun lance. Hot legendary mid-long DPS." })
add("cryoCannon", { label = "Cryo", rarity = "legendary", damage = 40, cooldown = 0.18, magazineSize = 24, reloadSeconds = 2.1, pellets = 2, spread = 0.05, range = 3.6, appliesSlow = true, symbol = "cryo", description = "Twin frost bolts. Legendary chill that freezes movement." })
add("clusterLauncher", { label = "Cluster", rarity = "legendary", damage = 120, cooldown = 0.40, magazineSize = 5, reloadSeconds = 2.45, spread = 0.06, range = 3.4, explosionRadius = 0.78, symbol = "launcher", description = "Cluster bombs. Huge legendary splash on impact." })
add("phantomBow", { label = "Phantom Bow", rarity = "legendary", damage = 170, cooldown = 0.38, magazineSize = 7, reloadSeconds = 1.9, spread = 0.01, range = 4.8, appliesSlow = true, symbol = "marksman", description = "Spectral arrows. Hard precision shots that linger with frost." })
add("stormCaller", { label = "Storm", rarity = "legendary", damage = 35, cooldown = 0.24, magazineSize = 18, reloadSeconds = 2.15, pellets = 3, spread = 0.09, range = 3.5, symbol = "thunder", description = "Triple thunderbolts. Legendary pack shredder." })
add("rpg", { label = "RPG", rarity = "legendary", damage = 320, cooldown = 1.4, magazineSize = 1, reloadSeconds = 2.8, spread = 0.02, range = 4.2, explosionRadius = 1.15, ignites = true, symbol = "launcher", description = "One rocket. Massive blast radius, huge damage, leaves enemies burning." })

-- Mythic
add("voidCannon", { label = "Void", rarity = "mythic", damage = 95, cooldown = 0.30, magazineSize = 12, reloadSeconds = 2.1, pellets = 2, spread = 0.035, range = 4.8, symbol = "voidCore", description = "Mythic twin void beams. Elite deletion at range." })
add("starSplitter", { label = "Star Split", rarity = "mythic", damage = 48, cooldown = 0.22, magazineSize = 30, reloadSeconds = 2.0, pellets = 3, spread = 0.07, range = 4.0, symbol = "star", description = "Mythic starburst. Rapid triple-shot pressure." })
add("singularity", { label = "Singularity", rarity = "mythic", damage = 120, cooldown = 0.18, magazineSize = 14, reloadSeconds = 2.2, spread = 0.02, range = 4.5, symbol = "plasma", description = "Collapsed-star rounds. Dense mythic single shots." })
add("dragonBreath", { label = "Dragon", rarity = "mythic", damage = 28, cooldown = 0.17, magazineSize = 45, reloadSeconds = 2.4, pellets = 4, spread = 0.2, range = 2.0, symbol = "flamer", description = "Mythic fire cone. Short range, catastrophic volume." })
add("prismLance", { label = "Prism", rarity = "mythic", damage = 210, cooldown = 0.42, magazineSize = 6, reloadSeconds = 2.3, spread = 0.0, range = 5.8, pierces = true, symbol = "rail", description = "Refracted pierce beam. Mythic line wipe." })
add("oblivionCaster", { label = "Oblivion", rarity = "mythic", damage = 55, cooldown = 0.17, magazineSize = 22, reloadSeconds = 2.05, pellets = 2, spread = 0.04, range = 4.3, symbol = "plasma", description = "Twin oblivion bolts. Smooth mythic DPS." })
add("blowdart", { label = "Blowdart", rarity = "mythic", damage = 78, cooldown = 0.34, magazineSize = 14, reloadSeconds = 1.65, spread = 0.008, range = 5.0, appliesVirus = true, symbol = "toxin", description = "Toxic darts. Heavy poison DoT that slows and leaps between nearby zombies." })

-- Ascendant
add("apocalypseCannon", { label = "Apocalypse", rarity = "ascendant", damage = 110, cooldown = 0.24, magazineSize = 16, reloadSeconds = 2.3, pellets = 2, spread = 0.03, range = 5.0, symbol = "voidCore", description = "Ascendant twin doom beams. End-of-run firepower." })
add("eternityRail", { label = "Eternity", rarity = "ascendant", damage = 320, cooldown = 0.48, magazineSize = 5, reloadSeconds = 2.6, spread = 0.0, range = 6.2, pierces = true, symbol = "rail", description = "Ascendant pierce rail. Deletes entire lanes." })
add("novaStorm", { label = "Nova Storm", rarity = "ascendant", damage = 85, cooldown = 0.28, magazineSize = 10, reloadSeconds = 2.5, pellets = 2, spread = 0.08, range = 3.8, explosionRadius = 0.72, symbol = "launcher", description = "Ascendant nova shells. Twin blasts on every impact." })
add("worldEnder", { label = "World Ender", rarity = "ascendant", damage = 180, cooldown = 0.20, magazineSize = 12, reloadSeconds = 2.4, spread = 0.015, range = 5.2, symbol = "star", description = "Ascendant annihilation cannon. Pure boss melt." })
add("genesisBlaster", { label = "Genesis", rarity = "ascendant", damage = 85, cooldown = 0.18, magazineSize = 24, reloadSeconds = 2.2, pellets = 2, spread = 0.04, range = 4.7, symbol = "star", description = "Ascendant creation fire. Relentless twin beams." })

local function dps(id: WeaponId): number
	local def = Weapons[id]
	return (def.damage * def.pellets) / def.cooldown
end

local function mastery(id: WeaponId): WeaponMastery
	return SymbolMastery[Weapons[id].symbol]
end

local function rarityColor(rarity: WeaponRarity): Color3
	return RarityColor[rarity]
end

return {
	Weapons = Weapons,
	RarityOrder = RarityOrder,
	RarityColor = RarityColor,
	SymbolMastery = SymbolMastery,
	dps = dps,
	mastery = mastery,
	rarityColor = rarityColor,
}
