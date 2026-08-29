Roblox game design document · v2 · 28 August 2026
Don't Drop It
Run into the middle of the map, grab escaped animals, and carry them back to your zoo. Bigger animals are worth more, weigh more, and live further in. The more you take, the more attention you attract — and the harder getting home becomes.

The one-line pitch
Stack as much value as you dare. The more you take, the harder escaping becomes.

Steal a Brainrot: take valuable things from people.  ·  Steal An Egg: steal an egg and escape its guardian.  ·  Ours: greed creates the chase.

3
Verbs
8
Players / server
5
Rarity rings
1
Enemy type
17 min
Session target
~2,000
CCU for $26K/mo
What this is, honestly
Read this first. It sets expectations for everyone on the project.

This is a deliberately derivative game. The template underneath — a plot, collectibles that generate money per second, rarity tiers, mutations, a collection index, offline income — is the most proven loop on Roblox and we are not trying to reinvent it.

We're copying the strategy that worked. Steal An Egg is derivative of Steal a Brainrot. It launched 25 July 2026 and hit 2.2 million concurrent players in 28 days without a single novel system. It won on one structural change: acquisition went from clicking a conveyor (2 seconds, no risk) to outrunning a guardian across a map — and that nearly doubled average session length, 9.3 minutes to 17.0.

Session length is what the Roblox algorithm started paying for on 15 June 2026, when it extended its retention window to 28 days and made short first sessions an explicit negative signal. So: proven template, one structural change to acquisition, win on session length and feel.

Our structural change: greed creates the chase. Every extra animal simultaneously raises your reward, slows you down, attracts NPC Rangers, and makes you a more attractive target for other players. You chose all four of those things when you grabbed the tenth animal.
Steal An Egg's guardian is fixed — you take one egg, one guardian chases you, every time. Ours scales with a decision you make continuously. One animal is a walk. Five is a jog with someone watching. Ten including a Legendary is good luck.

Design principles
These are not preferences. Violating any of them breaks the game, and they override anything else in this document.

You lose the trip, never the property
Getting bumped costs you a run — two minutes and a walk. It never costs you something you already banked. Everything in the zoo is permanently safe. This single rule is why the game can have theft without the rage that gives Steal a Brainrot 2.6 million downvotes at 85.3% approval.

Never sell a way out of the loop
No auto-collect, no instant recovery after a spill, no teleport home. Selling the removal of Grab → Carry → Bank is selling the player a way to not play the game, and monetising the emotional climax by immediately undoing it. Sell progression, collection, and status instead.

Never sell an advantage in the bump
The bump is the most important interaction in the game. If spenders are visibly harder to catch or harder to escape, free players read every loss as purchased rather than earned, and the community turns. Movement and bump resistance are earned through progression only.

Bumping is a skill check, not a collision
No passive body collision spills anything, ever. A bump is an explicit shoulder-check with a visible wind-up, a cooldown, and a dodge window. The player who loses a ten-animal stack must think "damn, he got me" — not "this game is broken."

The game must work in an empty server
Tension can never depend on other players showing up. Rangers guarantee it. This is not a nice-to-have — a new game runs three-player servers during exactly the window the algorithm is grading it, and a design that needs a full lobby is broken precisely when it most needs to be good.

One enemy type. Forever.
Rangers. That's it. No enemy variety, no elites, no bosses, no AI archetypes. One instantly readable threat with one rule: don't let it hit your stack. The moment a second enemy type is proposed, the game has stopped being simple.

Depth is open to everyone from minute one
No level gates on rings. A brand-new player can sprint straight to the centre and grab a whale. The question isn't whether they're allowed — it's whether they can get it home. That produces "BRO I GOT A MYTHIC ON DAY ONE," which is worth more than any progression wall.

The soft gate is already built. A 26-weight whale against 30 starting capacity leaves almost no room, drops you to a crawl, and triggers maximum Heat on contact. Capacity, weight and Heat are the gate — and a natural one is far more interesting than "Level 15 Required." If testing shows everyone rushes the centre immediately and progression feels pointless, add unlocks then. Do not solve a problem before you have observed it.

