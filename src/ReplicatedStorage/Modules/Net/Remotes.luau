--!strict
-- Central definition of client<->server RemoteEvents. Server creates them on
-- boot (RunService:IsServer()); both sides require this module to get the
-- same Instances rather than duplicating name strings everywhere.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "Remotes"

local EVENT_NAMES = {
	"RequestFire", -- client -> server: {aimDirection: Vector3}
	"RequestFireStop", -- client -> server: stop holding fire
	"RequestReload", -- client -> server
	"RequestAbility", -- client -> server: {aimDirection: Vector3}
	"RequestEquipWeapon", -- client -> server: {weaponId: string}
	"RequestUnlockWeapon", -- client -> server: {weaponId: string}
	"RequestUnlockClass", -- client -> server: {classId: string}
	"RequestSelectClass", -- client -> server: {classId: string}
	"Notify", -- server -> client: {text: string}
	"DamageFloater", -- server -> client: {worldPosition: Vector3, amount: number, kind: string}
	"WaveBanner", -- server -> client: {wave: number}
}

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local Remotes = {}

if RunService:IsServer() then
	local folder = getOrCreateFolder()
	for _, name in EVENT_NAMES do
		if not folder:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
	end
else
	-- Client: wait for the server-created folder/events to replicate down.
	ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder

for _, name in EVENT_NAMES do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
