--!strict
-- Shared tuning constants for translating Dart survival_engine.dart's abstract
-- "world unit" simulation space into Roblox studs, plus a few global rules.
--
-- Dart sim: flat float Offset(x,y), arena half-extent 8.0 world units (16x16
-- total), player collision radius 0.055, wraps like a torus at the edges.
-- We keep every gameplay NUMBER (damage, hp, cooldowns, speeds-in-world-units)
-- identical to the Dart source and only scale distances by STUD_SCALE when
-- they need to become Roblox studs (positions, radii, ranges).

local Config = {}

-- 1 Dart world unit = 12 Roblox studs. Arena becomes a 192x192 stud square.
Config.STUD_SCALE = 12

Config.ARENA_HALF_UNITS = 8.0
Config.ARENA_HALF_STUDS = Config.ARENA_HALF_UNITS * Config.STUD_SCALE

-- Dart clamps update() dt to a max of 0.05s per frame; mirror that so a
-- hitched server frame doesn't let anything tunnel or over-simulate.
Config.MAX_DT = 0.05

-- Player collision radius from the Dart sim (kept only for hit-scan math;
-- actual Roblox character collision uses the default humanoid capsule).
Config.PLAYER_RADIUS_UNITS = 0.055

Config.HEALTH_REGEN_INTERVAL = 2.0 -- seconds per +1 HP, from _regenTimer
Config.OVERHEAL_DECAY_PER_SECOND = 7

Config.WAVE_INTERMISSION_SECONDS = 5
Config.WAVE_BANNER_SECONDS = 2.4

Config.MAX_UPGRADE_LEVEL = 5

function Config.unitsToStuds(units: number): number
	return units * Config.STUD_SCALE
end

function Config.studsToUnits(studs: number): number
	return studs / Config.STUD_SCALE
end

-- Ported from _wrap(Offset p) in survival_engine.dart -- the arena is a
-- wrapping torus, not walled. Wraps a single X or Z coordinate into
-- [-ARENA_HALF_STUDS, ARENA_HALF_STUDS].
function Config.wrapCoord(v: number): number
	local half = Config.ARENA_HALF_STUDS
	local span = half * 2
	if v > half then
		return v - span * math.ceil((v - half) / span)
	elseif v < -half then
		return v + span * math.ceil((-half - v) / span)
	end
	return v
end

function Config.wrapPosition(pos: Vector3): Vector3
	return Vector3.new(Config.wrapCoord(pos.X), pos.Y, Config.wrapCoord(pos.Z))
end

-- Ported from _wrappedDelta(from, to) -- shortest signed delta between two
-- points across the wrap boundary, so AI chasing near one edge correctly
-- takes the short way around instead of the long way across the arena.
function Config.wrappedDelta(from: Vector3, to: Vector3): Vector3
	local span = Config.ARENA_HALF_STUDS * 2
	local function axis(f: number, t: number): number
		local raw = t - f
		if raw > Config.ARENA_HALF_STUDS then
			raw -= span
		elseif raw < -Config.ARENA_HALF_STUDS then
			raw += span
		end
		return raw
	end
	return Vector3.new(axis(from.X, to.X), 0, axis(from.Z, to.Z))
end

return Config
