# Deadfall (Roblox)

A from-scratch Roblox/Luau port of **Deadfall**, a top-down zombie survival
game. The original is a Flutter/Dart cross-platform game
(`Coconutwater21/deadfall`); this repo is a new implementation for Roblox
built to the same design — it does not compile or embed any Dart code.

See [`MIGRATION.md`](MIGRATION.md) for the full system-by-system porting
checklist, and `docs/` for detailed engine/UI porting specs pulled from the
Dart source.

## Status: early vertical slice

Playable right now: move (WASD), aim (mouse), shoot (hold left-click),
reload (R), Survivor's Adrenaline ability (Q), walker zombies spawning in
waves 1+, money/kills, a weapon unlock path (buy any weapon in
`ReplicatedStorage/Modules/Data/WeaponData.luau` with in-run money), and a
basic HUD. Everything else in the Dart game — other classes/abilities, more
zombie kinds, bosses, houses/chests, status effects, audio — is scaffolded
in the data layer but not yet wired into gameplay. See `MIGRATION.md` for
what's next.

This is designed as shared co-op survival by default (see `MIGRATION.md`'s
"Intentional multiplayer adaptations" section for the two behavior changes
that implies vs. the single-player Dart original).

## Requirements

- [Roblox Studio](https://www.roblox.com/create) (macOS or Windows).
- [Rojo](https://rojo.space/) — already vendored via `aftman.toml`; if you
  don't have [Aftman](https://github.com/LPGhatguy/aftman) installed, either
  install it and run `aftman install` in this directory, or just
  `brew install rojo` (macOS) / see the Rojo docs for other platforms. This
  repo was built against Rojo 7.7.0.
- The **Rojo Studio plugin** (install once from the Roblox Studio plugin
  marketplace, or run `rojo plugin install`).

## Opening in Studio

1. Install the Rojo Studio plugin if you haven't already:
   ```bash
   rojo plugin install
   ```
2. From this directory, start the Rojo server:
   ```bash
   rojo serve
   ```
3. Open Roblox Studio, create (or open) a place, then in the Rojo plugin
   panel click **Connect** (default `localhost:34872`). Studio's Explorer
   will populate with `ReplicatedStorage/Modules`, `ServerScriptService/
   Server`, `StarterPlayer/StarterPlayerScripts/Client`, etc.
4. Press **Play** (or **Play Here**) in Studio to test solo, or **Play Team
   Test** (with 2+ clients) to test co-op wave sharing.

You can also build a standalone `.rbxlx` file without opening Studio's live
sync, useful for CI or a quick sanity check that the project tree is valid:

```bash
rojo build -o build.rbxlx
```

## What you should see on Play

- You spawn as Survivor with a Pistol, standing near the arena's edge.
- Zombies (walkers) start spawning from the arena boundary a few seconds in;
  a "WAVE 1" banner announces the start.
- Hold left mouse button aimed at a zombie to shoot; health bars appear over
  zombies as they take damage.
- Killing zombies grants money (top-left) and kill count; a wave clears once
  all spawned zombies for it are dead, then a 5-second intermission starts
  the next wave.
- Press Q to trigger Adrenaline (speed buff + heal); the cooldown bar under
  your health bar shows readiness.
- To try the unlock path: any weapon can be unlocked by firing
  `ReplicatedStorage.Modules.Net.Remotes.RequestUnlockWeapon:FireServer({weaponId = "revolver"})`
  from the client (e.g. via the Studio command bar while Play-testing, or
  wire a temporary UI button) once you have enough money — there's no
  Weapon Bar UI yet to do this by clicking (see `MIGRATION.md`).

## Project layout

```
default.project.json          Rojo project manifest
aftman.toml                   Pinned Rojo version
src/
  ReplicatedStorage/Modules/
    Config.luau                Shared tuning constants (stud scale, arena size, timing)
    Data/                      Class/Zombie/Weapon/Upgrade catalogs ported from Dart
    Net/Remotes.luau           RemoteEvent definitions, created by the server on boot
  ServerScriptService/Server/  All server-authoritative simulation (see MIGRATION.md)
  StarterPlayer/StarterPlayerScripts/Client/
    Main.client.luau           Client bootstrap
    CameraController.luau      Fixed-angle overhead camera + mouse ground-raycast
    InputController.luau       Fire/reload/ability input → RemoteEvents
    HUD/HUDMain.luau           Health/ammo/money/kills/wave/ability HUD
docs/
  ENGINE_PORTING_SPEC.md       Detailed simulation porting reference (from survival_engine.dart)
  UI_PORTING_SPEC.md           Detailed HUD/menu porting reference (from survival_game_screen.dart)
MIGRATION.md                   System-by-system checklist + intentional deviations
```

## Development notes

- Every gameplay number (damage, HP, cooldowns, costs) is kept identical to
  the Dart source; only distances are scaled into studs
  (`Config.STUD_SCALE = 12`, i.e. 1 Dart "world unit" = 12 studs). See
  `Config.luau` for the conversion.
- Data modules (`Data/*.luau`) are pure content — no gameplay logic — so
  adding a new weapon/class/zombie kind to the roster is a data-only change;
  wiring it into spawning/abilities is separate (tracked in `MIGRATION.md`).
- No Luau type-checker with Roblox's global type definitions was available
  in the environment this was built in; every file was verified to at least
  **parse and begin executing** correctly (`luau <file>` reaches a
  Roblox-API runtime call, not a syntax error) and the full Rojo tree
  builds cleanly (`rojo build`). It has **not** been playtested inside
  Roblox Studio yet — do that first before trusting the "what you should
  see" section above as gospel, and file/fix anything that doesn't match.