The stack is the product
If ten animals sit rigidly on a player's back, this game is mediocre and nothing else in this document saves it. Wobble, lag, sway, lean, weight, sound, camera pullback. Someone carrying frog + chicken + pig + giraffe + T-rex + whale must be funny on a muted TikTok.

The map
Concentric rarity rings. Zoos on the outside, the best animals dead centre.

Ring 1 · Common · safe
Ring 2 · Rare
Ring 3 · Epic
Ring 4 · Legendary
Centre · Mythic
ZOOZOOZOOZOOZOOZOOZOOZOO
Total field radius ~110 studs. Ring 1 outer edge sits ~15 studs from every zoo line.
Every successful run has the same shape: go in → get greedy → escape out.

This is the single best structural idea in the design, because it makes the map itself teach the game. A child sees bigger, crazier animals toward the middle and understands the whole progression without a menu.

And it means the better the animal, the longer you must carry it. A frog is five seconds from your zoo. A whale means you ran to the dead centre, everybody watched you take it, it weighs more than everything else combined, and now you have the longest possible trip home while moving at walking pace. The reward and the danger are the same distance.

Ring rules
Ring	Animals	Weight	Bumping	Rangers	Walk home
1 — Common	frog, chick, cat	1–2	Disabled — safe	None, ever	~5s
2 — Rare	pig, penguin, dog	3–4	Enabled	Rare patrol, high heat only	~12s
3 — Epic	cow, gorilla, shark	7–8	Enabled	React to medium heat	~22s
4 — Legendary	elephant, giraffe	14–15	Enabled	Aggressive	~35s
Centre — Mythic	whale, T-rex, ???	24–26	Enabled — chaos	Maximum	~55s
Ring 1 is a safe learning zone. No bumping. A kid carrying his first frog cannot be spawn-camped. The ground and lighting change visibly at the Ring 2 boundary with a one-line warning — ⚠ STACKS CAN BE KNOCKED DOWN PAST THIS LINE — so entering danger is always a choice the player made. Playtest whether Ring 1 should stay permanently safe or only until a player's first bank.

Zoos are absolutely safe. Cross your zoo line and you cannot be bumped, followed, or robbed. That boundary is the relief moment the entire tension curve resolves into.

Heat
The greedier you get, the more attention you attract. This is the system that makes the game work with nobody else online.

Every animal you're carrying adds Heat. Heat determines how many Rangers come for you. A frog is nothing. Five animals and you're visibly overloaded. A gorilla plus a cow plus a pig and someone has noticed. A Legendary is instant attention.

Rangers don't kill you, arrest you, or take your animals. They knock one or two loose — which scatter as free pickups like any spill. That's deliberate: a Ranger is pressure, a player bump is catastrophe. Keeping those different is what stops Rangers from feeling like punishment and keeps other humans as the real threat.

Heat	State	Rangers	What the player experiences
0–5	Clear	0	Nothing. Walk home whenever you like.
6–14	Noticed	1	A whistle. One Ranger starts walking your way, slowly.
15–24	Wanted	2	Screen edges tint. Two Rangers, moving with purpose.
25+	High Value	3	Alarm. Three Rangers, fast, converging. Everyone on the map can see your marker.
Heat = total carried weight, plus a rarity surcharge. Legendary adds +10 on pickup, Mythic adds +20. So a whale (weight 26) plus its Mythic surcharge is Heat 46 — maximum Rangers the instant you touch it, before you've taken a single step. That is exactly right.

Heat decays when you drop below a threshold, and collapses to zero the moment you cross your zoo line. Rangers give up at the boundary and walk away. Same relief moment, doubled.

The Ranger
What it does
Walks toward you. Winds up a visible swing with a 0.5s telegraph. On a hit, one or two animals pop off your stack and scatter. It cannot follow you into Ring 1 or into any zoo. One model, one animation, one sound. That's the entire enemy design and it never grows.

