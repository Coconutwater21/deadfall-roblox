--!strict
-- Ported from lib/game/survival_content.dart (PlayerClass + PlayerClassStats).
-- Numbers are kept 1:1 with the Dart source; only representation changed
-- (enum -> string key, dart:ui Color -> Color3).

export type ClassId =
	"survivor"
	| "scout"
	| "tank"
	| "assault"
	| "berserker"
	| "reaper"
	| "demolitions"
	| "ghost"
	| "juggernaut"
	| "ranger"
	| "commander"

export type ClassDef = {
	id: ClassId,
	label: string,
	blurb: string,
	description: string,
	maxHealth: number,
	moveSpeed: number, -- Dart's relative speed multiplier; see Balance.MOVE_SPEED_STUDS
	color: Color3,
	moneyCost: number,
	killCost: number,
	abilityName: string,
	abilityDescription: string,
	abilityMoneyCost: number,
	abilityKillCost: number,
	abilityCooldown: number, -- seconds
}

local ClassData: { [ClassId]: ClassDef } = {
	survivor = {
		id = "survivor",
		label = "Survivor",
		blurb = "Balanced starter",
		description = "Jack-of-all-trades. Steady HP and speed for learning the arena.",
		maxHealth = 100,
		moveSpeed = 0.95,
		color = Color3.fromRGB(0x80, 0xCB, 0xC4),
		moneyCost = 0,
		killCost = 0,
		abilityName = "Adrenaline",
		abilityDescription = "Brief speed surge and a small heal.",
		abilityMoneyCost = 2600,
		abilityKillCost = 40,
		abilityCooldown = 10,
	},
	scout = {
		id = "scout",
		label = "Scout",
		blurb = "Fast, fragile",
		description = "Highest mobility. Hit and run, but one mistake hurts a lot.",
		maxHealth = 70,
		moveSpeed = 1.35,
		color = Color3.fromRGB(0x81, 0xD4, 0xFA),
		moneyCost = 200,
		killCost = 4,
		abilityName = "Dash",
		abilityDescription = "Dash hard in your aim direction.",
		abilityMoneyCost = 3100,
		abilityKillCost = 45,
		abilityCooldown = 6,
	},
	tank = {
		id = "tank",
		label = "Vanguard",
		blurb = "Fast bruiser",
		description = "Expensive frontliner. Solid speed and a knockback-invuln bash.",
		maxHealth = 145,
		moveSpeed = 1.18,
		color = Color3.fromRGB(0xFF, 0xA7, 0x26),
		moneyCost = 680,
		killCost = 16,
		abilityName = "Shock Bash",
		abilityDescription = "Shove foes, gain invulnerability, then shove again.",
		abilityMoneyCost = 5800,
		abilityKillCost = 75,
		abilityCooldown = 12,
	},
	assault = {
		id = "assault",
		label = "Assault",
		blurb = "Frontline fighter",
		description = "Above-average HP and solid pace. Built for mid-range fights.",
		maxHealth = 120,
		moveSpeed = 1.05,
		color = Color3.fromRGB(0xEF, 0x9A, 0x9A),
		moneyCost = 320,
		killCost = 7,
		abilityName = "Overdrive",
		abilityDescription = "Massively boost fire rate for a short burst.",
		abilityMoneyCost = 3900,
		abilityKillCost = 55,
		abilityCooldown = 12,
	},
	berserker = {
		id = "berserker",
		label = "Berserker",
		blurb = "Glass cannon speed",
		description = "Near-scout speed with better HP than Scout. Aggressive skirmisher.",
		maxHealth = 85,
		moveSpeed = 1.28,
		color = Color3.fromRGB(0xCE, 0x93, 0xD8),
		moneyCost = 450,
		killCost = 10,
		abilityName = "Blood Rage",
		abilityDescription = "Huge damage and speed for a few seconds.",
		abilityMoneyCost = 4400,
		abilityKillCost = 60,
		abilityCooldown = 13,
	},
	reaper = {
		id = "reaper",
		label = "Reaper",
		blurb = "Soul harvest fighter",
		description = "Damage fills a Soul Bar that drains over time. Full bars heal a flat amount (scales with Reaper level, can overheal); ability summons a massive scythe.",
		maxHealth = 100,
		moveSpeed = 0.98,
		color = Color3.fromRGB(0xB3, 0x88, 0xFF),
		moneyCost = 700,
		killCost = 99,
		abilityName = "Soul Scythe",
		abilityDescription = "Melee scythe swings that cleave up close and fill the Soul Bar fast.",
		abilityMoneyCost = 3900,
		abilityKillCost = 520,
		abilityCooldown = 16,
	},
	demolitions = {
		id = "demolitions",
		label = "Demo",
		blurb = "Close-range power",
		description = "Sturdy and deliberate. Best when fighting up close to packs.",
		maxHealth = 130,
		moveSpeed = 0.88,
		color = Color3.fromRGB(0xFF, 0xAB, 0x91),
		moneyCost = 390,
		killCost = 8,
		abilityName = "Satchel",
		abilityDescription = "Detonate a satchel blast at your aim point.",
		abilityMoneyCost = 4200,
		abilityKillCost = 55,
		abilityCooldown = 11,
	},
	ghost = {
		id = "ghost",
		label = "Ghost",
		blurb = "Elusive speedster",
		description = "Fastest class. Trade armor for pure repositioning speed.",
		maxHealth = 60,
		moveSpeed = 1.48,
		color = Color3.fromRGB(0xB0, 0xBE, 0xC5),
		moneyCost = 480,
		killCost = 11,
		abilityName = "Phase Shift",
		abilityDescription = "Phase dash with brief invulnerability.",
		abilityMoneyCost = 4800,
		abilityKillCost = 65,
		abilityCooldown = 9,
	},
	juggernaut = {
		id = "juggernaut",
		label = "Juggernaut",
		blurb = "Walking fortress",
		description = "Massive HP, glacial movement. Anchor the center of the map.",
		maxHealth = 200,
		moveSpeed = 0.55,
		color = Color3.fromRGB(0xFF, 0xCC, 0x80),
		moneyCost = 560,
		killCost = 12,
		abilityName = "Shockwave",
		abilityDescription = "Shockwave that damages nearby zombies.",
		abilityMoneyCost = 5500,
		abilityKillCost = 70,
		abilityCooldown = 12,
	},
	ranger = {
		id = "ranger",
		label = "Ranger",
		blurb = "Mid-range hunter",
		description = "Balanced hunter stats. Comfortable kiting across open ground.",
		maxHealth = 110,
		moveSpeed = 1.12,
		color = Color3.fromRGB(0x80, 0xCB, 0xC4),
		moneyCost = 420,
		killCost = 9,
		abilityName = "Marked Shot",
		abilityDescription = "Fire a piercing marked shot for massive damage.",
		abilityMoneyCost = 4000,
		abilityKillCost = 55,
		abilityCooldown = 10,
	},
	commander = {
		id = "commander",
		label = "Commander",
		blurb = "Summons gunners",
		description = "Very expensive warlord. Summons armed helpers that gun down the horde.",
		maxHealth = 125,
		moveSpeed = 0.98,
		color = Color3.fromRGB(0xFF, 0xD5, 0x4F),
		moneyCost = 840,
		killCost = 20,
		abilityName = "Gunline",
		abilityDescription = "Summon gunner helpers with heavy rifles.",
		abilityMoneyCost = 3900,
		abilityKillCost = 50,
		abilityCooldown = 18,
	},
}

-- Left-to-right class-bar order, sorted by moneyCost (project rule: keep this
-- order when rendering the class bar UI).
local ClassOrder: { ClassId } = {}
for id in ClassData do
	table.insert(ClassOrder, id)
end
table.sort(ClassOrder, function(a, b)
	return ClassData[a].moneyCost < ClassData[b].moneyCost
end)

return {
	Classes = ClassData,
	ClassOrder = ClassOrder,
}
