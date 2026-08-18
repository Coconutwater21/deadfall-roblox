# Migration Checklist — Flutter Deadfall → Roblox

Source of truth for design/numbers: the Flutter repo at
`/Users/Cody/Projects/deadfall` (GitHub: Coconutwater21/deadfall). This repo
is a from-scratch Roblox (Luau) implementation, not a compile of that code —
see `docs/ENGINE_PORTING_SPEC.md` and `docs/UI_PORTING_SPEC.md` for the full
system-by-system reference this checklist is built from.

## Architecture

- **Server-authoritative**: all combat, spawning, damage, currency, and
  unlocks are decided in `ServerScriptService/Server/*`. Clients only send
  intent (`RequestFire`, `RequestReload`, `RequestAbility`, `RequestEquip-
  Weapon`, `RequestUnlockWeapon`, `RequestUnlockClass`, `RequestSelectClass`)
  via `ReplicatedStorage/Modules/Net/Remotes.luau`.
- **Client**: input (`InputController.luau`), camera
  (`CameraController.luau`), presentation (`HUD/HUDMain.luau`). Movement
  itself rides Roblox's default WASD character controller.
- **Data modules** (`ReplicatedStorage/Modules/Data/*.luau`) mirror the Dart
  catalogs 1:1 in content, with formulas kept identical:
  - `ClassData.luau` ← `survival_content.dart` (`PlayerClass`)
  - `ZombieData.luau` ← `survival_content.dart` (`ZombieKind`)
  - `WeaponData.luau` ← `weapon_catalog.dart`
  - `UpgradeCurves.luau` ← `survival_upgrades.dart`
- **Replicated state**: instead of Dart's single `ChangeNotifier` object
  polled every frame, state lives as `NumberValue`/`StringValue`/`BoolValue`
  instances under each `Player` (`leaderstats`, `Combat`) and a shared
  `ReplicatedStorage.GameState` folder — Roblox replicates these
  automatically, and the client HUD polls them every frame, which is the
  direct equivalent of Dart's poll-and-rebuild pattern (see
  `docs/UI_PORTING_SPEC.md`'s "State management pattern" section).

## System map (Dart file/system → Roblox module)

| Dart system | Roblox module | Status |
|---|---|---|
| `PlayerClass` stats/costs | `Data/ClassData.luau` | ✅ full data, 1 of 11 abilities implemented |
| `ZombieKind` stats/costs | `Data/ZombieData.luau` | ✅ full data, 1 of 47 kinds spawned |
| `WeaponKind` profiles | `Data/WeaponData.luau` | ✅ full data, generic hitscan/pierce/blast works for all 45 |
| `SurvivalUpgrades` cost curves | `Data/UpgradeCurves.luau` | ✅ full formulas ported |
| Arena layout (props) | `WorldBuilder.luau` | ✅ ported |
| Arena layout (houses/chests/keys) | — | ❌ not started |
| Wrapping-torus arena edges | `Config.luau` (constants only) | ⚠️ constants exist, wrap teleport not implemented |
| Player movement + collision | Roblox default character controller + `WorldBuilder` obstacle parts | ✅ (collision is free from Roblox physics, not a manual port) |
| Weapon fire/hitscan/pierce/blast | `CombatService.luau` | ✅ core loop; ⚠️ no status effects, no mastery gimmicks |
| Status effects (burn/virus/slow) | — | ❌ not started (spec in `ENGINE_PORTING_SPEC.md` §4) |
| Weapon mastery on-hit effects | — | ❌ not started |
| Zombie AI (chase + melee) | `ZombieService.luau` | ✅ walker-only; ⚠️ no kiting, no ranged attacks, no wind-ups |
| Zombie AI (ranged/special per kind) | — | ❌ not started (spec §5) |
| Elite combat skills (dash/block/pound) | — | ❌ not started (spec §7) |
| Wave spawn pacing/count | `WaveService.luau` | ✅ ported |
| Mini-boss/boss wave injection | — | ❌ not started (spec §6) |
| Zombie-kind weighted roll table | — | ❌ not started, MVP always spawns walker |
| Class abilities | `AbilityService.luau` | ⚠️ Survivor/Adrenaline only, 1 of 11 |
| Reaper Soul Bar | — | ❌ not started (spec §8) |
| Commander Gunline + allies | — | ❌ not started (spec §8, §10) |
| Kill/wave-clear economy | `EconomyService.luau` | ✅ ported (co-op adapted, see below) |
| Supply crates | — | ❌ not started (spec §9) |
| Weapon drop rarity gating | — | ❌ not started (spec §9) |
| Houses/chests/keys | — | ❌ not started (spec §9) |
| Class/weapon unlock + equip economy | `ProgressionService.luau` | ✅ ported generically for all classes/weapons |
| Class/weapon/ability upgrade (leveling) | — | ⚠️ level fields exist in `PlayerState`, no upgrade remote/UI yet |
| Player death/respawn | `PlayerService.luau` | ✅ co-op adapted (see below) |
| Health regen / overheal decay | `AbilityService.update` | ✅ ported |
| Friendly fire pits | — | ❌ not started |
| Necromancer bad-ending | — | ❌ N/A until Necromancer exists |
| HUD (health/ammo/money/kills/wave/ability) | `HUD/HUDMain.luau` | ✅ ported, see `UI_PORTING_SPEC.md` for what's left |
| Class Bar / Weapon Bar UI | — | ❌ not started |
| Settings / Pause / Intro / Game-over overlays | — | ❌ not started |
| Audio (music + SFX cues) | — | ❌ not started, see Audio section below |

