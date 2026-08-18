--!strict
-- Ported from survival_engine.dart activateAbility(). MVP implements
-- Survivor's Adrenaline only; every other class's ability formula is
-- documented in the porting spec and just needs its branch added here (see
-- MIGRATION.md) -- the cooldown/power scaffolding below is already generic.
local ClassData = require(game:GetService("ReplicatedStorage").Modules.Data.ClassData)
local PlayerState = require(script.Parent.PlayerState)

local AbilityService = {}

local function abilityPowerMult(level: number): number
	return 1 + level * 0.14
end

local function abilityCooldownMult(level: number): number
	return math.max(0.55, 1 - level * 0.08)
end

local function applySurvivorAdrenaline(state: PlayerState.State)
	local power = abilityPowerMult(state.abilityLevel)
	local mastered = state.abilityLevel >= 5

	state.speedBuffTimer = 4.5 * power
	state.speedBuffMult = 1.55 + (power - 1) * 0.35

	local healAmount = (mastered and 48 or 18) * power
	state.health = math.min(state.maxHealth, state.health + healAmount)

	local character = state.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = PlayerState.effectiveWalkSpeed(state)
	end
end

function AbilityService.activate(player: Player): boolean
	local state = PlayerState.get(player)
	if not state or not state.abilityUnlocked or state.abilityCooldown > 0 then
		return false
	end
	if state.health <= 0 then
		return false
	end

	if state.classId == "survivor" then
		applySurvivorAdrenaline(state)
	else
		return false -- Not ported yet for this class.
	end

	local classDef = ClassData.Classes[state.classId]
	state.abilityCooldown = classDef.abilityCooldown * abilityCooldownMult(state.abilityLevel)
	return true
end

-- Called every server tick to count down buffs/cooldowns that Dart ticks in
-- SurvivalEngine.update() (§2 of the porting spec).
function AbilityService.update(dt: number)
	for _, state in PlayerState.all() do
		if state.abilityCooldown > 0 then
			state.abilityCooldown = math.max(0, state.abilityCooldown - dt)
		end
		if state.speedBuffTimer > 0 then
			state.speedBuffTimer = math.max(0, state.speedBuffTimer - dt)
			if state.speedBuffTimer == 0 then
				state.speedBuffMult = 1
				local character = state.player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = PlayerState.effectiveWalkSpeed(state)
				end
			end
		end
		if state.health > 0 and state.health < state.maxHealth then
			state.regenTimer += dt
			while state.regenTimer >= 2.0 and state.health < state.maxHealth do
				state.regenTimer -= 2.0
				state.health = math.min(state.maxHealth, state.health + 1)
			end
		else
			state.regenTimer = 0
		end
	end
end

return AbilityService