What it must never do
Never spill the whole stack — that's the player bump's job and the distinction matters. Never one-shot. Never spawn in Ring 1. Never appear without a sound cue first. Never scale into elites, variants, or bosses, no matter how tempting the content drop looks.

A Ranger's job is not to take your animals. It is to make you dodge, slow down, and become predictable — so a human can line up the shot. Rangers create the openings. Players cause the catastrophe.
Hold that framing while tuning, because it gives you the target: a player should be looking over their shoulder constantly and actually losing animals to a Ranger rarely. A rough benchmark — on a deep, high-Heat run, a competent player should get clipped roughly once, and a careless one two or three times. If Rangers are connecting on every run, they've stopped being tension and become a tax on playing well.

When it feels wrong, tune Ranger speed down before you tune anything else up. A slow, visible, dodgeable threat that you outrun by a hair is the whole feeling. A fast one that reliably lands is a completely different and much worse game.

A run, end to end
You're in Ring 3 carrying a frog, a cat and a pig. Heat 6, one Ranger drifting toward you. You see an Epic gorilla and take it — Heat 14, stack visibly taller, movement noticeably heavier. You should go home.

Deeper in you can see a Legendary giraffe. You go anyway. Heat jumps to 38. Alarm. Three Rangers. You are now carrying thousands per second at half speed with the longest possible walk ahead of you — and another real player has just spotted you coming outward with a marker over your head.

You dodge his shoulder-check. A Ranger nearly connects. Fifteen studs from your zoo line, he lines up a second one and lands it. Giraffe, gorilla and pig go flying. Four people scramble.

That's the game. And every single step of it was a choice you made, not a difficulty setting.
The loop
Three verbs. A seven-year-old learns all of it in under ten seconds without reading anything.

GRAB
Walk into an animal to pick it up. It stacks physically on your back, visible to everyone on the map.

GREED
Each animal adds income if you bank it — and right now adds weight and Heat. Heavier animals live deeper in. Two decisions, constantly: one more, or go home? One ring deeper, or turn around?

ESCAPE
Get back out through every ring you crossed, with Rangers converging on you and other players able to see exactly how loaded, how slow, and how valuable you are.

BANK
Cross your zoo line. THUD THUD THUD. Animals fill your pads, income counts up on screen — $417/s → $1,283/s — and it is permanently yours.

GROW
Spend on more pads, a bigger footprint, carry capacity, cosmetics. Your zoo gets bigger and fuller — and everyone can see it from across the map.

The first thirty seconds
Time	What happens
0:00	Spawn at your zoo. Ring 1 is fifteen studs away with animals visibly hopping around. No lobby, no menu, no camera pan.
0:04	Walk into a frog. It hops onto your back. +$2/s pops off it. Verb learned, nothing explained.
0:12	Three animals on your back. Cross your zoo line. THUD THUD THUD. Income counter climbs. First full loop done inside fifteen seconds.
0:20	You look inward. The colours change ring by ring and the animals get visibly enormous. Nobody told you that means better.
0:28	Someone staggers past you out of Ring 3 with a cow on their back moving at half speed, and a second player is chasing them.
0:40	You cross into Ring 2. The ground changes colour and warns you. You go anyway. That's the hook, and it fired inside a minute.
Weight is the whole economy
Weight is per-animal, never per-count. This is what makes a Mythic a decision instead of a pickup.

Carry capacity is a weight budget, not a slot count. Starting budget is 30. A whale weighs 26 — so the moment you pick one up you are at 26/30, moving at a crawl, and you can fit one more frog if you're insane. That is exactly the decision we want: bank this now, or push my luck for one more?

