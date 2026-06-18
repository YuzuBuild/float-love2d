# CLAUDE.md — Float (LÖVE2D)

Agent instructions for working on this codebase. Read this before making changes.

## What This Is

Float is a roguelite blackjack game with a DREDGE-like narrative layer. Ported from Swift/SpriteKit (iOS) to LÖVE2D. The player crosses "the Reaches" in a series of watches (acts), buying modifiers at the wharf between watches, collecting artefacts that reveal a fragmented mystery.

Target platforms: web (love.js), iOS, Android. Currently desktop-only.

## Quick Commands

```bash
# Run headless (no display needed)
XDG_RUNTIME_DIR=/tmp/runtime-root timeout 5 love .

# Run tests
lua5.3 test/test_engine.lua

# Run balance simulation (N=number of runs)
XDG_RUNTIME_DIR=/tmp/runtime-root love . --sim 1000

# Syntax check all Lua files
find . -name "*.lua" -exec luac -p {} \; 2>&1

# Run with Xvfb for screenshots (see godot-screenshot-on-vps skill)
Xvfb :99 -screen 0 390x844x24 -ac -noreset +extension GLX +extension EGL &
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe love .
# Screenshot: DISPLAY=:99 ffmpeg -f x11grab -video_size 390x844 -i :99 -vframes 1 -update 1 -y /tmp/shot.png
```

## Architecture

Three-layer separation: **Models** (data) → **Engine** (game logic) → **UI** (rendering). Never put game logic in UI code. Never put rendering in engine code.

### File Map

```
main.lua              — entry point, screen routing, run lifecycle
conf.lua              — LÖVE2D config (390×844, portrait mobile)
src/
  card_renderer.lua   — card drawing (faces, backs, voyage cards, felt, shadows)
  scene_manager.lua   — screen stack (switch/push/pop, input dispatch)
  animation.lua       — tween system (card slide-in, hole card flip, fust flash)
  dialogue.lua        — 4 characters, trigger-based dialogue, wharf ambient text
  audio.lua           — procedural sound (card deal, chip clink, ambient drone)
  engine/
    engine.lua        — GameEngine: full state machine, 26 modifiers, tide, salvage
  models/
    card.lua          — Card class, Deck (6-shoe), hand evaluation, ace logic
    modifiers.lua     — 26 modifier definitions (types, names, desc, costs, icons)
    voyage_card.lua   — 4 voyage card types (deadweight, undertow, squall, fogBank)
    run.lua           — Run state, 8 conditions, constants (thresholds, hands, watches)
    meta.lua          — Meta-progression (JSON persistence), artefact tracking
    artefacts.lua     — 30 lore items with progression-gated unlock conditions
  ui/
    screens.lua       — All game screens (departure, game, shop, journal, game over)
  lib/
    json.lua          — JSON encode/decode for persistence
test/
  test_engine.lua     — 13 engine tests
  sim_balance.lua     — Monte Carlo balance simulation (basic strategy AI)
```

### Engine State Machine

```
BETTING → TIDE → PLAYER_TURN → DEALER_TURN → HAND_RESULT → SALVAGE → SHOP → GAME_OVER
```

- **BETTING**: Set bet amount, press DEAL
- **TIDE**: Choose Rising (+20% payout, dealer extra card) / Falling (-20%, see hole) / Flat
- **PLAYER_TURN**: HIT / STAND / DOUBLE / SPLIT / PEEK / BALLAST
- **DEALER_TURN**: Auto-resolved
- **HAND_RESULT**: Shows outcome (AFLOAT/FUST/PUSH/UNDER), auto-advances after 1.8s
- **SALVAGE**: Take Flotsam (+1 meta) or Seed Reef (voyage card in deck + chips per remaining hand)
- **SHOP**: Every 5 hands (end of watch). Buy modifiers, float a loan, depart
- **GAME_OVER**: FOUNDERED or AFLOAT. Character reactions. New voyage.

### Watch Identity System

Each of the 4 watches has a mechanical identity:

| Watch | Name   | Rule                                              |
|-------|--------|---------------------------------------------------|
| 1     | Calm   | Standard blackjack                                |
| 2     | Tide   | Odd hands pay 1.5×, even hands pay 0.75×          |
| 3     | Fog    | Hole card always hidden, reef seeds 2 cards       |
| 4     | Reaches| All modifier payouts ×2, all modifier costs ×2   |

### Game Constants

- 20 hands per run (4 watches × 5 hands)
- Starting chips: 200
- Watch thresholds: [120, 260, 450, 750]
- Min bet: 10 (30 on roughWater)
- Loan: +75 chips (once per watch)
- Max modifiers: 3 per run
- 26 purchasable modifiers + 1 event-only (passenger)
- Artefact find rate: 35% during salvage

## UI System

### Accent Colors

Each run gets a random accent: `dustyGreen`, `slateBlue`, or `warmOchre`. This determines the felt tint, button color, card back pattern, and border accents throughout the run.

### Keyboard Shortcuts

- `Return` / `Space` — Deal / New voyage / Next hand
- `1` `2` `3` — Tide choices (Rising/Falling/Flat) or Salvage reef cards
- `h` — Hit, `s` — Stand, `d` — Double, `p` — Split
- `f` — Take flotsam (salvage)
- `j` — Toggle journal (in shop)
- `m` — Mute audio
- `Escape` — Close journal

### Mouse/Touch

All buttons are drawn as rectangles with hit detection via `inRect(mx, my, x, y, w, h)`. The same coordinates are used for draw and hit-test.

## What NOT to Change

- `engine.lua` — game logic only changes with explicit design intent
- `card.lua` — card model and hand evaluation are stable
- `test/test_engine.lua` — tests must stay passing (13/13)
- Keyboard shortcut mappings — muscle memory matters

## Current State

See DESIGN.md for game design spec and roadmap.

## Dependencies

- LÖVE2D 11.5 (installed on VPS)
- No external Lua packages (JSON parser is vendored in src/lib/)
- Meta-progression saved to `float_meta.json` via `love.filesystem`