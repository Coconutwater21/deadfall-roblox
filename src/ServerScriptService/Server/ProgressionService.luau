--!strict
-- Weapon/class unlock & equip economy, ported from survival_engine.dart's
-- unlockClass/unlockWeapon/selectClass/equip plus survival_upgrades.dart's
-- cost curves. Every class/weapon's stats already exist in the data
-- modules, so unlocking/selecting any of them works generically here even
-- though only Survivor's ability is implemented (AbilityService) -- picking
-- another class correctly changes HP/speed, it just won't have an ability
-- yet (see MIGRATION.md).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassData = require(ReplicatedStorage.Modules.Data.ClassData)
local WeaponData = require(ReplicatedStorage.Modules.Data.WeaponData)
local UpgradeCurves = require(ReplicatedStorage.Modules.Data.UpgradeCurves)
local Remotes = require(ReplicatedStorage.Modules.Net.Remotes)
local PlayerState = require(script.Parent.PlayerState)

local ProgressionService = {}

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, { text = text })
end

local function unlockWeapon(player: Player, weaponId: WeaponData.WeaponId)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local weapon = WeaponData.Weapons[weaponId]
	if not weapon then
		return
	end
	if state.unlockedWeapons[weaponId] then
		return
	end
	local cost = UpgradeCurves.weaponMoneyCost(weaponId, 0)
	if state.money < cost then
		notify(player, string.format("Need $%d to unlock %s", cost, weapon.label))
		return
	end
	state.money -= cost
	state.unlockedWeapons[weaponId] = true
	state.weaponLevels[weaponId] = 0
	notify(player, weapon.label .. " unlocked")
end

local function equipWeapon(player: Player, weaponId: WeaponData.WeaponId)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if not state.unlockedWeapons[weaponId] then
		return
	end
	state.weaponId = weaponId
	local weapon = WeaponData.Weapons[weaponId]
	local level = state.weaponLevels[weaponId] or 0
	state.ammoInMag = weapon.magazineSize + level
	state.reloadTimer = 0
	state.shotCooldown = 0
end

local function unlockClass(player: Player, classId: ClassData.ClassId)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local classDef = ClassData.Classes[classId]
	if not classDef then
		return
	end
	if state.unlockedClasses[classId] then
		return
	end
	local cost = UpgradeCurves.classMoneyCost(classId, 0)
	if state.money < cost then
		notify(player, string.format("Need $%d to unlock %s", cost, classDef.label))
		return
	end
	state.money -= cost
	state.unlockedClasses[classId] = true
	notify(player, classDef.label .. " unlocked")
end

local function selectClass(player: Player, classId: ClassData.ClassId)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if not state.unlockedClasses[classId] then
		return
	end
	local classDef = ClassData.Classes[classId]
	local wasFull = state.health >= state.maxHealth
	state.classId = classId
	state.classLevel = 0
	state.maxHealth = classDef.maxHealth
	state.health = wasFull and state.maxHealth or math.min(state.health, state.maxHealth)
	state.abilityLevel = 0
	state.abilityCooldown = 0

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = PlayerState.effectiveWalkSpeed(state)
	end
end

function ProgressionService.start()
	Remotes.RequestUnlockWeapon.OnServerEvent:Connect(function(player: Player, payload)
		if typeof(payload) == "table" and typeof(payload.weaponId) == "string" then
			unlockWeapon(player, payload.weaponId)
		end
	end)
	Remotes.RequestEquipWeapon.OnServerEvent:Connect(function(player: Player, payload)
		if typeof(payload) == "table" and typeof(payload.weaponId) == "string" then
			equipWeapon(player, payload.weaponId)
		end
	end)
	Remotes.RequestUnlockClass.OnServerEvent:Connect(function(player: Player, payload)
		if typeof(payload) == "table" and typeof(payload.classId) == "string" then
			unlockClass(player, payload.classId)
		end
	end)
	Remotes.RequestSelectClass.OnServerEvent:Connect(function(player: Player, payload)
		if typeof(payload) == "table" and typeof(payload.classId) == "string" then
			selectClass(player, payload.classId)
		end
	end)
end

return ProgressionService
