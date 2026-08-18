# Engine Porting Spec (survival_engine.dart)

Authoritative reference for porting the rest of `survival_engine.dart`'s simulation
into Luau. Produced by a full read of the 6047-line source plus the 1992-line
test file. Numbers here are exact Dart values/formulas — treat this as the spec
to implement against, not a summary to re-derive from memory.

MVP (this repo, as of the initial scaffold) implements a small slice of this:
walker-only waves, hitscan pistol/revolver-style weapons (pierce + blast
supported generically), Survivor + Adrenaline, straight-line zombie chase +
instant melee. Everything else below is follow-up work — see `MIGRATION.md`
for the prioritized checklist.

---

## 1. Coordinate system & arena

- World space is a flat float `Offset(dx, dy)` in abstract "world units," not
  normalized 0–1 and not pixels. Arena is a square of half-extent
  `arenaHalf = 8.0`, so the full playfield is 16×16 world units, centered at
  origin `(0,0)`. This repo scales 1 world unit = 12 studs
  (`Config.STUD_SCALE`), giving a 192×192 stud arena.
- **Wrapping (Pac-Man style torus, not walls)**: `_wrap(Offset p)` clamps/loops
  x/y into `[-arenaHalf, arenaHalf]` — the map is a wrapping torus, confirmed
  by test `'map wraps when walking off an edge'`. All distance/direction math
  that needs to respect wrapping uses `_wrappedDelta(from, to)`, which picks
  the shortest signed delta across the wrap boundary. **Not yet ported**: the
  MVP arena has a purely visual boundary strip and no wrap teleport logic for
  players or zombies. Add wrap-around position correction in the main
  Heartbeat loop (check player/zombie position against
  `Config.ARENA_HALF_STUDS`, teleport to the opposite edge) plus a
  wrapped-delta helper for AI targeting distance math near the boundary.
- **Player collision radius**: `0.055` world units, hardcoded at every
  `_moveWithCollision` call site for the player. Zombie collision radius is
  `zombie.radius` (kind-specific) but hit-detection uses a separate larger
  `hitRadius = radius * (isBoss||isMiniBoss ? 2.2 : 2.6)`
  (`ZombieData.hitRadius` — already ported).
- **"Isometric" screen mapping**: the sim itself is plain 2D Cartesian; the
  isometric look was purely a rendering-time rotation applied to movement
  input, not to stored coordinates:
  ```
  screenRight = Offset(0.70710678, -0.70710678)
  screenDown  = Offset(0.70710678,  0.70710678)
  ```
  This rotation is **not needed** in a true-3D Roblox port — CameraController
  already gives an equivalent fixed-angle overhead view without it.
- No collision/pathing grid — the world is continuous float space; obstacle
  avoidance is circle-vs-circle and circle-vs-inflated-rect. Roblox gets this
  for free from real part physics (see `WorldBuilder.luau`), **except** the
  MVP's zombies are kinematic (`CanCollide = false`, manual CFrame movement)
  so they currently ignore obstacles entirely — matches Dart's "no
  pathfinding, straight line" but not its collision-slide-around-obstacles
  behavior for zombies. Follow-up: either give zombies real physics collision
  (Humanoid + Move) or port the axis-slide algorithm manually.

## 2. Game loop / tick structure