## Intentional multiplayer adaptations (deviations from Dart)

Dart is single-player; this port defaults to shared co-op survival per the
project brief. Two deliberate behavior changes, both called out inline in
the code comments where they live:

1. **Death**: Dart pauses/ends the run and shows a game-over screen. Here,
   `PlayerService.luau` respawns the player after a 3-second delay so the
   shared wave loop keeps running for everyone else. There's currently no
   "everyone is dead" match-over state.
2. **Wave-clear bonus money**: Dart pays it to "the" player (single-player).
   `EconomyService.awardWaveClearBonus` pays every player currently in the
   arena.

Revisit both if the intended mode ever needs a real match-over/scoring flow
(e.g. for a leaderboard or a "best wave reached" stat).

## Known simplifications in the current code (not deviations, just unported depth)

- Zombies are kinematic (`CanCollide = false`) and walk straight through
  obstacle props — only the player collides with props. Fine for walkers in
  open ground; will look wrong once the arena has houses to path around.
- Damage numbers use `math.max(1, math.round(amount))` on melee hits only;
  ranged/explosion damage isn't floor-clamped to 1 the way Dart clamps *all*
  non-fractional hits. Low-impact until damage-reduction masteries exist and
  can round tiny hits to 0.
- No fractional/accumulator damage mode — needed once status-effect DoTs are
  ported (see `ENGINE_PORTING_SPEC.md` §4's status-effect section) so
  sub-1-HP/frame ticks don't get lost to rounding.

## Audio

Not started. Dart's `game_audio.dart` uses `audioplayers` with a fixed asset
manifest (`assets/audio/music/*.mp3`, `assets/audio/sfx/*.mp3`, plus one SFX
per weapon file named after the `WeaponKind` enum value). For Roblox:
upload each cue as a Roblox audio asset (or use placeholder Roblox library
IDs first — don't block gameplay work on final audio licensing/import), then
build a thin `AudioCue`/`GameMusic` equivalent module keyed the same way
(`Data/WeaponData.luau`'s `id` strings already match the Dart weapon-name-to-
SFX-filename convention, so the lookup table is a near-direct port).

## Suggested next milestones, in priority order

1. **Wrap-around arena edges** for players and zombies (small, high-value —
   currently the arena just has walls-that-aren't-walls).
2. **Runner zombie + kiting behavior** — cheap addition since the data and
   AI hook points already exist (`ZombieData.prefersRange`/`preferredRange`).
3. **Class Bar + Weapon Bar UI** with unlock/equip/upgrade wired to the
   already-working `ProgressionService` remotes — this is the biggest gap
   between "technically playable" and "feels like the real unlock loop."
4. **Status effects** (burn/virus/slow) — unlocks a big chunk of the weapon
   roster's identity (Flamer, Ice Rifle, Toxin Sprayer families etc. already
   have `ignites`/`appliesSlow`/`appliesVirus` flags sitting unused in
   `WeaponData.luau`).
5. **Second class + ability** (Scout/Dash is the simplest — no soul bar, no
   multi-stage timers, just a collision-respecting teleport-slide).
6. **Mini-boss wave injection** (wave 5/10/15...) using the already-ported
   `ZombieData` boss/mini-boss entries — spawn logic in `WaveService.luau`
   needs the priority-ordered injection rules from
   `ENGINE_PORTING_SPEC.md` §6.
7. **Houses + chests + keys**, then supply crates — biggest single content
   gap, but self-contained (doesn't block other systems).

## Opening & playtesting

See `README.md`.
