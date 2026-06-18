# DESIGN.md — Float

Game design specification for the roguelite blackjack game "Float".

## Pitch

A single-deck blackjack roguelite where you cross "the Reaches" — a passage nobody fully remembers. Twenty hands. Four watches. A wharf between each one where you spend chips on modifiers and hear from people who don't quite belong. Artefacts float back from the crossing — fragments of a mystery that accumulates but never resolves.

**DREDGE meets Balatro.** Short sessions (8-12 minutes). Dense decisions. Lore you assemble from pieces.

## Session Design

**Target: 8-12 minute sessions.**

20 hands in 4 watches of 5. Each hand has 3 decision points:
1. **Tide phase** (~3s): push-your-luck — raise payout for risk, or gain info
2. **Play phase** (~15s): blackjack decisions (hit/stand/double/split)
3. **Salvage phase** (~3s): take flotsam (safe) or seed the reef (risky chips)

Every 5 hands: **The Wharf** — shop with 3 modifier cards, loan option, character encounters, artefact journal.

## The Loop

```
Departure (narrative) → 5 hands → Wharf (shop + dialogue) → 5 hands → Wharf → 5 hands → Wharf → 5 hands → Game Over
```

Watch 1 (Calm) is the onboarding watch — standard blackjack, learn the loop.
Watch 2 (Tide) introduces payout variance — odd/even hand timing matters.
Watch 3 (Fog) strips information — hole card hidden, reef is dangerous.
Watch 4 (The Reaches) amplifies everything — modifier payouts and costs doubled.

## Win/Loss

- **Win**: Reach 750 chips by end of Watch 4. Title: "AFLOAT"
- **Foundered**: Drop below the watch threshold at any point. Title: "FOUNDERED"
- Balance target: 30-40% win rate for a player who buys and uses modifiers well. ~16% for basic strategy (no modifier optimization). Simulated via `love . --sim 2000`.

## Economy

- Start: 200 chips
- Min bet: 10 (30 on roughWater condition)
- Watch thresholds: [120, 260, 450, 750]
- Loan: +75 once per watch (no interest, just a tool)
- Shop: 3 random modifiers, prices 50-100 (doubled in Watch 4)
- Max 3 active modifiers per run

## Tide Phase (pre-deal push-your-luck)

| Choice   | Payout      | Cost                          |
|----------|-------------|-------------------------------|
| Rising   | +20%        | Dealer draws one extra card    |
| Falling  | -20%        | See dealer's hole card         |
| Flat     | Standard    | None                           |

## Salvage Phase (post-hand)

| Choice       | Effect                                              |
|--------------|-----------------------------------------------------|
| Take Flotsam | +1 Flotsam (meta currency), 35% chance of artefact |
| Seed Reef    | Voyage card in deck + 2 chips per remaining hand    |

## Voyage Cards (reef hazards)

| Card      | Effect                                                    |
|-----------|-----------------------------------------------------------|
| Deadweight| Counts as 13. No reduction.                               |
| Undertow  | Counts as 0. Draw one more card.                          |
| Squall    | Counts as 3. All aces become 1 — no soft totals.          |
| Fog Bank  | Hidden value (4-9). Revealed when hand resolves.           |

## Run Conditions (random per voyage)

| Condition       | Effect                                      |
|-----------------|---------------------------------------------|
| Calm Crossing   | Dealer stands on soft 17 (standard)        |
| Rough Water     | Minimum bet is 30                           |
| Fog             | Dealer hole card hidden until their turn    |
| Clear Skies      | Dealer hole card always face up            |
| Spring Tide     | Pushes pay in player's favour               |
| The Ledger is Open| Modifier costs -15                        |
| Short Passage   | 2 watches, win at 350                       |
| Known Waters    | See top deck card before each bet           |

## Modifiers (26 purchasable)

Three categories:
- **Outcome modifiers** — change payout math (Hot Streak, Dead Calm, All or Nothing)
- **Decision modifiers** — change available actions (Card Shark, Ballast, Standing Order)
- **Betting modifiers** — change bet dynamics (Compound Interest, The Ledger, Tide)

See `src/models/modifiers.lua` for full definitions. Prices range 50-100, doubled in Watch 4.

## Narrative System

### Characters (4)