- **Delta-time based, clamped**: `update(dt)` clamps `dt` to max 0.05s per
  call (`Config.MAX_DT`, already applied in `Main.server.luau`'s Heartbeat).
- Per-frame order in Dart (for reference when adding systems — insert new
  systems at the equivalent point in `Main.server.luau`'s Heartbeat):
  1. Misc timers (cooldowns, buffs, damage flash, notifications).
  2. Tank's delayed second-push timer.
  3. Reload timer countdown.
  4. Crates/chests/keys pickup, player movement + collision, trail recording.
  5. Health regen, overheal decay.
  6. Wave update (spawn scheduling / wave-clear check).
  7. Zombie AI + movement + melee + status effects (the biggest system).
  8. Necromancer bad-ending check.
  9. Enemy projectiles, sky hazards, corpses, poison clouds, sticky goo, fire
     pits, laser cannons, gun allies.
  10. Player auto-fire if held.

## 3. Player movement & aim

- Movement: class `moveSpeed` × `classSpeedMult(level) = 1 + level*0.04` ×
  active speed-buff multiplier × any slow-puddle factor (min across overlaps,
  not stacked). Already ported for Survivor in `PlayerState.effectiveWalkSpeed`.
- Aim: either `setAim(worldPoint)` (mouse/touch cursor → normalized direction)
  or `aimAtNearest()` (auto-aim assist, e.g. for touch/controller). MVP only
  implements the mouse-ground-raycast path (`InputController.luau`).
- No explicit player-vs-zombie physical collision in Dart — zombies can
  overlap the player freely; melee damage is purely proximity+cooldown based
  (already how `ZombieService` works).

## 4. Combat / shooting

`fire()` is the single entry point, gated by `_shotCooldown <= 0`.

- **Reaper redirect**: if Soul Scythe is active, `fire()` redirects to melee
  swing instead of shooting. Not applicable until Reaper is ported.
- **Free-shot chance** (ammo not consumed): Assault class-mastery 45% roll,
  or Storm-mastery (SMG family) weapon-mastery 40% roll. Not yet ported (no
  mastery system exists yet — see §8/§9 in this doc and `UpgradeCurves.luau`
  which already has the level-scaling formulas ready).
- **Cooldown**: `shotCd = effectiveWeaponCooldown * (overdrive active ? 0.35 : 1)`,
  further ×0.45 if SMG-mastery "storm" frenzy is active post-kill.
  `effectiveWeaponCooldown = weapon.cooldown * weaponCooldownMult(level)`
  (already ported, no overdrive/storm yet).
- **Overheat mastery** (Minigun-family): heat +0.08/shot while firing, decays
  -0.55/sec idle; heat>0.2 multiplies damage up to 2.4× at heat=1.0, heat>0.55
  grants pierce. Not ported.
- **Pierce**: `weapon.pierces` (ported) OR Ranger class-mastery (not ported)
  OR Overheat-mastery-at-high-heat (not ported).
- **Explosion radius**: base `weapon.explosionRadius` (ported, full damage to
  every zombie in radius, no falloff). Demolitions-mastered doubles it,
  Launcher-mastery ×1.85, other masteries with blast ×1.35 — none ported.
  Launcher-mastery also seeds 3 delayed cluster bombs at `[0.2,0.4,0.65]`s.
- **Pellet count**: `weapon.pellets` (ported) + Shotgun-mastery +3 + Storm-
  mastery +2 during frenzy — not ported.
- **Hit detection is hitscan against a fake 3-point body column** (feet/
  torso/head) in Dart, for its 2D-sim-as-iso-render hack. The MVP instead
  does a single point-vs-segment test against each zombie's root position
  with a scaled-up `hitRadius` (`CombatService.collectHitsAlongRay`) — this is
  the correct 3D-native equivalent, no fake-height column needed.
- **Damage resolution** (`_applyWeaponHit`, ported minus mastery/status):
  1. Block check (Elite Block skill nullifies damage) — not ported (no elite
     skills yet).
  2. Damage multiplier stacking: Brand-mastery mark ×1.9, Shotgun-mastery
     point-blank up to ×3 at distance 0, Creed-mastery 38% chance ×2.6 crit —
     none ported.
  3. `dealt = effectiveWeaponDamage * damageMult * zombie.kind.damageTakenFactor`
     — the `damageTakenFactor` armor multiplier **is already ported**
     (`CombatService.applyHit`).
  4. Status effects (burn/virus/slow) — **not ported at all** yet. See exact
     durations/DPS/spread rules below.
  5. Reaper soul-charge — N/A until Reaper exists.
  6. Weapon-mastery on-hit gimmick — N/A until masteries exist.

### Status effects (not yet ported — full spec for when they are)

- **Burn** (`weapon.ignites` or Inferno mastery): `health -= burnDps*dt` while
  `burnTimer>0`. Duration/DPS: 3.5s @ dps from `28`-damage-normalized base,
  7.0s @ dps from `72`-normalized when mastered (i.e. roughly scale duration
  and DPS off the hit weapon's damage — check `survival_engine.dart` around
  the ignite branch for the exact normalization constant before porting).
- **Virus** (`weapon.appliesVirus`): `health -= dps*dt` (dps≥6 floor), 12s
  base / 18s mastered. **Spreads**: each infected zombie with
  `virusSpreadCooldown<=0` (resets to 0.3s) infects any non-infected zombie
  within `0.68` world units, inheriting `duration=max(5.5, carrier*0.85)`,
  `dps=max(18, carrier*0.9)` — decaying chain infection.
- **Slow** (`weapon.appliesSlow` or Beam mastery): factor 0.45 @ 2.4s base
  rarity, 0.35 @ 3.2s for legendary+, 0.2 @ 4.5s mastered. Multiple slow
  applications take the **strongest** (min factor), not additive stacking;
  reapplication refreshes/extends duration rather than stacking instances.
- Burn/virus don't stack additively either — new application takes
  `max(duration)` and `max(dps)` of old vs new.
- **Important**: status-effect DoT ticks bypass `damageTakenFactor` (armor) —
  only direct hit damage gets armor-reduced.

## 5. Zombie AI

MVP ported: straight-line chase, instant no-windup melee punch (cooldown
`brute-like ? 1.15 : 0.8`), nearest-player targeting. Everything below is
follow-up, ordered roughly by value:

- **Global auras** (not ported): Screamer aura (0.75 radius, +0.35 speed to
  nearby zombies), Haste Mage aura (2.95 radius, +2.0 speed, i.e. 3× total,
  including itself since the loop isn't self-filtered in Dart).
- **Gunner-ally targeting** (N/A until Commander exists): zombies bias toward
  the nearest `GunAlly` over the player with an 0.88 distance multiplier
  (i.e. prefer gunners at up to ~14% farther distance than the player).
- **Kiting** (`kind.prefersRange && playerDistance < preferredRange`): moves
  away from the player at `moveSpeed*0.35` (only if distance > 0.08 to avoid
  jitter). `ZombieData` already has `prefersRange`/`preferredRange` per kind
  — this is a small, high-value addition since ~20 of 47 kinds use it.
- **Wind-up telegraphs**: most special attacks have a wind-up timer
  (0.2s–1.65s depending on kind) during which the zombie faces its target and
  a telegraph radius/point is shown before the attack commits. Not ported —
  no ranged zombie attacks exist yet at all (every current zombie is a
  melee-only walker).
- **Ghost zombies**: 20% roll on spawn (non-boss/mini-boss only) to ignore
  collision entirely and move at `speed*2.4`, plus a 30% per-hit-check chance
  to phase through any bullet/blast. Not ported.
- Full per-kind ability windup/range/damage table, elite combat skills
  (dash/block/ground-pound), wave-injection rules for mini-bosses/bosses, and
  all named boss mechanics (Dreadlord/Citadel Tower/Apocalypse Lord/Shadow
  Ronin/Void Sovereign) are fully documented in the original agent research
  — re-run a targeted `survival_engine.dart` read for the specific kind before
  implementing it, since that detail wasn't duplicated here to keep this doc
  from ballooning back to source-file size. Search for the kind's name in
  `_tickZombieAbility` (~line 3130) and `_commitZombieAbility` (~line 3664).

## 6. Wave / spawn system

Ported: base spawn count `6 + wave*3` (+4 on `wave%5==0`), spawn pacing
`max(0.22, 0.75 - wave*0.02)` seconds between spawns, edge spawn points,
wave-clear condition (`remainingToSpawn==0 && zombies empty`), 5s
intermission, wave-clear bonus money.

**Not ported** — elite/boss injection (checked in this exact priority order
when a wave starts):
1. `wave % 20 == 0`: force-spawn Shadow Ronin, halve remaining (floor 4).
2. `wave % 10 == 0`: force-spawn Citadel Tower, halve remaining (floor 4).
   HP/power scales via `tier = wave // 10`,
   `powerScale = 1 + (tier-1)*0.42`.
3. Else `wave % 5 == 0`: one mini-boss, rotating
   siegeBehemoth/broodQueen/ironColossus (and blazeburst from wave 15,
   4-way rotation).
4. Laser Overseer: `wave==11 or wave==12` → 1; `wave>=15 and wave%5==0` → 2.
5. Void Sovereign: `wave==21 or wave%25==0`, halve remaining (floor 3).

These are independent `if`s (not mutually exclusive except citadel/miniboss),
so e.g. wave 20 gets both Shadow Ronin AND a tier-2 Citadel Tower.

**Zombie kind variety**: also not ported — MVP always spawns `"walker"`.
Dart uses a weighted bag that grows with wave number (see original spec for
the exact per-wave weight table). Adding `"runner"` from wave 2 onward is the
smallest useful first step.

## 7. Elite combat skills

`dash` / `block` / `groundPound`, assigned per-kind via `ZombieData.eliteSkills`
(data already ported, behavior is not). Rolled independently of the kind's
primary special each time its ability cooldown is up (48% chance normally,
lower for Citadel Tower/Void Sovereign). Dash = short teleport-lunge with a
swept-segment hit test. Block = damage immunity window + self-slow. Ground
Pound = windup then AoE around self. Full numbers in the original research;
re-derive from `_tryEliteCombatSkill`/`_commitEliteDash`/`_commitEliteBlock`/
`_commitEliteGroundPound` in `survival_engine.dart` (~lines 3542–3663) when
implementing.

## 8. Class abilities

Ported: Survivor/Adrenaline only (`AbilityService.luau`), including the
class-mastery-vs-ability-mastery distinction and the `abilityPowerMult`/
`abilityCooldownMult` scaffolding, which is already generic enough for every
other class.

**Not ported** (10 classes): Scout Dash, Tank Shock Bash (has a delayed
second-push combo baked into a timer, not just flavor), Assault Overdrive,
Berserker Blood Rage, Reaper Soul Scythe + Soul Bar (soulBarDamageNeeded=520,
drain 0.12/sec, heal formula `18 + classLevel*12 (+15 mastered)`, melee swing
mechanics), Demolitions Satchel, Ghost Phase Shift, Juggernaut Shockwave
(+independent periodic passive pulse every 3.2s at class mastery — not tied
to the ability button), Ranger Marked Shot, Commander Gunline (formation
allies with continuous re-facing toward the nearest enemy, see §10). Every
formula (damage, radius, duration, mastery variant) is in the original
research — each class is roughly a half-day of focused porting work once its
turn comes up.

## 9. Economy / loot

Ported: kill reward → money+kills (`EconomyService.awardKill`), wave-clear
bonus. **Not ported**: supply crates (spawn timer, loot-kind roll, rarity
roll with the exact mythic/ascendant late-wave gating —
`wave>=18 && roll<0.012` for ascendant, `wave>=14 && roll<0.03` for mythic),
weapon-drop rarity weighting (`weaponDropWeight` — epic/legendary/mythic/
ascendant are hard-zero weight before waves 4/7/14/18 respectively), houses +
treasure chests (mini-key vs boss-key, always exactly 2 of each, chest loot
bands, respawn timers), world key drops, duplicate-weapon-grant refund logic.

## 10. Special mechanics

- **Friendly fire pits**: player-caused fire (weapon ignite kills/explosions,
  SMG-mastery Inferno on-kill) is always `friendly: true` and skips ALL
  damage application (player AND gun allies) via an early `continue` in the
  fire-pit tick. Enemy-caused fire (Blazeburst, Hammer Mauler, Pyrofiend,
  meteors) is not friendly. Not ported (no fire pits exist yet).
- **Commander gunline continuous re-facing**: `_gunlineFormationOffsets(count)`
  recomputes EVERY frame based on the nearest zombie to the Commander, not
  just on cast — the whole gunner line pivots as a rigid formation, each
  ally lerping toward its new slot at `min(1.0, 18*dt)` per frame (very
  tight leash, ~90%/frame). N/A until Commander is ported.
- **Necromancer bad-ending trigger**: exact condition is "at least one
  necromancer present, zero non-minion zombies present, spawn queue
  exhausted" held continuously for 2.0 seconds (`_necroSoloTimer`, resets to
  0 instantly if the condition breaks — no debounce/grace). On trigger:
  pause, cutscene, and on player-dismiss the necromancer ascends
  (HP `8200+wave*180`, damageMult ×4.2) and the entire boss+mini-boss roster
  (10 kinds) spawns simultaneously in a ring around the arena center. N/A
  until Necromancer + all bosses exist.
- **Class bar sort order**: the "sort by money cost" rule referenced in the
  project brief was **not found anywhere in `survival_engine.dart`** — the
  engine only sorts weapons by rarity (`unlockedSorted`). If that UI
  behavior is real, its comparator lives in `survival_game_screen.dart`
  (not deep-dived for this doc) or was aspirational. `ClassData.luau`
  implements it anyway (`ClassOrder`, sorted by `moneyCost` ascending) since
  it's a reasonable, cheap-to-keep convention regardless.

## 11. Player death / house-chest / key usage

Ported (adapted for co-op, see `MIGRATION.md`): damage floor of 1 HP per
non-fractional hit, health regen (2s/+1HP), overheal decay (7/sec). **Not
ported**: shield/invuln-timer damage immunity (Tank ability, Ghost/Berserker
abilities — N/A until those classes exist), Tank mastery's half-damage +
retaliation-pulse passive, fractional DoT damage accumulation
(`allowFractional` mode — needed once status effects are ported, so DoT tick
damage under 1 HP/frame doesn't get lost to rounding), houses/chests/keys
(see §9), high-score/leaderboard recording.

**Multiplayer adaptation** (intentional deviation from Dart, see
`MIGRATION.md`): Dart's single-player `gameOver` freeze-and-restart flow is
replaced with a per-player respawn-after-3-seconds so the shared wave loop
keeps running for other players. There is currently no "everyone's dead"
match-over state — worth adding once there's more than one save-worthy
outcome to reach.

---

### Files referenced

- `lib/game/survival_engine.dart` (6047 lines)
- `test/survival_engine_test.dart` (1992 lines)
- `lib/game/survival_world.dart` (246 lines)
- `lib/game/survival_upgrades.dart` (174 lines)
- `lib/game/survival_content.dart` (lines 380–780: zombie stat formulas)
