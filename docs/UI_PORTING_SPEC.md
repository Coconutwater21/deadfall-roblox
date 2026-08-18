# UI/UX Porting Spec (survival_game_screen.dart)

Reference for porting the rest of Deadfall's HUD/menus. Produced from a full
read of the 7424-line screen source (Canvas-painting internals intentionally
skipped — gameplay feel over pixel-identical rendering, per the project
brief). MVP HUD (`HUD/HUDMain.luau`) implements a subset — see the bottom of
this doc for what's done vs. outstanding.

## Architectural headline

There is no multi-screen navigation stack in Dart. Everything — main menu,
class select, weapon arsenal, settings, pause, game over — is an overlay
stacked on top of the always-running game world, toggled by booleans. The
gameplay world renders underneath even during "menus." **Roblox equivalent**:
one persistent `ScreenGui` with a `Frame` per overlay, visibility toggled,
over the always-active 3D viewport — not separate places or GUI page-swaps.

## Screen/menu flow

1. Necromancer bad-ending cutscene (blocks gameplay) — N/A until Necromancer exists.
2. Intro / "How to Play" overlay — shown at launch, acts as the de facto main
   menu. Player is already spawned as Survivor underneath it.
3. Settings overlay (reachable only from Pause).
4. Pause overlay.
5. Game Over overlay — also contains the high-score list and name-entry flow inline.

**No separate class-select or weapon-shop screen** — Survivor is the fixed
starting class; all unlocks/switches/purchases happen live via the
always-present Class Bar and Weapon Bar during gameplay, spending
money/kills in real time while a wave is active.

## HUD elements during gameplay

Top row (left→right): health bar (HP/MaxHP + class label, color-graded
green/orange/red, cyan if overhealed) with the Reaper Soul Bar directly under
it when playing Reaper; a horizontally-scrollable pill row (ammo/reload,
current weapon+level, status pill, money, kills, keys, ability-cooldown pill,
wave/enemies-remaining or next-wave-timer pill, pause button). Elite/boss
health bars render separately below the main row for every living boss/
mini-boss, sorted bosses-first then lowest-HP%. No minimap exists anywhere in
the source.

**Class Bar**: horizontally-scrollable strip sorted left→right by unlock
price ascending (money cost, then kill cost, then label). Each tile: hotkey
digit, lock/unlock/selected icon, level+stats, description/ability/L5-mastery
blurb (compact layout truncates this), unlock/upgrade chips.

**Weapon Bar** ("arsenal grid"): unlocked weapons first (tap to equip), then
locked (grayed, lock icon). Each tile: symbol-based icon (`WeaponSymbol` →
Material icon in Dart; port as an `ImageLabel`/decal per symbol), +level
badge, upgrade pips, rarity-colored label + DPS + drop-odds, description/
mastery blurb. A 3-chip "equipped upgrade row" above the bar gives quick
GUN/CLASS/ABL upgrade actions for whatever's currently equipped.

**Mobile touch controls**: virtual joystick bottom-left, ability/reload/fire
hold-buttons stacked bottom-right. Not a priority for a Roblox port unless
targeting mobile — Roblox's own touch controls can likely substitute for the
movement joystick.

## Input handling

Two abstractions funnel into the same setter methods — maps cleanly to
Roblox `ContextActionService` (discrete actions) + `UserInputService`
(continuous aim): keyboard (remappable via a `GameAction` → key map, except
class hotkeys 1-9/0/- which are fixed) and mouse (hover = aim, left-click =
fire, right-click = ability). **No explicit interact key** — chests, crates,
and key pickups are fully proximity/automatic (distance check each tick,
auto-collect within a small radius). Worth deciding in the Roblox port
whether to keep this ambient model (what the MVP does — nothing implemented
yet since houses/chests aren't ported) or switch to `ProximityPrompt`.

MVP keybinds (documented choice, not copied from Dart's remappable scheme):
hold left-click to fire, R to reload, Q for ability. Right-click-for-ability
and remappable binds are a reasonable follow-up.

## Class/weapon selection & upgrade UI

Both bars are always visible during gameplay. Purchase/unlock and equip/
select are separate taps; a dedicated small upgrade chip per class/weapon/
ability calls the upgrade function, gated by affordability, capped at
`SurvivalUpgrades.maxLevel` (shows "MAX · <mastery name>" once maxed — the
mastery names/blurbs are already ported in `UpgradeCurves.luau`).

## In-world UI

Per-zombie floating health bars (world-space, above each zombie — **the MVP
already does this** via `BillboardGui` in `ZombieService.buildHealthBar`),
player world-space health bar (not ported), damage floaters (floating combat
text, colored per source, "BLOCK" variant — not ported), blast-flash VFX (not
ported), wave-start banner + generic notification toast (**both ported** in
`HUDMain.luau` via the `WaveBanner`/`Notify` remotes).

## Settings screen

HUD layout sliders (position/scale for every region), audio sliders (music/
SFX volume + mute), one gameplay toggle (auto-equip new weapons), and a full
remappable keybind list. Not ported — no settings UI exists yet in the MVP.

## State management pattern

`SurvivalEngine extends ChangeNotifier` owns all state as plain public
fields; a `Ticker` drives `update(dt)` every frame; `notifyListeners()`
triggers a full-tree rebuild reading fields directly — effectively a
poll-and-rebuild pattern, not fine-grained reactive bindings.

**This is exactly what the Roblox port already does**: server-authoritative
state lives in `PlayerState.luau` + a `GameState` folder, replicated to
clients as `NumberValue`/`StringValue`/`BoolValue` instances (automatic
Roblox replication), and `HUDMain.luau` re-reads all of them every
`RenderStepped` rather than subscribing to individual change events. No
architecture change needed as more stats/systems are added — just add more
value instances and read them in the same loop.

---

## MVP status vs. this spec

**Done**: persistent always-on HUD pattern, health bar, ammo/reload text,
money, kills, wave/enemies-remaining pill, ability-cooldown bar, wave-start
banner, notification toast, per-zombie world-space health bars, poll-every-
frame state reads from replicated value instances.

**Not done**: elite/boss HUD health bars (N/A, no bosses yet), Class Bar,
Weapon Bar, equipped-upgrade quick-chips, Reaper soul bar (N/A), settings
overlay, pause overlay, intro/main-menu overlay, game-over overlay +
leaderboard, mobile touch controls, damage floaters, blast-flash VFX,
remappable keybinds, proximity-based interact for houses/chests (N/A, no
houses/chests yet).