Animal	Ring	Weight	Income	Speed carrying just this
Frog	1	1	$2/s	15.9
Cat	1	2	$9/s	15.7
Pig	2	3	$45/s	15.4
Cow	3	7	$380/s	14.0
Gorilla	3	8	$610/s	13.6
Giraffe	4	14	$3,100/s	11.0
Elephant	4	15	$4,400/s	10.5
T‑Rex	Centre	24	$22,000/s	6.2
Whale	Centre	26	$31,000/s	5.3
Speed formula: walkSpeed = 16 × (1 − (W / Wmax)^1.4 × 0.72) where W is total carried weight and Wmax is your capacity. Non-linear on purpose — the first few kilos are free and the last few are brutal.

Capacity upgrades raise Wmax: 30 → 40 → 55 → 75. Note what that does — it doesn't just let you carry more, it makes the same whale less crippling. That's a progression reward that changes how the game feels rather than just how big a number is.

Server events
Rare animals do not spawn silently. They are announced to the whole server.

🚨 MYTHIC ESCAPED — A WHALE IS LOOSE
Centre of the field · everyone can see it
Every so often, instead of a quiet roll on a spawn table, a Mythic enters the field with a server-wide alert, a marker beam, and a visible arrival. Eight players sprint at the same object. One gets it. That player instantly hits maximum Heat, is the slowest thing on the map, is carrying the most valuable animal in the game, and has the longest possible walk home with three Rangers and seven humans converging.

Seven people immediately know what to do, and nobody had to be taught. That single moment produces competition, envy, a clip, and a reason for players to interact — without adding a single new system. It is the cheapest content in the entire design and it should fire every few minutes.

One open disagreement worth settling before build
There's a suggestion to gate centre events behind a required Zoo Level. I'd argue against it, because it contradicts the "depth is open to everyone" principle and kills the single best story the game can produce: "BRO I GOT A MYTHIC ON MY FIRST DAY."

The gate already exists and it's better than a level check — a new player can reach the whale, and then discovers they have 4 carry capacity to spare, maximum Heat, three Rangers, and no chance. They'll fail, and they'll immediately understand exactly what they need to come back with. That's a far stronger teaching moment than a locked door. Leonardo's call.

PvP is additive, never necessary
This is the design's most important structural property and it should be defended hard.

Nobody bumps? You still have greed, weight, Heat, Rangers, deeper rings and an escape. That is a complete game.
People do bump? Now it's greed, weight, Rangers and other humans hunting you. Much crazier.

Design so the floor is a real game and the ceiling is chaos. Most social games get this backwards — they need a full lobby to be fun, which means they're worst exactly when a new game has three people in a server and the algorithm is watching.

Why players will bump anyway
Because it pays. A spilled animal is free for anyone to grab and bank. If you're carrying a whale worth $31,000/s and I shoulder-check you and get it home, I just took the best animal in the game for the price of one input. Nobody needs to be told this — players work it out in their first session and then do it forever.

The ring structure guarantees the encounters. Everyone valuable is funnelled through the same corridor — deep in, then slowly back out — so you never have eight people wandering an empty field hoping to collide. Heat makes it worse in the best way: a high-Heat player has a marker over their head, so the whole server knows who's worth hunting. Scarce spawns create the conflict; greed does the rest.

Players invent their own strategies immediately: follow someone loaded, let the Rangers wear them down, and hit them fifteen studs from their zoo line.

The three protections
Zoo is absolute
Cross your line and it's banked. No bumping inside, no entry by other players, no stealing from pads — not in v1, and not later either. The zoo is the relief valve for every ounce of tension the field creates.

Small stacks are immune
Under 3 carried weight, you cannot be bumped. Combined with Ring 1 being permanently safe, a new player physically cannot be griefed while learning.

The bump is a skill check
Explicit shoulder-check input. 0.4s visible wind-up. 4-second cooldown. Fully dodgeable. You lose because someone read you, not because someone held a button. This is the single most important playtesting variable in the game.

What you keep
The animals
Physical size = weight = income. The art is the tutorial. Nobody needs to know a whale has Weight = 26 — they see a whale on someone's shoulders moving at 5 studs a second and they understand everything.

Mutations are material swaps on the same mesh: Golden ×2, Frozen ×2.5, Radioactive ×3, Rainbow ×5, plus seasonal sets. Forty animals × eight mutations is 320 distinct collectibles from forty models. That is the entire content pipeline, and it's the only cadence two people can sustain.