- **Higgs** — Wharf harbourmaster. Runs the loop. Sits at the centre. Not sinister — situated. He belongs to this in a way the player doesn't. Yet.
- **Maren** — Engineer. Former crew of the Calloway Cross. Knows the math doesn't add up.
- **Cully** — Drifter. Systems thinker. Forty-one crossings, none successful. Each ends with "almost."
- **Sable** — Rigger. Former crew of the Maud. Knows knots that hold because the rope remembers.

### Artefacts (30 lore items)

Progression-gated. Found via flotsam during salvage (35% chance). Categories:
- **Early** (any run): 6 items — fabric, seed pod, glass bead, warm stone, etc.
- **Mid** (watch 3+): 4 items — ship's log fragment, tide chart, coat button, endorsement form
- **Deep** (watch 4+): 5 items — Mayor's Income file, harbour authority seal, driftwood map
- **Post-win**: 3 items — Reaches flower, passenger ticket, stamped endorsement
- **Chain unlocks**: 4 items — require specific prior artefacts
- **Deep lore** (run count): 4 items — Higgs's coat, wharf photograph, full log, your endorsement
- **Final layer**: 3 items — Reaches coordinates, final entry, what Higgs knows

### Narrative Design Principles

- Mystery accumulates. Truth is never fully stated.
- Characters react to what you've found (trigger-based dialogue).
- The wharf transforms by watch (ambient text changes).
- The final revelation: the Reaches are the wharf seen from the other side. The player has always been arriving. Higgs files the forms because someone has to.
- Lore is optional — you can play 100 runs and never read a single artefact.

## Meta-Progression

- **Flotsam**: earned per run, spent on meta tree (10 nodes)
- **Meta tree**: starting chips, extra modifier slot, loan amount, artefact find rate, etc.
- **Persistence**: single JSON file via `love.filesystem`
- Unlocks are permanent across runs

## Visual Design

- **Portrait mobile** (390×844, iPhone-sized)
- **Dark atmospheric** — deep oceanic felt, not flat black. Vertical gradient tinted by accent color.
- **Run accent**: dustyGreen / slateBlue / warmOchre — felt tint, buttons, card backs, borders
- **Cards**: white-faced, proper 2.5:3.5 ratio, rank in corners, large suit centered, drop shadow
- **Voyage cards**: dark, accent-bordered, icon-forward
- **Card backs**: patterned with accent color, inner border, center motif
- **Typography**: clear hierarchy — titles 28-36px, body 14-16px, labels 10-12px

## Platform Roadmap

### Done
- Desktop (LÖVE2D 11.5, tested headless on VPS)
- Headless testing pipeline (Xvfb + llvmpipe + ffmpeg screenshots)

### Next
- **Web**: love.js → Vercel static deploy (same pipeline as SAFEMODE)
- **Android**: love2d-android wrapper APK
- **iOS**: love-ios template (needs Mac + Xcode)

## What Makes This Game Good

1. **Dense decisions**: 3 per hand × 20 hands = 60 meaningful choices in 10 minutes
2. **Watch identity**: each watch plays differently, not just harder
3. **Modifier synergy**: 26 modifiers create emergent combinations
4. **Lore that respects the player**: no forced reading, no exposition dumps, just fragments that click if you care
5. **Short sessions**: lose and re-roll in under 12 minutes

## Roadmap

### Critical (done)
- [x] Watch identity system
- [x] Balance pass (simulated, tuned)
- [x] Card animations (slide-in, flip, fust flash)
- [x] Procedural audio (deal, chip, ambient drone)
- [x] DepartureScreen metatable fix

### Important (next)
- [ ] UI visual polish — the current screens look rough. Card renderer is done, screens.lua needs overhaul
- [ ] Tutorial (8-step onboarding for Watch 1)
- [ ] Expanded character arcs (6-8 → 15-20 lines per character)
- [ ] Alternate card back (Hokusai-wave style)
- [ ] Game over screen polish (flotsam breakdown, artefact summary)

### Deploy
- [ ] Web build (love.js + Vercel)
- [ ] Android build (love2d-android)
- [ ] iOS build (love-ios, needs Mac)

### Future
- [ ] Commit mechanic ("bear down" post-stand for extra chip)
- [ ] More artefacts (expand to 40-50)
- [ ] Character-specific final-run mode
- [ ] Daily challenge seed