# Don't Drop It — Claude Code Instructions

## Source of Truth

Before doing any gameplay, architecture, balance, UI, world-integration, or production work, read:

`GAME_DESIGN.md`

`GAME_DESIGN.md` is the product source of truth.

Do not silently contradict, reinterpret, simplify away, or add systems that conflict with it.

If an instruction from Leonardo conflicts with `GAME_DESIGN.md`, Leonardo's newest explicit instruction wins.

If something is genuinely unclear, identify the ambiguity rather than inventing a major design decision.

---

# Team

## Leonardo — Lead Developer / Game Director

Leonardo has final authority over:

* game architecture
* core gameplay systems
* economy
* progression
* balance
* networking/remotes
* security
* ownership transfers
* persistence
* purchases
* analytics
* Git merges
* releases
* rollback decisions
* final product decisions

Claude is the primary implementation engine, but Leonardo owns the architecture and final decisions.

## Jadon — 3D Art Director / World Builder

Jadon owns:

* world building
* ring presentation
* zoo plots
* environment
* lighting
* asset style consistency
* animal visual direction
* Blender cleanup
* model scale
* model pivots
* collisions
* spawn placement
* visual polish
* mobile visual QA
* gameplay capture

Do not modify Jadon-owned world geometry unless Leonardo explicitly requests it.

Do not treat Jadon as an assistant. His visual work is a separate production lane.

---

# Current Production Goal

We are currently proving the MVP.

The question is:

Do players greed for one more animal and one ring deeper, and does losing the carried stack feel funny/exciting rather than unfair or frustrating?

The core loop is:

RUN OUT
→ GRAB
→ STACK
→ GET HEAVIER
→ GET SLOWER
→ GET GREEDIER
→ ESCAPE
→ BANK
→ INCOME INCREASES
→ RUN OUT AGAIN

Do not optimize for feature count.

Optimize for whether this loop is fun.

---

# MVP Scope

The MVP consists of:

1. Config
2. AnimalConfig
3. RingConfig
4. AnimalSpawner
5. Pickup
6. CarryState
7. StackRender
8. Bank
9. Income
10. RingZones
11. Heat
12. Ranger
13. Bump
14. Spill
15. basic gameplay HUD
16. analytics/debug instrumentation required for playtesting

Build incrementally.

Do not jump ahead because a later feature seems easy.

---

# Do Not Build Yet

Unless Leonardo explicitly authorizes it, do NOT implement during the current MVP:

* persistence
* saved player data
* DataStores
* ProfileStore
* shop
* gamepasses
* developer products
* crates
* mutation serum
* mutations
* collection Index
* zoo progression
* zoo expansion progression
* offline income
* season pass
* Mythic server events
* full animal library
* trading
* clans
* quests
* crafting
* combat
* weapons
* multiple currencies
* skill trees
* freeform building
* vehicles
* minigames
* themed zoo rebuilds
* level-gated rings
* auto-collect
* paid recovery
* teleport-home systems
* pay-to-win movement
* pay-to-win bump resistance

Do not create placeholder architecture for these unless it is genuinely required by the current MVP.

---

# Core Design Rules

These rules are non-negotiable unless Leonardo explicitly changes them.

## Greed Creates the Chase

Every additional valuable animal should increase reward while also increasing risk through:

* weight
* slower movement
* Heat
* Ranger pressure
* visibility to other players
* longer escape exposure

The player creates their own difficulty by becoming greedy.

## You Lose the Trip, Never the Property

Banked animals are permanently safe.

Players may lose what they are currently carrying.

They do not lose already banked property.

## Zoo Safety Is Absolute

Once a player crosses into their zoo:

* carried animals bank
* Heat resolves
* Rangers give up
* other players cannot steal the banked property
* bump pressure ends

The zoo boundary is the emotional relief moment.

## Ring 1 Is the Learning/Safe Area

Ring 1 protects new/small-stack players from unfair early griefing.

Do not accidentally make the onboarding area hostile.

## Depth Is Open From Minute One

Do not add level gates to deeper rings unless Leonardo explicitly changes this rule.

Risk, weight, capacity, distance and Heat are intended to create the soft gate.

## Rangers Are Pressure, Not Punishment

There is one enemy type: Rangers.

Do not create:

* elite Rangers
* bosses
* variants
* additional enemy archetypes

Rangers create pressure and openings.

Players create the major catastrophe.

A Ranger should normally knock only 1–2 animals loose.

If Rangers feel oppressive, tune them down before making them more punishing.

## Bumping Is a Skill Check

A bump is an explicit shoulder-check.

It is not passive character collision.

It must be readable, dodgeable and have a cooldown.

Players should feel:

"he got me"

not:

"the game randomly stole my stack."

## PvP Is Additive, Not Required

The game must remain fun in a nearly empty server.

Rangers ensure the core tension still works without many humans.

Do not architect the game so full servers are required for basic fun.

---

# The Stack Is the Product

The carried animal tower receives extremely high polish priority.

The server owns WHAT the player carries.

The client owns HOW the carried stack looks.

The carried stack must never rely on real Roblox physics.

Use controlled client-side visual positioning such as:

* springs
* interpolation
* sway
* delayed following
* lean
* acceleration response
* idle movement

The stack should visually communicate:

* weight
* greed
* value
* danger
* comedy

Turning with a large stack should feel visually different from carrying one small animal.

Camera response, sound and animation may reinforce the weight.

---

## UI Visual Direction

Reference screenshots live in `assets/references/ui`. Use them for quality bar and visual language ONLY — never copy another game's exact interface, layout, icons, or screen composition.