The zoo expands — it does not rebuild
Deliberate decision: no themed zoo tiers, no visual rebuilds. Levelling up adds pads and enlarges the footprint. That is all. The enclosure stays the same visual kit at every level; there is just more of it, holding more animals.

Two reasons. First, the flex was never the fence. Nobody is impressed by your ticket booth — they're impressed by the Rainbow T-Rex standing on it. Every ounce of visual interest should come from the animals, because the animals are also the content pipeline. Second, five distinct zoo builds across eight plots is weeks of Studio labour for a progression beat that "more pads" already delivers, and art is the bottleneck for a two-person team, not code.

This also matches the reference. Steal An Egg's pens multiply; they don't get rearchitected. Steal a Brainrot adds floors and slots to the same rack. Grow a Garden's plot just gets fuller. None of the games at the top of the chart rebuild the environment — they add room for more stuff.

Zoo level	Pads	Footprint	What actually changes
1	4	1×	Starting plot
2	6	1.3×	More pads, wider plot. Same kit.
3	9	1.7×	More pads, wider plot. Same kit.
4	13	2.2×	More pads, wider plot. Same kit.
5+	18+	3×+	Keeps scaling on the same curve
Because the zoos ring the field, you look across the map and see the player opposite you owns a Rainbow T-Rex. That's aspiration with no menu involved: how the hell did he get that? A bigger plot full of bigger animals reads as wealth from two hundred studs away. It does not need a themed rebuild to say so.

Zoo themes stay in the shop as an optional cosmetic — but as post-launch content you ship one at a time when there's spare art capacity, never as a required progression tier.

Money
Monetize progression, collection and status. Never the loop, never the bump.

Type	Item	The moment it sells	Robux
Progression	2× Cash the only income multiplier	Always	99
Progression	+10 Carry Weight	Standing over an animal you can't lift	349
Collection	+4 Display Pads	Out of pad space	499
Collection	2× Mutation Chance	A Mythic with no mutation	499
Status post-launch	Zoo Themes — safari, arctic, prehistoric	Seeing someone else's	399–899
Status	VIP — nameplate, tag, entrance	—	899
Cosmetic	Stack Effects — trails, sparkles, sounds	Carrying a big stack past people	199–399
Cosmetic	Bank & Bump Animations	The moment of triumph	249
Whale	Premium Zoo Showcase	Being top of the server	1,700–3,400
Repeatable	CRATES — guaranteed rare animal, published odds	The reveal	175 / 599 / 2,399
Repeatable	MUTATION SERUM — reroll a mutation	A perfect animal with a bad roll	249
Retention	SEASON PASS — 10 tiers, one month	Day 8–28	499–799
Cut from v1, deliberately
Auto-Collect (799) — sells a way to not play the game. Instant Recover (149) — monetizes the emotional climax by undoing it. Faster Walk and Steady Hands — direct advantages in the bump, which turns every free player's loss into "he paid for that." All four are cut. Also cut: trading, and time-skips of any kind.

One income multiplier, and one only
"2× Cash" and "2× Zoo Income" are the same purchase wearing two hats, and stacking them is how a shop starts feeling like a slot machine. 2× Zoo Income is cut. Any second progression purchase has to live on a genuinely different axis — capacity, collection, or status — never a second multiplier on the same number.

Design the sink before the multiplier
"2× Cash" is the most common gamepass on Roblox and it is worthless unless money buys something on an exponential curve. Draw the zoo upgrade cost ladder first, then price everything against it. This is the omission that makes most first economies unsellable.

And none of this ships before the loop proves itself. The entire shop is Phase 3. A monetization plan for a game nobody wants to play twice is wasted work.

Team
Two people and Claude. Clear ownership, one merge authority.

