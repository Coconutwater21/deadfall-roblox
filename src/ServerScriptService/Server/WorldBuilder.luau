--!strict
-- Ported from lib/game/survival_world.dart (SurvivalWorldBuilder). Houses are
-- deferred past the MVP (see MIGRATION.md); this builds the ground plane, a
-- purely-visual wrap-boundary strip (the arena wraps like a torus, so the
-- edge must NOT collide), and a scatter of solid obstacle props.
--
-- Unlike the Dart version, which hand-rolls circle/rect collision, Roblox
-- parts get real physics collision for free -- props just need CanCollide
-- true and a CollectionService tag so hitscans can raycast against them for
-- cover occlusion (see CombatService).

local CollectionService = game:GetService("CollectionService")
local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local WorldBuilder = {}

export type PropKind = "rock" | "crateStack" | "rubble" | "pillar" | "barrel" | "lampPost" | "well" | "cart"

local PROP_WEIGHTED: { PropKind } = {
	"barrel", "barrel", "barrel",
	"lampPost", "lampPost",
	"crateStack", "crateStack",
	"cart", "well", "rock", "rubble", "pillar", "rubble",
}

local PROP_RADIUS_RANGE: { [PropKind]: { number } } = {
	rock = { 0.14, 0.22 },
	crateStack = { 0.12, 0.17 },
	rubble = { 0.11, 0.17 },
	pillar = { 0.10, 0.14 },
	barrel = { 0.09, 0.13 },
	lampPost = { 0.07, 0.10 },
	well = { 0.15, 0.19 },
	cart = { 0.13, 0.18 },
}

local PROP_HEIGHT_STUDS: { [PropKind]: number } = {
	rock = 3,
	crateStack = 5,
	rubble = 2,
	pillar = 10,
	barrel = 4,
	lampPost = 12,
	well = 4,
	cart = 4.5,
}

local PROP_COLOR: { [PropKind]: Color3 } = {
	rock = Color3.fromRGB(120, 116, 108),
	crateStack = Color3.fromRGB(150, 111, 66),
	rubble = Color3.fromRGB(100, 96, 90),
	pillar = Color3.fromRGB(160, 155, 145),
	barrel = Color3.fromRGB(110, 80, 40),
	lampPost = Color3.fromRGB(50, 50, 55),
	well = Color3.fromRGB(130, 128, 120),
	cart = Color3.fromRGB(90, 60, 35),
}

local PROP_COUNT = 48
local MIN_CENTER_CLEARANCE_UNITS = 1.35
local MIN_PROP_SPACING_UNITS = 0.4
local EDGE_PAD_UNITS = 1.1

local function makeFolder(): Folder
	local existing = workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = workspace
	return folder
end

local function buildFloor(parent: Instance)
	local size = Config.ARENA_HALF_UNITS * 2 * Config.STUD_SCALE
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(size, 1, size)
	floor.CFrame = CFrame.new(0, -0.5, 0)
	floor.Color = Color3.fromRGB(63, 74, 52)
	floor.Material = Enum.Material.Ground
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.Parent = parent
end

-- Purely visual: a thin ground-level stripe along the boundary so players
-- can see where they'll wrap to the opposite side. Flat (not a wall) and
-- non-collidable on purpose -- this used to be a 1.2-stud-tall wall, which
-- read as a solid obstacle right in the camera's face when a player walked
-- up to the edge. See Main.server.luau / ZombieService.luau for the actual
-- wrap-teleport logic this stripe is just marking.
local function buildWrapBoundary(parent: Instance)
	local half = Config.ARENA_HALF_STUDS
	local thickness = 1.0
	local sides = {
		{ Vector3.new(half * 2, 0.05, thickness), CFrame.new(0, 0.03, -half) },
		{ Vector3.new(half * 2, 0.05, thickness), CFrame.new(0, 0.03, half) },
		{ Vector3.new(thickness, 0.05, half * 2), CFrame.new(-half, 0.03, 0) },
		{ Vector3.new(thickness, 0.05, half * 2), CFrame.new(half, 0.03, 0) },
	}
	for i, side in sides do
		local part = Instance.new("Part")
		part.Name = "WrapBoundary" .. i
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Size = side[1]
		part.CFrame = side[2]
		part.Color = Color3.fromRGB(255, 210, 90)
		part.Material = Enum.Material.Neon
		part.Transparency = 0.5
		part.Parent = parent
	end
end

local function randomRange(rng: Random, lo: number, hi: number): number
	return lo + rng:NextNumber() * (hi - lo)
end

-- Rejection-sampled point inside the arena, at least minCenter from origin,
-- kept EDGE_PAD_UNITS away from the wrap boundary.
local function safePoint(rng: Random): Vector2
	local pad = Config.ARENA_HALF_UNITS - EDGE_PAD_UNITS
	for _ = 1, 40 do
		local x = (rng:NextNumber() * 2 - 1) * pad
		local z = (rng:NextNumber() * 2 - 1) * pad
		if Vector2.new(x, z).Magnitude >= MIN_CENTER_CLEARANCE_UNITS then
			return Vector2.new(x, z)
		end
	end
	return Vector2.new(pad * 0.6, pad * 0.4)
end

local function tooClose(p: Vector2, others: { Vector2 }): boolean
	for _, o in others do
		if (p - o).Magnitude < MIN_PROP_SPACING_UNITS then
			return true
		end
	end
	return false
end

local function buildProp(parent: Instance, kind: PropKind, worldPos: Vector2, radiusUnits: number)
	local heightStuds = PROP_HEIGHT_STUDS[kind]
	local radiusStuds = radiusUnits * Config.STUD_SCALE
	local part = Instance.new("Part")
	part.Name = "Prop_" .. kind
	part.Anchored = true
	part.CanCollide = true
	part.Shape = if kind == "lampPost" or kind == "pillar" then Enum.PartType.Cylinder else Enum.PartType.Block
	if part.Shape == Enum.PartType.Cylinder then
		part.Size = Vector3.new(heightStuds, radiusStuds * 2, radiusStuds * 2)
		part.CFrame = CFrame.new(worldPos.X * Config.STUD_SCALE, heightStuds / 2, worldPos.Y * Config.STUD_SCALE)
			* CFrame.Angles(0, 0, math.rad(90))
	else
		part.Size = Vector3.new(radiusStuds * 2, heightStuds, radiusStuds * 2)
		part.CFrame = CFrame.new(worldPos.X * Config.STUD_SCALE, heightStuds / 2, worldPos.Y * Config.STUD_SCALE)
	end
	part.Color = PROP_COLOR[kind]
	part.Material = Enum.Material.Slate
	part.Parent = parent
	CollectionService:AddTag(part, "Obstacle")
end

function WorldBuilder.build(seed: number?)
	local folder = makeFolder()
	buildFloor(folder)
	buildWrapBoundary(folder)

	local propsFolder = Instance.new("Folder")
	propsFolder.Name = "Props"
	propsFolder.Parent = folder

	local rng = Random.new(seed or os.time())
	local placed: { Vector2 } = {}
	local attempts = 0
	while #placed < PROP_COUNT and attempts < PROP_COUNT * 6 do
		attempts += 1
		local pos = safePoint(rng)
		if not tooClose(pos, placed) then
			local kind = PROP_WEIGHTED[rng:NextInteger(1, #PROP_WEIGHTED)]
			local range = PROP_RADIUS_RANGE[kind]
			local radius = randomRange(rng, range[1], range[2])
			buildProp(propsFolder, kind, pos, radius)
			table.insert(placed, pos)
		end
	end

	return folder
end

return WorldBuilder
