--!strict
-- Ported from survival_engine.dart _registerKill / wave-clear bonus.
-- Co-op adaptation: Dart is single-player so all reward goes to "the"
-- player; here the killing blow's player gets the kill reward, and the
-- wave-clear bonus (20 + wave*4) is paid to every player alive in the arena
-- (documented in MIGRATION.md).
local ZombieData = require(game:GetService("ReplicatedStorage").Modules.Data.ZombieData)
local PlayerState = require(script.Parent.PlayerState)

local EconomyService = {}

function EconomyService.awardKill(player: Player, kind: ZombieData.ZombieId, wave: number)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local reward = ZombieData.reward(kind, wave)
	state.money += reward
	state.kills += 1
	state.totalMoneyEarned += reward
	state.totalKills += 1
end

function EconomyService.awardWaveClearBonus(wave: number)
	local bonus = 20 + wave * 4
	for _, state in PlayerState.all() do
		state.money += bonus
		state.totalMoneyEarned += bonus
	end
end

return EconomyService