Leonardo — Lead Developer	Brother — World & Content	Claude Code — Engineering
Game architecture	The field and all five rings	Module implementation
Animal, carry and weight systems	Zoo plots and level transforms	Refactors and debugging
Bump, spill, bank	Animal asset prep and rigging	Test harnesses
Economy and balance	Spawn placement and pacing	Repetitive implementation
Persistence and DataStores	VFX and sound placement	Config scaffolding
Purchases and receipts	Playtesting, especially mobile	Anti-exploit review
Anti-exploit and analytics	Weekly content prep	—
Merge and release authority	Thumbnails and gameplay capture	—
One hard rule
Only Leonardo changes core systems. Nobody else touches DataStores, transactions, economy maths, remotes, purchases, ownership transfer, or anti-cheat. Anyone can propose anything — architecture and merges have one owner. This is how two-person projects stay clean.

Give the brother something real
Not an assistant. He owns the answer to: "when somebody joins, does this look like a polished Roblox hit or a vibe-coded prototype?" That's map, visual content, animal presentation, playtesting and weekly content. Leonardo makes the machine work; he makes it worth playing.

Tuning numbers
Starting values. All of it lives in one Config ModuleScript — no magic numbers anywhere else.

Parameter	Start	Notes
Server size	8	Small enough that theft is personal
Field radius	110 studs	Centre to Ring 1 outer edge
Zoo line offset	15 studs	Beyond Ring 1
Base walk speed	16	Roblox default
Starting carry weight	30	Upgrades: 30 → 40 → 55 → 75
Speed formula	16 × (1 − (W/Wmax)^1.4 × 0.72)	Weight-based, non-linear
Bump wind-up	0.4s	Visible and dodgeable
Bump cooldown	4s	Prevents spam
Bump immunity	W < 3	Plus all of Ring 1
Spill radius	15 studs	A scramble, not a mugging
Heat formula	W + rarity surcharge	Legendary +10, Mythic +20
Heat thresholds	6 / 15 / 25	1 / 2 / 3 Rangers
Ranger speed	13 → 17	Scales with heat tier. Always catchable-ish, never hopeless.
Ranger swing telegraph	0.5s	Slower than a player bump — NPCs must be more readable than humans
Ranger knock-loose	1–2 animals	Never the whole stack. That's the player's job.
Heat decay	2/sec	Once below tier threshold. Instant zero at zoo line.
Mythic event interval	3–6 min	Server-wide alert
Target run length	45–90s	Many decisions per session
Session north star	17+ min	A goal to measure, never a number to engineer. Instrument it day one and let it be an outcome.
Systems to build
Server-authoritative unless marked client.

#	Module	Responsibility	Phase
01	AnimalSpawner	Per-ring spawn tables, respawn timing, simple wander AI	MVP
02	Pickup	Server-validated, appends to carried list, rejects over weight budget	MVP
03	CarryState	Owns carried list and total weight; computes and applies speed	MVP
04	StackRender (client)	Spring lag, lean on acceleration, idle sway. Never physics.	MVP
05	Bump	Input, wind-up, cooldown, immunity, knockback	MVP
06	Spill	Scatters carried animals into free world pickups	MVP
07	Bank	Zoo boundary, empties stack to pads, bank sequence	MVP
08	Income	Per-animal $/sec, aggregated, server heartbeat	MVP
09	RingZones	Ring boundaries, bump enable/disable, ranger permissions, visual transitions	MVP
10	Heat	Computes heat from carried weight + rarity surcharge; drives ranger count, marker, screen state; collapses at zoo line	MVP
11	Ranger	Spawn, pursue nearest high-heat player, telegraph, swing, knock 1–2 loose, despawn at boundary	MVP
12	Config	Every tuning number, every animal, every ring, every heat threshold	MVP
13	ServerEvents	Mythic spawn alerts, beam markers, announcements	P2
14	Persistence	ProfileStore, session-locked, sharded keys, transaction log	P2
15	Zoo	Pad count, footprint scaling, upgrade costs. No visual rebuilds.	P2
16	Index & Mutations	Collection grid, mutation rolls, completion rewards	P3
17	Shop	Passes, dev products, ProcessReceipt	P3
Non-negotiable engineering rules
The stack is never physics
Position and rotation lerps only, computed client-side from a replicated list of animal IDs. Real physics on a carried stack will desync, explode, and destroy your server heartbeat. Server owns what you carry; client owns how it looks.