The target is bold, modern Roblox simulator UI: polished and intentionally designed, never minimalist, never generic SaaS-style.

**Typography & outlines**

* One heavy rounded display font everywhere
* White text with a strong black stroke
* Thick black outlines on text and frames (UIStroke, gradient inside the stroke for bevel)

**Shape & shadow**

* Chunky rectangular buttons with slightly rounded corners
* Hard offset drop shadows (e.g. 0, 4px), never soft modern blurs
* Studded/blocky texture treatment where appropriate, matching the world's graybox-brick look

**Color**

* Bright, saturated, semantic, held rigidly:
  * green = positive/buy/money
  * red = sell/negative/close
  * blue = information
  * gold/yellow = premium/reward

**Iconography**

* Playful cartoon icons, consistent set, one sprite sheet
* Icons carry meaning before text does

**Hierarchy & mobile**

* Strong visual hierarchy — the one thing that matters on screen reads first
* Large touch targets
* Excellent mobile readability at small screen sizes

**Motion**

* Animated counters — currency counts up, never snaps
* Responsive button press feedback (fast press tween, ~0.08s)
* Bouncy back-easing transitions on open (~0.25s)
* A click sound on every button

These rules extend the "UI craft" section of `GAME_DESIGN.md`; if they ever conflict, `GAME_DESIGN.md` wins.

---

# Server Authority

Gameplay state is server-authoritative.

Never trust the client for:

* animal ownership
* animal identity
* animal weight
* pickup validity
* player position when validation matters
* bank rewards
* income
* spill results
* bump results
* carry capacity
* purchases
* ownership transfers

The client may request an action.

The server decides whether that action is valid.

Avoid exploit-prone client-authoritative designs even during prototyping.

---

# Config Rules

All meaningful tuning values belong in configuration modules.

Do not scatter magic numbers through gameplay scripts.

Examples:

* animal weight
* income
* rarity
* carry capacity
* base walk speed
* speed curve
* Heat thresholds
* rarity Heat surcharge
* Ranger speed
* Ranger count
* Ranger telegraph duration
* bump wind-up
* bump cooldown
* spill radius
* ring radius
* spawn rates

Prefer data-driven configuration so Leonardo can tune the game without rewriting systems.

---

# Project Structure

Rojo mappings:

`src/server`
→ `ServerScriptService.Server`

`src/shared`
→ `ReplicatedStorage.Shared`

`src/client`
→ `StarterPlayer.StarterPlayerScripts.Client`

Use these responsibilities:

## server

Server-authoritative systems and services.

## shared

Configuration, shared types, definitions and data.

## client

Visual rendering, UI, camera, input presentation and feedback.

Do not manually create duplicate versions of Rojo-managed scripts inside Roblox Studio.

---

# Roblox Studio MCP

Roblox Studio MCP is available.

Use it when helpful to:

* inspect the DataModel
* inspect instances
* inspect scripts
* verify Rojo synchronization
* run Luau
* inspect Studio Output
* perform playtests
* debug runtime behavior
* verify implementation

Do not make unrelated changes to the Studio place while solving a task.

Before a major Studio modification, understand whether the object is Rojo-managed or Jadon-owned.

---

# Development Process

For each requested feature:

1. Read `GAME_DESIGN.md` if the task touches game behavior or architecture.
2. Inspect the existing code before writing new code.
3. Identify which system owns the behavior.
4. Implement the smallest correct version.
5. Avoid unnecessary frameworks and abstractions.
6. Keep the server/client boundary clear.
7. Put tuning values in config.
8. Run relevant tests.
9. Use Roblox Studio MCP when runtime verification is useful.
10. Check Studio Output for warnings/errors.
11. Fix regressions caused by the change.
12. Summarize exactly what changed.
13. Mention anything that still needs manual playtesting.

Do not claim something works merely because the code looks correct.

Verify behavior whenever practical.

---

# Code Quality

Prefer:

* readable Luau
* small focused modules
* clear names
* explicit ownership of state
* predictable data flow
* simple APIs
* defensive server validation
* easy-to-tune configuration
* mobile-conscious performance

Avoid:

* giant scripts
* unnecessary metaprogramming
* premature abstraction
* duplicated state
* hidden magic numbers
* physics-heavy carried objects
* excessive RemoteEvents
* client-authoritative gameplay
* speculative systems for future features

---

# Git Safety

`main` represents the stable build.

Leonardo owns merges and releases.

When working:

* keep changes focused
* do not delete unrelated files
* do not rewrite working systems without a reason
* inspect current work before modifying it
* avoid mixing several unrelated features into one change
* preserve rollback ability
* explain unusually large changes before making them when appropriate

Never intentionally leave the project in a broken state.

---

# Playtesting Philosophy

Metrics are evidence, not targets to manipulate.

The game should earn session length because players naturally want another run.

Do not build artificial playtime inflation.

Important MVP signals include:

* runs per session
* ring depth reached
* Heat reached
* spontaneous player bumping
* average session length
* whether players immediately run out again after banking or losing a stack

The qualitative signal matters heavily.

Players should naturally create moments like:

* "one more"
* "don't hit me"
* "get the whale"
* scrambling after a spill
* immediately chasing another run

If the core server feels quiet or boring, do not assume more features will fix it.

---

# Production Priority

When choosing between:

more features

and

making Grab → Stack → Slow → Greed → Escape → Bank feel better

choose the core loop.

When choosing between:

more animal quantity

and

making the carried stack funnier and more readable

choose stack quality.

When choosing between:

complexity

and

clarity

choose clarity.

We are trying to prove a simple game at high execution quality, not build a large game as fast as possible.