Server authority on every transfer
Pickup, spill and bank all validate server-side. Never trust a client-supplied animal ID, weight, or position. Every ownership change writes to an idempotent transaction log so a duplication exploit is detectable and reversible.

No unsharded global keys
DataStore allows ~4 MB per key per minute regardless of player count. A single global leaderboard key throttles the moment you succeed. Shard from the first commit.

Feature flags from day one
A runtime config store readable without republishing. You cannot ship a Studio fix at 3am at fifty thousand concurrent players. Build the kill switch before you need it.

Feel and interface
The stack gets more polish hours than anything else in the game. It is the product.

Stack feel
Each animal follows the one below on a spring, so turning whips the tower. Tilt opposite to acceleration. Idle sway scaling with height. Per-animal pickup sound and a layered ambient clatter — squeaks, moos, roars — that thickens as the stack grows. Camera pulls back so the world shrinks around you. Heavier footsteps, slower turn rate, more camera bob under load.

UI craft that separates pro from vibe-coded
One heavy rounded display font everywhere. UIStroke on every text and frame, with a UIGradient inside the stroke — that's what makes buttons look bevelled. UIPadding on everything. Hard 0 4px 0 offset shadow, not a soft blur. Semantic colour held rigidly: green buys, red sells and closes, blue informs, gold is premium. Back-easing tweens on open (0.25s) and press (0.08s). Currency counts up, never snaps. A click sound on every button.

Split the HUD across ScreenGuis
Roblox caches a Gui's appearance and any change to any descendant invalidates the whole tree. One ticking money counter inside your main HUD makes the entire HUD recompute every frame. Static frames in one ScreenGui, animating numbers in another. Documented saving: 1.9ms — over 11% of a 60fps frame budget.

Where to spend art money
Not a full UI commission. One icon set plus one button 9-slice sprite sheet, roughly $50–150. Consistent icons make hand-built frames look professional; mismatched free-model icons make good layout look amateur. Every icon in one sprite sheet — saves mobile texture memory and forces consistency as a side effect.

Projected CCU and revenue
Scenarios, not predictions. The odds are judgment; the cash column is arithmetic.

Scenario	Odds	Avg CCU	Cash / month	Cash / year
Doesn't find an audience	~65%	< 500	< $6K	—
Conservative viable	~18%	2,000	~$26K	~$316K
Strong	~11%	8,000	~$105K	~$1.26M
Breakout	~5%	30,000	~$395K	~$4.7M
Top of the chart	~1%	150,000+	~$2M+	—
Method: Roblox books $0.0537 per engagement hour platform-wide (Q2 2026 bookings over hours engaged); about 21% reaches a developer after the 30% marketplace fee and DevEx at $0.0038. A 1.6× premium is applied because a collection economy with repeatable crates monetizes above average — inside the observed twelve-fold spread between Adopt Me and Brookhaven, but an assumption, not a measurement. Inferred

Comparables for the achievable band, pulled 28 Aug 2026: Cut Grass Adventure 35,783 live · Greedy Growers 73,089 peak · Grow a Chicken Fighter 242,669 peak · Clean all the leaves 124,835 peak. Those are the games with this DNA and this simplicity class.

MVP — two to three weeks
Do players greed for one more animal and one ring deeper — and does losing the stack feel funny rather than infuriating?
Build
The ring field with three rings, eight players, six animals with real weights. Pickup, visible stack, weight-based slowdown, ring boundaries, Heat with the marker, one Ranger type, bump with wind-up, spill, bank at your zoo line, $/sec ticking. Loop forever. Modules 01–12.

Rangers are in the MVP. Without them a six-person private playtest can read as boring purely because polite testers don't bump each other — and you'd kill a good design for the wrong reason.

Do not build
Saved data, shop, gamepasses, mutations, the index, zoo levels, offline income, Mythic server events, forty animals, sound beyond four effects, polished UI. Nobody — not Leonardo, not his brother, not Claude — adds anything to this list until the question above is answered.

Signal	Kill	Iterate	Strong
Runs per session	< 5	5–10	> 10
Players who reached Ring 3+	< 50%	50–80%	> 80%
Runs ending above Heat 15	< 25%	25–50%	> 50%
Players who bumped someone unprompted	< 40%	40–70%	> 70%
Average session	< 8 min	8–14 min	> 14 min
Run the test twice — once with two players, once with eight. The two-player run is the more important one, because it proves the floor. If a near-empty server is still tense, the design survives its own launch window. If it's only fun at eight, you have a game that is worst exactly when the algorithm is deciding whether to distribute it.

On the 17-minute target
Treat it as a north star, not a number to engineer toward. The table above is the real signal — runs per session, ring depth, Heat reached, spontaneous bumping. If players naturally keep saying one more, session length arrives on its own as a consequence.

The failure mode here is well documented and recent: Steal An Egg engineered time-in-game with an autoplaying video feed on its treadmill, and Roblox banned the entire mechanic class on 25 August 2026. Anything that inflates session length without making the loop better is both against the rules and pointed at the wrong metric — playtime is capped at 60 minutes per user per day for ranking anyway, while play days is not. Long sessions should be evidence the game is good, never the goal itself.

The real test is qualitative. Get six to eight people in a private server and listen for whether these happen without anyone being told how to have fun:

"ONE MORE."
"BRO DON'T HIT ME."
"GET THE WHALE."
"NOOO I DROPPED IT."
"GRAB HIS SHIT."
"RUN RUN RUN."

If people say those things unprompted, the concept is done being questioned and the only job left is pouring fuel on it. If the server is quiet, no amount of content fixes it.

Before spending anything on acquisition, the community benchmark is eight minutes average playtime and 10% day-one retention. The ranking algorithm only grades players arriving organically from the Home page, and you sit that exam once per content update.

Deliberately not in the game
Adding any of these is how this gets ruined. If a sixth rule appears, something else gets cut.

zoo raiding
trading
clans
combat
guns
quests
skill trees
crafting
freeform building
multiple currencies
driveable vehicles
PvE enemies
dialogue
minigames
a large world
level-gated rings
tutorial
auto-collect
paid recovery
time skips
pay-to-win movement
themed zoo rebuilds
zoo visual tiers
The honest risks
The differentiator is two sentences
Carry many instead of one and pay in your own speed; go deeper for better and pay in distance. Everything else already ships — Steal a Brainrot has visible carried loot, a speed penalty, get-hit-and-drop, carry-home-to-bank, rarity, mutations, an index and offline income. Load The Truck already sells an "Infinite Carry" gamepass. We are betting on execution, and everyone should know that going in.

Bumping could read as unfair
If it feels random rather than earned, approval tanks and the game dies of its own community. The wind-up, cooldown, immunity window, safe Ring 1 and wide spill radius are all defences — and they need real playtesting rather than assumption.

The stack could feel flat
The tower is the entire product. No weight, no wobble, no momentum, and nothing else in this document matters.

Rangers could feel like an annoyance rather than pressure
This replaced the old "nobody might bump" risk, which Heat solves. The new risk is the opposite: if a Ranger connects too often, or knocks too much loose, or isn't clearly telegraphed, it stops being tension and starts being tax. The 0.5s telegraph and the 1–2 animal limit are the guards. Tune Ranger speed down before tuning anything else up.

The clone cycle is fast
This is a two-week fork for anyone who sees it working. The defence is cadence and feel, not secrecy. Whoever ships better content faster wins, from month one.

Single-account platform risk
Live games get removed after mass reporting, with appeals rejected and inconsistent reasons given. No portability, no insurance. Not a reason to skip the platform — a reason not to make it the only thing either of you is building.