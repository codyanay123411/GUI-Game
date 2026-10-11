# Game Design

## Director-authorized contextual map presentation — 2026-10-10

Province selection surfaces relationship-aware map actions, then a focused drawer or an existing full workflow. War/Conquer requires a review and explicit confirmation; declaration, commitment, Ready/Lock and battle rules remain unchanged. Full navigation remains accessible. Small screens may use a compact action list. Province attention shows unread communication, incoming offers, relevant wars and temporary results; aggregate the highest priority with a count. Ruler events anchor to their personally owned territory nearest the local greater realm; war/results anchor to the actual target. Existing notification, audio/settings and communication permissions remain in force. This is presentation authorization, not new gameplay scope or Director implementation acceptance. See `AI/CONTEXTUAL_MAP_INTERACTION.md`.

**Authoritative product vision (design bible v0.1).** This file is the game’s product and design direction. Project directors (the user and their design collaborator) determine mechanics. Implementation agents implement approved designs accurately.

AI agents must **not** silently alter this design, redefine an unspecified mechanic, or modify this document to justify an implementation. Do not materially change, expand, reinterpret, or invent mechanics beyond what is written here. When an important mechanic is unspecified, ask for design direction.

Unspecified mechanics remain intentionally unspecified until the directors design them. Concepts in this document are **not** authorization to implement those systems.

---

## Game Vision

A GUI-first **multiplayer feudal grand-strategy and political role-playing game** for Roblox.

Inspired by experiential concepts of character-driven grand strategy — not by recreating a historical timeline or another game’s exact mechanics:

- Characters rather than abstract nations
- Political hierarchy, rulers and subjects, vassalage
- Dynasties and succession
- Diplomacy, alliances, warfare, political intrigue
- Religion
- Territory and titles, realm building, internal politics
- Emergent player-created history

The game must have its **own** terminology, presentation, balancing, systems, and implementation.

The world and its history are **created by the players during each match**. The setting is fictional. Kingdoms, empires, alliances, wars, dynasties, rivalries, religious movements, political collapses, and other major events emerge from player actions. The map at the end of a match should represent that server’s political history.

## Design Pillars

**Compress** a larger feudal grand-strategy experience into a Roblox session that:

- Is understandable to ordinary Roblox players
- Provides meaningful strategic and political depth
- Creates frequent player interaction
- Produces emergent stories
- Supports different playstyles
- Has fast enough pacing for Roblox
- Feels satisfying within a single session
- Encourages repeated matches
- Does **not** require players to understand the complexity of the underlying simulation

The simulation may be complex internally. Player interaction with it should stay understandable and responsive. **Complexity belongs in systems, not in unnecessary micromanagement.**

Further pillars specified by directors:

- **GUI-first.** The interface is the primary game environment. No requirement for a traditional explorable 3D world.
- **Shared political world.** Players are not isolated into private kingdoms or private simulations.
- **Subordination is gameplay, not elimination.** Conquest or vassalage does not automatically remove a player from the match.
- **Accelerated political history.** A ~30-minute match may represent many years or generations.
- **Multiple paths to victory.** Victory must not require eliminating every other player.
- **Incremental implementation.** Directors define mechanics; agents implement them. Do not build the entire design at once.
- **Useful grand-strategy concepts, not unnecessary grand-strategy complexity.** Complex political outcomes should eventually emerge from relatively simple player-facing systems. This is **not** intended to become a deep historical character/family simulator.
- **Player-relevant information.** Ordinary player-facing UI must use player/realm-relevant views of authoritative server state. Global server state is not automatically player-visible. Admin/debug inspection is exempt. Systems that intentionally expose global/public information must explicitly define that visibility. Subjects inherit their greater realm’s relevant view.

**Currently approved core identity:** for playable prototypes, the human player is effectively their **ruler identity for the match**. Aging, generational succession, family simulation, and natural character death are **not** part of the currently approved core design. Do not implement those systems. Long-term character/dynasty ideas elsewhere in this bible remain long-term / deferred unless directors later approve them.

## Match Structure

Target **maximum match duration: approximately 30 minutes**. A normal match should reach a meaningful conclusion in that window.

This requirement must influence future balancing of political progression, territorial expansion, wars, alliances, dynasty generations, succession, economy, religion, political actions, and victory progress.

The game must not require multi-hour sessions to experience its major systems. Favor accelerated political history. A single match may span many years or generations of fictional history.

All future **political hierarchy** mechanics must also respect this ~30-minute target. Political structures need enough time to form, grow, merge, fracture, compete, and potentially contribute toward victory — without multi-hour sessions. This does not authorize any specific balancing numbers.

## Multiplayer

Target **maximum server population: approximately 50 players**.

Players share one political world. Decisions directly affect other players.

Encourage: cooperation, rivalry, negotiation, betrayal, alliances, hierarchies, political maneuvering, warfare, and shared objectives.

Previous single-player-oriented development assumptions are **superseded** by this design.

## Player Identity

The player controls a **character**, not an abstract nation.

A character may possess:

- A personal identity
- A dynasty or house
- Family relationships
- Traits
- Attributes
- Titles
- Territory
- Wealth
- Military power
- Political relationships
- Religious affiliation
- Claims or political objectives

A player’s political situation can change **without** removing them from the match.

For currently approved core play, treat the player as their match ruler. Do not implement aging, family simulation, generational succession, or natural character death unless directors later authorize those systems.

## Political Hierarchy

Political Hierarchy Design **V0.1** is specified below. The V0.1 prototype is **accepted / complete**. Do not reopen or redesign it. Territory / Map Foundation V0.1 (specified separately) must integrate with it, not replace it.

Players exist in a shared political world as **independent rulers** or **subordinate rulers**. Relationships must support **nested** hierarchies.

### Landed title ranks

There are **four** primary landed political levels (intentionally few, for ~30-minute matches):

**Lord → Duke → King → Emperor**

This **supersedes** earlier conceptual ranks that used Count. Do not add extra landed title tiers.

Title **establishment** is specified under Titles & Territory as **Title Progression V0.1** (accepted / complete). Progression is sequential Lord → Duke → King → Emperor. Vale prototype test thresholds exist for that map only. Gold and Influence are **not** title-establishment requirements. Promotion is **not** automatic. Prestige is a threshold, **not spent**.

### Match start

In a **normal** match, every participating player begins as an **Independent Lord** controlling **one starting territory**.

There are no player-created Dukes, Kings, or Emperors at the start. Higher titles and larger realms emerge during play so each server creates its own political history.

Conceptually:

```text
Lord A
Lord B
Lord C
Lord D
Lord E
```

Not predefined player kingdoms or empires.

### Independence vs title rank

**Independent** is a political **status**, not a title tier.

A ruler may theoretically be an Independent Lord, Independent Duke, Independent King, or Independent Emperor — or a subject inside a larger hierarchy.

**Title rank** and **political independence** are separate. A Duke is not automatically independent because they are a Duke.

### Direct liege and direct vassals

Hierarchy is ruler-to-ruler.

- **Liege:** the ruler directly above, or none if independent.
- **Direct vassals:** rulers directly subordinate.

Example:

```text
Emperor Aldric
└── King Robert
    └── Duke William
        └── Lord Henry
```

- Henry’s direct liege is William.
- William’s direct liege is Robert.
- Robert’s direct liege is Aldric.
- Aldric has no liege and is independent.

The simulation must **eventually** traverse this tree for higher political authority and realm membership. That is a conceptual requirement, not a prescribed data structure.

### Direct vassals vs indirect subjects

Robert is Aldric’s **direct vassal**. William and Henry are in Aldric’s **greater realm** but are **not** Aldric’s direct vassals. William answers to Robert; Henry answers to William. This distinction must remain meaningful in future political systems.

### Voluntary vassalage

An approved political action: a ruler may voluntarily become another ruler’s vassal when **both parties agree**, subject to title rank.

**Player-facing term:** this action is **Vassalage** (Offer Vassalage / Incoming vassalage requests). Do not use “Fealty” in player-facing UI.

**Allowed:** become the vassal of a ruler whose title rank is **equal to or higher** than one’s own.  
**Never allowed:** become the vassal of a ruler with a **lower** title rank.

“→” means “becomes the vassal of”:

```text
Lord → Lord        ALLOWED
Lord → Duke        ALLOWED
Lord → King        ALLOWED
Lord → Emperor     ALLOWED

Duke → Duke        ALLOWED
Duke → King        ALLOWED
Duke → Emperor     ALLOWED
Duke → Lord        NOT ALLOWED

King → King        ALLOWED
King → Emperor     ALLOWED
King → Duke        NOT ALLOWED
King → Lord        NOT ALLOWED

Emperor → Emperor  ALLOWED
Emperor → King     NOT ALLOWED
Emperor → Duke     NOT ALLOWED
Emperor → Lord     NOT ALLOWED
```

**Equal-rank vassalage is intentionally allowed**, so organizations can form before higher titles exist.

Example at match start: Bob, Henry, and Robert swear to Cody (all Lords). Cody’s greater realm then conceptually controls four territories if each holds one, which can contribute toward later **eligibility** to establish a Duchy (see Title Progression V0.1). On the Vale V0.1 test map, Duke requires **2** greater-realm territories and **100** test Prestige; those numbers are not universal.

```text
Lord Cody
├── Lord Bob
├── Lord Henry
└── Lord Robert
```

### Subordinate trees stay attached

**Core rule.** When a ruler becomes subordinate to another, that ruler’s **existing subordinate hierarchy stays attached**. Existing **direct-vassal** relationships are preserved. The joining ruler’s subjects do **not** become the new liege’s direct vassals; they become **indirect** members of the greater realm.

Example: Duke Cody (with Lords Bob, Henry, Robert) voluntarily becomes Duke Edward’s vassal:

```text
Duke Edward
└── Duke Cody
    ├── Lord Bob
    ├── Lord Henry
    └── Lord Robert
```

The same applies at any size (including nested Kings/Dukes/Lords under an Emperor who then vassalizes to another Emperor). Only the joining ruler’s **direct liege** relationship changes. Blocs can merge **without flattening** internal hierarchy.

**Inverse:** if that ruler later becomes independent, their subordinate tree **remains underneath them**. Subjects do not need to recreate relationships merely because their ruler’s liege changed.

**How** independence happens (peaceful release, negotiation, rebellion, independence wars, penalties, cooldowns, diplomatic consequences) is **not specified**. Do not invent those methods.

### Humans and NPCs

The hierarchy must **eventually** be able to contain human-controlled and AI/NPC-controlled rulers. Humans remain the primary drivers of multiplayer geopolitics. NPCs may occupy supporting or political positions where necessary. The same conceptual hierarchy rules should apply to both unless a later approved design says otherwise.

**Detailed NPC political behavior is not part of this specification.**

### Nested roles

A ruler can be a vassal and also a liege. Example: a Duke under a King who themselves has three Lords. Those roles are not contradictory. Nested political gameplay is intentional.

### Realm membership

The game must **eventually** distinguish:

- Direct liege
- Direct vassals
- Indirect subjects
- Independent rulers
- The top political ruler of a hierarchy
- Membership in the same greater political realm

In a four-level Emperor → King → Duke → Lord chain, all four belong to the **same greater realm**; their **direct** relationships remain distinct.

### No cycles

Hierarchy must remain a valid **tree-like** structure. Cycles are invalid (A→B→C→A). A ruler may not become subordinate to someone already **beneath them** in their own subordinate tree.

The authoritative simulation must **eventually** validate hierarchy changes and reject cycles. Validation is **server-authoritative**.

### Server authority

Political hierarchy is **authoritative game state**. The Roblox client must never be trusted to decide: who a liege or vassals are; whether a vassalage relationship is valid; whether a hierarchy change is permitted; whether title-rank rules allow it; whether a cycle would be created.

Clients may **request** political actions and **display** state. The **server** determines and validates the result.

### Unresolved (do not invent)

- Title-scaling formula and numerical thresholds for maps **other than** the Vale V0.1 test numbers (see Title Progression V0.1)
- Title-loss systems (revoke, usurp, surrender, destroy, war, succession, and similar)
- Vassal obligations (tax, military contribution, contracts, percentages, penalties, formulas). Economy V0.1 locks **no automatic tax/tribute** from greater-realm membership; it does **not** design a tax system.
- Independence **gameplay methods** (the hierarchy must support becoming independent later; methods are unspecified)
- Disconnect / reconnect behavior
- Join-in-progress participation

### Delegated greater-realm authority (future architecture — not implemented)

Future independent **roots** may delegate specific greater-realm powers to subjects. This is **not** Political Hierarchy V0.1, **not** Economy V0.1, and **not** a retrofit into accepted Warfare / Diplomacy / Title / Map systems.

**Effective delegated authority** = **rank defaults** + **individual overrides**.

- The independent **root remains the ultimate** greater-realm authority.
- **Subject status alone does not** automatically grant greater-realm powers.
- The root may configure **default delegated permissions by subject political rank** (example structure: Emperor configures Kings, Dukes, Lords). Those defaults are **realm-specific policy**, not universal hardcoded rules (“all Dukes can always do X”).
- The root may **grant or revoke individual overrides** for particular subjects (trust one Lord with an authority their rank default lacks; restrict one King despite a broader King default).
- Delegation lets an authorized subject **act on behalf of the greater realm**. It does **not** make them independent, create another root, change hierarchy relationships, automatically transfer territory ownership, or automatically transfer personal Gold.
- Permissions describe gameplay **authorities / capabilities**, not specific GUI buttons. Conceptual example: prefer `ExternalWarAuthority` over `CanPressDeclareWarButton`.
- Future gameplay systems should expose **delegation hooks** after their own authoritative APIs are designed. Do **not** define the complete permission catalog yet.

**Economy and delegation.** Economy V0.1 treasury ownership is **personal to the ruler**. Delegated realm permissions must **not** be assumed to give a liege or subject access to another ruler’s personal Gold. Future realm treasury, taxation, spending authority, investment authority, and obligations must be **explicitly designed** if they exist.

### Compatibility with future war

Future warfare may alter hierarchy rather than removing defeated players (for example a defeated independent ruler potentially becoming subordinate to the victor). **Exact war mechanics and outcomes are unspecified and not authorized for implementation.** This only preserves compatibility with the broader vision.

## Subordination Is Gameplay, Not Elimination

**Core principle.** Being conquered or becoming another player’s subject does **not** automatically remove a player from the match.

A formerly independent ruler may continue as a subordinate ruler.

Example: King Robert loses a war to Emperor Aldric. Robert may become Duke Robert, subject to Aldric’s realm. Robert remains an active player with territory, resources, political influence, relationships, military capability, potential subjects, and political goals.

This example illustrates **subordination remaining playable**. It does **not** define title-loss, demotion, revocation, usurpation, surrender, or war-outcome mechanics. Those remain unresolved.

A subordinate player may:

- Remain loyal and support their ruler
- Gain political influence
- Expand within the realm
- Participate in realm wars
- Form political coalitions
- Seek greater autonomy
- Rebel
- Pursue independence
- Attempt to replace their ruler
- Potentially become the ruler themselves

Being a powerful subordinate should be a **viable and interesting** way to play.

## Character & Dynasty Simulation

Characters remain important in a multiplayer-focused game.

Players may:

- Establish dynasties/houses
- Marry
- Produce heirs
- Form family relationships
- Inherit political positions or territory
- Experience succession
- Build dynasty prestige/influence

NPC characters may support the simulation where humans cannot reasonably fill every role. NPCs may potentially serve as spouses, children, heirs, courtiers, advisors, religious figures, or other supporting characters.

**Human players remain the primary drivers of major geopolitical decisions.**

Detailed large-dynasty simulation and advanced AI rulers are not authorized for immediate implementation (see Explicitly Deferred Features).

The first meaningful **gameplay prototype** (Political Hierarchy V0.1) is **accepted / complete**. It must **not** expand into a deep autonomous character simulation. Territory / Map Foundation V0.1 is **accepted / complete**. Diplomacy V0.1 is **accepted / complete**. Warfare / Conquest V0.1 is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**. This accepts **Warfare V0.1 only**; it is not a complete military simulation. **Economy / Resources V0.1** is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 Gold foundation only; not a finished economy). **Military / Armies V0.1** is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope only). Normal wars resolve through Military battle feeding Warfare attacker/defender application. `resolvewar` remains privileged.

### Development verification vs first real playtest

Studio Play Solo, Local Server synthetic-client sessions, MCP sessions, isolated regression testing, and Director acceptance checks are **development verification / acceptance testing**. They are **not** this project’s first real playtest.

The **first real playtest** is: a **published Roblox server**; the Director plus friends / actual human players joining normally; **one completed map** (multiple maps are not required); GUI sufficiently polished and intentionally laid out; core backend systems implemented and integrated; a coherent playable match loop of about **30 minutes** from beginning through conclusion; a winner that can actually be determined. The build should feel like a playable game rather than a collection of development/debug prototypes. The Director may still use a **simple single published map/server** for that first playtest.

Do not call Studio verification “the playtest.”

**V0.5 playtest stage (product direction).** Around **V0.5** the project intends a first **serious** playtesting phase with real players (multiplayer/emergent bugs, pacing, balance, UX friction). That stage uses `AI/PLAYTEST_BACKLOG.md`. It does **not** replace the published-server **first real playtest** definition above, and it is **not** a claim that half of all possible features exist at V0.5. Cumbersome remaining multiplayer tests may be deferred as non-blocking until that stage; **deferred is not PASS.** V0.1–V0.4: build/integrate (**ugly is acceptable; confusing is not**). V0.5–V0.9: iterate from playtest feedback. V1.0: release-target polish/onboarding. Pacing: **the timer should pressure indecision, not punish normal thinking.**

### Player communications (PRE-V0.5 REQUIRED — IMPLEMENTED — NOT DIRECTOR-ACCEPTED)

A **usable player text-communication system** must exist **before** the serious V0.5 multiplayer playtesting milestone so players can negotiate, coordinate, threaten, cooperate, betray, and conduct politics in-game. **Status: PRE-V0.5 REQUIRED — IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Director authorized recommendation B replacement on 2026-10-09, superseding the earlier design-only restriction. Direct personal-territory adjacency was clarified by Director; intended product scope remains frozen. Implementation evidence and limits: `AI/COMMUNICATIONS_IMPLEMENTATION.md`. This is **not** a Military / Armies V0.1 blocker, **not** a current gameplay regression, **not** a current critical defect, and does not change existing Military backlog status. Actual remaining Communications verification is recorded in `AI/PLAYTEST_BACKLOG.md`. Distinct from deferred gameplay **Council systems**.

**Historical name:** player-facing **General** / General/Public is **retired**. The replacement public-political path is **Diplomatic**.

#### Ordinary player paths (frozen)

Four ordinary paths, plus a separate administrative system (not an ordinary player channel).

**1. DIPLOMATIC** — Public political communication with geographically nearby realms. **Not** a global server-wide room and **not** a conventional room with fixed membership. Eligibility uses the **authoritative realm-adjacency graph**. A Diplomatic message reaches rulers at **realm-graph distance ≤ 2 from the sender**. Example: Red—Blue—Green: Red reaches Blue and Green. Red—Blue—Green—Yellow: Red reaches Blue and Green, **not** Yellow; Green reaches Red, Blue, and Yellow. Conversations may be **intentionally asymmetric**; a player may receive a reply to a conversation whose earlier message they never received. Do **not** repair, backfill, synchronize, or eliminate that asymmetry (desired emergent information gameplay). Recipient eligibility is calculated from authoritative political/territorial state **at the moment the message is sent**. Already delivered messages are **not** retroactively removed if borders/ownership later change; future messages use the new graph. Players may disclose or lie about strategy. The game must **not** censor numbers, troop claims, strategic words, or player-chosen intelligence. Protected information is what the **game system** automatically exposes, not what humans type.

**2. COUNCIL** — Private **direct-liege** feudal communication (not realm-wide, not recursive). A ruler’s Council is **that ruler + that ruler’s direct subjects only**. Example: Emperor A → King B → Duke C → Lord D: A’s Council = A+B; B’s Council = B+C; C’s Council = C+D. A ruler may participate **upward** as someone’s direct subject and simultaneously have a **separate downward** Council with their own direct subjects. **Geographic distance does not restrict Council.** Information may travel the feudal chain or other permitted paths. Distinct from deferred gameplay Council systems.

**3. ALLIES** — Private allied coordination. **Alliance only.** **NAP does not grant access.** Subjects do **not** inherit their liege’s Allies access. Only the rulers who are actual parties to **that specific Alliance** participate. Each distinct Alliance relationship is **compartmentalized**. Example: A allied with X and separately with Z → A–X and A–Z are separate contexts; X must not automatically see A–Z; Z must not automatically see A–X. Do **not** merge every ally into one giant Allies room. **Geographic distance does not restrict Allies.**

**4. DIRECT** — Private 1:1 political communication. Exactly two players. **Relationship-independent** (liege, subject, ally, enemy, or unrelated). **Normal Direct requires current personal-territory adjacency (Director clarification 2026-10-09):** sender and recipient must be two different players/rulers, and at least one territory **directly/personally owned** by one must border at least one territory **directly/personally owned** by the other. Do **not** compute Direct from greater-realm/root graph distance or include subject holdings in a liege’s personal holdings. This rule applies identically to liege/subject, fellow subjects, allies, enemies, NAP partners and unrelated rulers. Sharing a greater-realm root alone does **not** grant Direct. A liege and subject whose personal holdings touch may have both Council and Direct; if their personal holdings do not touch, their hierarchy-based path is Council. This clarifies existing relationship-independent Direct intent, not additional scope. If they do not currently share a border, normal Direct is unavailable. **Existing contact does not create a permanent line.** If two rulers have a Direct conversation and then stop sharing a border, **send access is cut immediately** (no grandfathering). Previously delivered Direct messages may remain visible for the **match**, but neither side may send further **normal** Direct messages while adjacency is broken. If adjacency is restored, normal Direct may become available again. Direct is **match-scoped**; no cross-session/DataStore Direct history for Communications V0.x. If a participant leaves, that participant is unavailable. **Roblox/platform direct-chat eligibility must be obeyed**; never bypass safety/eligibility.

#### Admin / Observer (frozen information requirement; not ordinary play)

Authorized administrators need **relationship-aware observation** of relevant in-game communication (Diplomatic, Council, Allies, Direct, and future supported types) for moderation/debug. Presentation must make clear **who** is talking, **where** the conversation exists, and the political relationship/context. Admins are **politically neutral observers** for this purpose: do **not** apply ordinary viewer-relative tags ambiguously. Show **explicit context** (conceptual examples: `[Direct: Player2 ↔ Player4]` / `[Liege ↔ Subject]` / `[King] Player2:` …; `[Alliance: Player1 ↔ Player3]` / `[Emperor] Player1:` …). Exact formatting/colors are **not** frozen; the information requirement **is**. Observer presentation must support **mute/silence** so a large server does not overwhelm an administrator. Muting the observer view must **not** stop underlying player communication. Direct is private from ordinary players, **not** from authorized game moderation or Roblox/platform moderation.

**Admin announcements (direction, not frozen UX):** authorized administrators should eventually have an explicit announcement capability (conceptual: `[ADMIN] The server will restart in 10 minutes.`). Admin/system communication must be unmistakably administrative. Admins must **not** casually masquerade as normal participants inside someone else’s Council, Alliance, or Direct conversation. If later intervention into a conversation is ever permitted, it must be visibly ADMIN/SYSTEM. Exact announcement command/UX is **not** frozen. Do not implement yet.

#### Dynamic chat identity (frozen baseline)

Every ordinary player message must display the speaker’s **current authoritative Title** (example: `[King] Player2`). Title is live; do **not** permanently cache it as stale metadata. Rank changes apply to **future** messages. In appropriate contexts, messages may additionally display **one** viewer-relative political relationship tag. Frozen baseline priority: **Liege / Subject**, then **Ally**, then **none**. No tag spam. **No territory-count tags** in Communications V0.x. The same underlying message may render different relationship context for different viewers. Identity comes from authoritative game state, not client claims.

- **Diplomatic:** `[Title] [viewer-relative relationship if useful] PlayerName` (examples: `[King] [Liege] Player2`, `[King] [Subject] Player2`, `[King] [Ally] Player2`, `[King] Player2`).
- **Council:** `[Title] PlayerName` only. Do not add “Council Member.”
- **Allies:** `[Title] PlayerName` only. Do not add “Ally.”
- **Direct:** `[Title] [viewer-relative Liege/Subject/Ally if applicable] PlayerName`.

System/channel-help messages are **not** ordinary player messages and do **not** receive Title/relationship tags.

#### Channel help (frozen intent; copy polish later)

Every communication context must clearly explain itself. When a player first enters/opens a context, show a clearly identifiable **SYSTEM** informational message for **that** channel only. Director does **not** want one giant Help dump of every channel. Players need a **harmless player-level** way to re-display the current channel’s explanation. Conceptual command: `help` (possibly via Kohl if it can expose a player-level command **without** admin privileges). Exact Kohl syntax is **not** frozen; audit Kohl during implementation. Intended meaning (final copy may be polished later without changing mechanics):

- Diplomatic: Public political communication with nearby realms. Messages reach rulers within realm-graph distance 2. Audience may differ between rulers.
- Council: Private communication between a ruler and their direct subjects. Geographic distance does not restrict Council communication.
- Allies: Private communication between the rulers participating in this specific Alliance. Subjects and NAP partners do not receive these messages.
- Direct: Private 1:1 communication with a neighboring ruler. Realms must currently share a border for normal communication.

#### Roblox architecture (frozen direction; API audit before implementation)

Use **Roblox TextChatService** as the underlying Communications infrastructure. Prefer extending/customizing Roblox’s native chat. Roblox continues to handle required text filtering/moderation. The game layers political rules, identity, channels, visibility, and presentation on top. Do **not** build an entirely separate custom chat frontend unless frozen requirements cannot be cleanly represented through currently supported TextChatService/native chat capabilities. Before implementation, audit current TextChatService APIs. Previously identified **candidates** (not an order to use a specific callback without audit): custom TextChannels; conditional delivery; TextChatMessageProperties / PrefixText; configurable native chat window/input; CanUsersDirectChatAsync or current equivalent; a custom frontend backed by TextChatService only if absolutely required.

#### Intelligence / espionage boundary (frozen)

Espionage/information-control governs what **the game system** reveals. It does **not** police voluntary human speech. Players may type true or false troop claims; the game must not try to verify them. Do **not** implement naive keyword filtering, number censorship, or strategic-word censorship. Military hidden commitment remains protected from **automatic/system** disclosure per Military / Armies V0.1.

#### Future long-distance / espionage communication (undesigned)

Document only. Do **not** implement or design mechanics now. Room is reserved for a future advanced system where espionage, messengers, diplomatic infrastructure, Gold, or similar could potentially permit communication **beyond** normal geographic range. Possible future concept (not locked): normal Direct = free/ordinary but requires adjacency; advanced long-distance = potentially expensive and distance-sensitive; espionage may interact. Exact mechanics, costs, interception, detection, distance formulas, and permissions are **not** designed. Do not invent them.

**Required before V0.5 serious playtesting:** usable player text communication covering the frozen Diplomatic, Council, Allies, and Direct paths; dynamic current-title identity; frozen viewer-relative baseline above; Roblox-required moderation/text filtering; enough function for real multiplayer politics; Admin/Observer information requirement (implementation of observer/announcements may follow ordinary paths). **Not necessarily required before V0.5:** complete espionage or interception; long-distance paid communication; polished chat UI; V1.0 onboarding; every future political tag; territory-count tags; advanced history/search; the future Hierarchy/Diplomacy layout idea below.

**Still unresolved (do not invent):** exact native TextChatService UI/channel-selection UX; how players initiate/select a Direct conversation; Council selector UX when a player has upward and downward Councils; Alliance selector UX with multiple distinct alliances; exact visual formatting/colors/brackets; exact player-level contextual help command integration with Kohl; exact Admin observer UI/presentation; exact Admin announcement command/UX; long-distance/espionage communication mechanics; interception/detection; message history/search beyond ordinary match-scoped chat; load/stress behavior; final acceptance test matrix.

Do not implement Communications until the Director authorizes an **implementation** pass (this freeze is design documentation only).

**Related future UI idea (not Communications V0.x; do not implement now):** Tab could eventually toggle the Hierarchy interface in place of the normal leaderboard/player-list role; Diplomacy could eventually move into/over the map-side interface similarly to Military, freeing more permanent map space. Recorded only.

### Public product match entry (future — not current work)

Before the game is a **normal public product**, players will need a proper match-entry flow. Conceptual requirements (not designed in detail, **not** required for Military / Armies V0.1, **not** required for the first published playtest): lobby / hub or menu; select an available playing world / map as appropriate; join or queue for a match; matchmaking / queue population; players enter the selected match/server; the match starts when required conditions are met. Do **not** implement matchmaking, a queue service, a lobby, a world selector, or a multi-map server browser unless the Director later authorizes that work.

### Required before first published playtest (not current work)

These are **locked requirements**, not authorization to implement them now unless the Director says otherwise. They are **required usability**, not optional decoration.

**Player/map orientation.** A player should never have to guess where they are on the political map. Provide persistent but restrained identification of the player’s own land; a clear relationship between the player/ruler and their realm color; explicit holder/owner information in TerritoryInfo; a convenient center-on / show-my-realm action or equivalent; likely a temporary highlight of the player’s realm. Greater-realm visualization should eventually distinguish personally held **territory** from subject/vassal-held **territory** while still making the total greater realm understandable. Exact keybind and art treatment are **not locked**. Do not assign a key arbitrarily.

**Admin copy/reuse UX.** Make the administrator’s job as easy as practically possible. When admin/debug UI exposes identifiers an administrator may reasonably reuse (war IDs, request IDs, ruler IDs, territory IDs, session IDs, coordinates, debug values), provide a convenient in-game copy/reuse action when technically possible. Example future presentation: Copy War ID / Attacker Victory / Defender Victory. The Kohl command interface remains available. A polished admin dashboard is **not** part of accepted Warfare V0.1; do not build it unless the Director authorizes pre-playtest admin UX.

**Player-relevant information** is already a standing rule (Warfare ordinary GUI implemented). Coherent GUI layout and major-interaction clarity also belong in this pre-playtest bucket.

**Terminology.** **Territory** means land / province / map holding. **Title** means political rank (Lord, Duke, King, Emperor). Do not interchange them.

## Admin / Testing Infrastructure V0.1

Director-approved **tooling architecture**, not a gameplay system. **Kohl's Admin** is the command/auth presentation layer only. It is **not** gameplay authority.

Custom testing commands must go: Kohl (or Studio debug) → project **Admin Bridge** → existing authoritative service APIs → normal replication. The admin layer must never become an alternative source of truth. Gameplay services must not depend on Kohl's Admin.

**GameTester** access is server-enforced by `AdminConfig.IsGameTester`: an explicitly authorized UserId OR a trusted effective Kohl rank of **SuperAdmin or higher** (Director ruling, 2026-10-10). The existing owner `106676397` remains allowlisted; additions are `2646795710` (ffrjfss), `701857` (coolguy2323), `470733` (iceboy10), and `555636491` (nooblyklll). Lower ranks and ordinary players remain denied unless explicitly allowlisted. Never trust client-supplied admin status, ruler identity, or mutations. Do not expose arbitrary code execution or generic “set anything” remotes.

**V0.1 status:** architecture recorded. Official Kohl's Admin (@Scripth, asset 172732271) is installed under `ServerScriptService`. Live GameTester commands (`adminhelp`, `inspectwars`, `inspectterritory`, `inspectruler`, `setowner`, `setprestige`, `inspectgold`, `setgold`, `addgold`, `spendgold`, `resolvewar`) go through `AdminKohlAddon` → `AdminBridge`. Command feedback uses project ResultToast / compact inspect overlay; Kohl chrome is restyled from PrototypeGuiTheme after load. Kohl SuperAdmin+ now qualifies through the central server gate; lower ranks do not. Studio `AdminDebug.Invoke` and per-system `*Debug` folders remain. **Studio-only:** synthetic Local Server UserIds `< 0` may pass `AdminConfig.IsGameTester` while `RunService:IsStudio()` is true; they are not production allowlist entries. Do not treat this tooling as a complete/polished admin product.

**Future systems:** when a new server-authoritative gameplay system is implemented, consider exposing Director/testing operations through the Admin Bridge after the system's own APIs exist. Do not implement deferred gameplay (armies, buildings, taxation, etc.) as fake admin commands. **Economy / Resources V0.1** Gold APIs go through AdminBridge (`;inspectgold` `;setgold` `;addgold` `;spendgold`). Owner/ruler Kohl tokens use addon types `adminOwnerToken` / `adminRulerToken` (raw parse; suggestions are not authority).

## Character Traits & Attributes

Characters may possess traits and attributes. Detailed trait/attribute mechanics are **unspecified** and must be designed by directors before implementation.

## Titles & Territory

The primary world representation is a **GUI-first 2D interactive political map**. It is the primary strategic game board, not a decorative background. Long-term it should occupy the central portion of the interface.

The long-term map should be capable of supporting concepts such as panning, zooming, territory selection, highlighting, political ownership visualization, realm visualization, contextual information, and different informational/map modes where appropriate. Players should eventually interact with individual territories and navigate political information through the map.

**Territory / Map Foundation V0.1** (below) is **accepted / complete**. **Title Progression V0.1** (below) specifies sequential landed-rank establishment with Vale test thresholds; it is **accepted / complete**. Lobby/map voting and additional maps remain unresolved.

There is no requirement for a traditional explorable 3D Roblox world.

Approved landed ranks are **Lord → Duke → King → Emperor**. Each normal starting player is an Independent Lord with **one** starting territory.

### Multiple maps and stable geography

The long-term game should support **multiple selectable fictional maps**. A future lobby/match-selection flow may allow players to choose or vote between maps. Approximately five maps has been discussed; **five is not a locked production requirement**.

Each map may have a different number, arrangement, and shape of territories. Territory counts need not match across maps. Political systems must **not** assume every map has the same number of territories.

Maps are **not** selected or scaled by human player count. Do not use concepts such as RecommendedPlayers as a foundation for map or title progression. The selected map keeps its intended geography regardless of current human population. Title progression and political scaling must **not** fundamentally depend on how many humans are in the match.

Each designed map has recognizable geography. Territories have **stable geographic identities and names** for that map (illustrative only, not final names: Blackmere, Northwatch, Ravenford, Eastvale, Stormrest). If a territory is named Blackmere, it remains Blackmere for the match. Ownership, realm membership, rulers, and titles may change; **geographic identity does not**.

**Geography and political realms are separate.** A territory’s geographic name is not the political realm controlling it. Example: the Duchy of Blackmere may comprise Blackmere, Ravenford, Eastvale, and Stormrest. Blackmere stays a geographic territory; “Duchy of Blackmere” is a political entity layered over geography. Multiple duchies may exist inside a kingdom, and multiple kingdom-level structures inside an empire. Political organization must not overwrite geographic identities.

Lobby/map voting, additional production maps, and exact layouts of maps other than the V0.1 test map remain unresolved. The V0.1 test map’s territory count (**16**) is locked for that prototype only and is **not** a universal count for future maps.

### Territory / Map Foundation V0.1

Specified design checkpoint. **Accepted / complete** as a limited prototype. Do not expand V0.1 into warfare, claiming, AI, or additional maps without a new authorization.

A **Territory** is the smallest ownable geographic unit. It cannot be subdivided. Each territory has a stable identity from its map: ID, display name, polygon geometry, adjacent territory IDs, and any future static geographic metadata. Geography and names do not change during a match. Ownership is **match state**, not map-definition state. Do not hardcode ownership into geometry or map configuration.

Maps are **hand-authored presets**, not generated each match. The eventual game may offer multiple selectable maps with different territory counts, shapes, names, adjacency, and layouts. The same map can produce different political histories because ownership and realm state are dynamic. Do not add recommended-player-count as a required map concept. AI may later fill political gaps; **AI is not part of Territory / Map V0.1**.

V0.1 uses **exactly one test map** with **16 territories** (prototype/testing only). Visual direction: stylized **irregular polygons** between CK3-style provinces and Civilization hexes. **Do not use a hex grid.** Realistic geography is not required. Exact prototype continent layout and fictional names are implementation/content discretion (illustrative style only: Westmere, Northvale, Greyfen, Highmarch). **The territory name belongs to the territory/map, not its ruler.** Ownership change does not rename the land.

Every human Independent Lord begins with **exactly one** starting territory. V0.1 assignment is **automatic, random, unique**, and based on humans who actually join. There are no permanently designated Player1/Player2 territories (those names are Studio test identities only). Conceptually: player joins → ruler exists → server selects an available starting territory → that ruler owns it. Lobby/map-start location choice is **not** V0.1.

Territories not assigned to a human remain **Unclaimed**. No NPC rulers and no AI occupy unused land. With 16 territories, practical prototype capacity is 16 simultaneous starting human rulers. Behavior when a 17th ruler joins and no starting territory remains is **unresolved — do not invent it**.

If a human leaves and Political Hierarchy V0.1 removes their runtime ruler, **their directly owned territory becomes Unclaimed**. No AI replacement, reconnection restoration, or succession in this checkpoint.

Unclaimed territories use a **neutral gray** prototype look. They stay fully selectable; Unclaimed does not mean disabled. Owned realms use an automatic curated distinguishable palette; humans do not pick colors in V0.1. Do not design monetization around realm colors here.

**Ownership is not hierarchy membership.** A vassal keeps direct ownership of their territory while visually belonging to the greater independent realm (root ruler). Dominant fill = greater realm; a secondary indicator (for example a thinner internal border) may keep the direct holder’s color. Exact rendering technique is implementation discretion. Map visuals **derive from** authoritative hierarchy state; do not change Political Hierarchy rules to fake this.

Every territory is selectable, including unclaimed. Selection opens a simple information panel only: territory name, territory ID, owner, owner rank, independent/subject status, greater realm/root ruler. Unclaimed must read as Unclaimed. Territory / Map Foundation V0.1 must **not** add economy, gold, military, religion, development, claims, war actions, buildings, or population to that panel. Architect the panel so later systems can extend it. **Economy / Resources V0.1** uses a **separate** minimal player Gold UI, not a province-income breakdown in TerritoryInfo. There is **no Claim/Conquer** action in Territory / Map Foundation V0.1. Player conquest of enemy-held **territory**, when using Warfare / Conquest V0.1, uses this map’s existing authoritative ownership path. Economy V0.1 **reads** that ownership for income; it must not become a second ownership model.

Desktop V0.1 navigation: click-and-drag pan, mouse-wheel zoom, click to select. Bounded strategy-map camera: no infinite pan away from the map; reasonable min/max zoom; pan constrained to map bounds; initial view frames the entire 16-territory test map. **“Focus my realm” is not Territory / Map Foundation V0.1.** Player/map orientation (center-on / show-my-realm or equivalent) is **required before the first published playtest**; do not implement or bind a key unless the Director authorizes it.

**Adjacency** is static map definition from the start (each territory lists neighboring IDs) and is **MapConfiguration truth**, not runtime distance. Territory / Map Foundation V0.1 stores adjacency; it does not itself declare or resolve wars. **Warfare / Conquest V0.1** queries that adjacency plus greater-realm membership for declaration validation.

**Vale prototype adjacency (director-corrected, later director-verified).** On the current 4×4 Vale lattice, a territory is adjacent to every **immediate** neighboring cell that shares an **edge or a corner** (8-neighbor). Interior cells may have up to 8 neighbors; edge non-corners up to 5; corners up to 3. Two cells away is not adjacent. Other maps author their own graphs; do not assume every future map is 8-neighbor. Do not infer adjacency from visual proximity.

Territory / Map Foundation V0.1 includes **no** conquest, war, armies, claims, occupation, annexation, claiming unclaimed land, trading, gifting, or purchase of territory. Ownership changes beyond initial assignment and disconnect may use **server-only debug helpers** for verification, not player gameplay. Successful attacker victory under Warfare / Conquest V0.1 uses this map’s existing authoritative ownership path.

Authority: server owns ownership, starting assignment, territory-to-ruler links, and mutable match map state. Client renders, pans/zooms, selects, displays authoritative info, and may later send intents. Prefer calculate-on-change. Do not recompute political state every frame without reason.

The renderer must be **map-agnostic**: drive from the currently selected `MapConfiguration`, not “the 16-territory map.” Future maps must change counts/geometry without rewriting political systems. This preserves `TitleRequirements = f(MapConfiguration)`.

### Title Progression V0.1

Specified design checkpoint, now **implemented as a baseline prototype** and **accepted / complete** after director Local Server + 2 Players verification. Do not reopen Political Hierarchy V0.1 or Territory / Map Foundation V0.1 to invent title-loss, auto-promotion, or rank skipping.

Purpose: prove a ruler can qualify for the **next** landed rank from greater-realm control plus a Prestige threshold, **manually establish** that title, receive the new rank **server-authoritatively**, and have hierarchy/map UI reflect it. Baseline prototype only. Not title-law, succession, claims, ceremonies, revocation, or realm administration.

**Sequential only:** Lord → Duke → King → Emperor. A ruler may establish only the next rank above their current rank. A Lord may not skip to King or Emperor even if debug values exceed those requirements. Emperor has no higher landed rank in V0.1.

**Vale prototype test thresholds** (for the 16-territory Vale map only; **not** universal final balance; **not** “all maps always use 2 / 5 / 10”):

| Next rank | Greater-realm territory control | Prestige threshold |
| --- | --- | --- |
| Lord | Starting/default; no establishment | — |
| Duke | 2 | 100 |
| King | 5 | 250 |
| Emperor | 10 | 500 |

`TitleRequirements = f(MapConfiguration)`. Future maps may use different territory and Prestige numbers. Human player count is not part of the calculation. Deterministic per selected map, not random per match.

**Greater-realm control** counts every territory **directly owned** by rulers in that ruler’s subordinate hierarchy/tree (the ruler plus descendants). The qualifying ruler need not personally own all counted land. Example: King Bob with Duke Cody (Lords A and B) and Lord C, each holding one territory → Bob’s greater realm controls **5**. Derive this from authoritative Political Hierarchy + Territory ownership. Do **not** duplicate hierarchy trees inside a title system. Unclaimed land does not count. Establishing a title does **not** consume, unclaim, or reassign territory.

**Eligibility ≠ grant.** Qualification does not auto-promote. Flow: requirements met → eligible → GUI may show Establish Duchy / Kingdom / Empire → player chooses Establish → **server revalidates** (ruler exists, current rank, requested rank is the valid next rank, sequential rule, current greater-realm count, current Prestige, map requirement table, other already-approved V0.1 validity) → grant if still valid. Do not auto-promote because territory count, vassalage, or debug Prestige changed. Eligibility display may update; establishment requires the ruler’s action.

**Prestige in V0.1:** the real Prestige resource system is **not** part of this checkpoint. Title Progression V0.1 uses **temporary server-side test Prestige** only, to test qualification. Prestige is **checked** against the threshold and **not spent**. Example: 250 Prestige, King threshold 250, establish King → Prestige remains 250. Do not implement Prestige income, decay, spending, purchases, economy UI, rewards, or persistence here. Later server-only debug may set test Prestige; do not expose client Prestige mutation.

Gold and Influence are **not** establishment requirements.

**Server authority.** The client may show current/next title, realm control X / required, Prestige X / required, Eligible / Not eligible, and a disabled or unavailable Establish control when ineligible. The client must not be trusted to claim qualification, control count, Prestige, or “make me Emperor.”

**Established titles persist.** Dropping below the creation threshold does **not** auto-demote. A King established at 5 territories who later holds 3 remains King unless a **future explicitly designed** mechanic removes the title. V0.1 has **no** automatic demotion.

**Title loss remains unresolved — do not invent:** forced demotion, revocation, usurpation, destruction, conquest/rebellion/surrender loss, loss of all land, deposition, claimants.

**Rank vs realm name.** Landed rank is Lord / Duke / King / Emperor. A future political entity name (e.g. Duchy of Westmere) is separate. V0.1 proves rank progression. Full naming is not this checkpoint: default/deterministic display name is enough for UI/testing; custom names stay optional and must never block establishment; geography name ≠ political title. Do not build procedural naming as a separate system here.

**Hierarchy integration.** Use existing Political Hierarchy V0.1. Rank change does **not** automatically rewrite liege/vassal links or flatten trees. Existing vassals remain attached. An existing liege remains unless a **separately designed** future rule handles an impossible rank state. Do not invent automatic hierarchy restructuring. After a rank change, future vassalage validation should use the **new current rank**. Player-facing actions: Establish Duchy / Establish Kingdom / Establish Empire (or equivalent clear wording).

**Map integration.** Read greater-realm control from existing map/ownership state. Title progression must not own, create, reassign, or conquer territory, or alter adjacency/geometry. Map/hierarchy UI may later show the updated rank.

Do not implement a full Prestige economy, Gold, Influence, warfare, claims, AI, religion, succession, aging, dynasties, persistence, title laws, de jure, coronations, or extra rank tiers from this checkpoint.

### Title qualification and establishment (long-term)

Higher-title qualification **adapts to the selected map**. Do **not** permanently hardcode universal territory counts for every future map. Conceptually: `TitleRequirements = f(MapConfiguration)`. Vale V0.1 test numbers are locked for that prototype map only. Exact formula, percentages, rounding, and per-map tuning for **other** maps remain **unresolved**.

Formal rank and current practical power may **diverge** (a weakened Duke may hold less land or military strength than a powerful Lord). This is intentional.

### Realm naming

When establishing a Duchy, Kingdom, or Empire, the game should provide an automatic/default political realm name. The player may accept it without custom text. A player must **never** be blocked from establishing an earned title for lack of a custom name. Optional custom names must eventually use appropriate Roblox text filtering/moderation before display to others. Exact naming UI is unresolved.

Where runtime-generated names are useful, prefer lightweight procedural generation or curated naming data, **not** an external generative-AI service. Categories may eventually include political realms, dynasties/houses, characters, religions, and other fictional entities, possibly with different rules per category. The generator is not designed. **Stable geographic territory names** on designed maps stay separate from runtime-generated political names.

## Succession

Character death should **not** normally remove the player from the match. When appropriate, the player continues as an eligible heir.

Succession may alter titles, territory, relationships, political stability, realm hierarchy, claims, and alliances.

Because matches last ~30 minutes, aging, generations, and succession must be **substantially accelerated** versus realistic time.

Succession should create political opportunities and instability, not merely cosmetic character replacement.

Detailed succession mechanics are unspecified and are not authorized for immediate implementation.

## Relationships & Diplomacy

Players should be able to interact politically without warfare. Diplomacy should provide legitimate paths to power.

**Voluntary vassalage** remains a Political Hierarchy V0.1 action (both parties agree; rank rules). It is **not** Diplomacy V0.1. Diplomacy V0.1 is **external** formal agreements between independent greater realms.

Long-term design may later include marriage diplomacy, guarantees, tributaries, coalitions, opinion, trust, and similar. Those remain unspecified. Do not implement a full diplomacy system from the long-term list.

### Diplomacy V0.1

Specified design checkpoint. **Accepted / complete** after director Local Server multiplayer verification. Do not reopen Political Hierarchy V0.1, Territory / Map Foundation V0.1, Title Progression V0.1, or Diplomacy V0.1. Do not implement deferred military systems, economy, AI, relationships/opinion, or vassal diplomatic autonomy from this Diplomacy section.

**Purpose.** Authoritative political relationships **between independent greater realms**. It answers: which independent realms currently have formal diplomatic agreements with each other? Baseline infrastructure only. Not a complete diplomatic simulation.

**Actors.** External diplomacy is conducted only by **root / independent rulers**. The root represents the entire greater realm. Subjects **cannot** independently offer, accept, decline, or break those external agreements. A subject’s external diplomatic alignment follows their greater-realm root. **Vassal diplomatic autonomy is not V0.1.**

Example: independent King Bob may diplomatically engage independent Emperor Steve. Duke Cody, vassal of Bob, may not offer Alliance or NAP to Steve, accept or decline Steve’s external requests, or break Bob’s external agreements.

**Agreement types (exactly two):**

1. **Alliance**
2. **Non-Aggression Pact (NAP)**

Do not add guarantees, tributaries, trade agreements, marriages, defensive pacts, coalitions, federations, truces, favors/hooks, opinion, trust, diplomatic reputation, embassies, subject-negotiated diplomacy, or war participation.

**Alliance V0.1.** Mutual formal relationship between two independent greater realms. Flow: root A offers Alliance to root B → server pending request → B Accept or Decline → only successful server Accept creates the Alliance. Either root may later **unilaterally Break Alliance** (no consent). V0.1 meaning only: these two greater realms are formally allied. Diplomacy must **not** implement automatic military assistance, call to arms, shared wars, troop access, joint victory, defensive/offensive obligations, or Prestige/economic effects. **Warfare / Conquest V0.1** (implemented) **queries** Alliance state and does **not** auto-join allies to wars.

**Non-Aggression Pact V0.1.** Mutual formal relationship between two independent greater realms. Same offer → pending → Accept/Decline / expire flow. Either root may unilaterally **Break NAP**. V0.1 meaning only: these two greater realms currently have a formal non-aggression agreement. Diplomacy must **not** auto-break the pact, apply violation penalties, create truces, or alter reputation/Prestige. **Warfare / Conquest V0.1** (implemented) **queries** NAP via Diplomacy and **rejects war declaration** while the pact exists. The player must no longer have the blocking NAP before a valid declaration.

**Coexistence.** Alliance and NAP are **separate**. Two realms **may** have both at once. Do not make them mutually exclusive. Do not auto-create NAP on Alliance accept. Do not auto-remove NAP when an Alliance is created. Whether Alliance later implies non-aggression is unresolved.

**Server authority.** Diplomacy is server-authoritative. Clients submit intentions only (conceptually: OfferAlliance, OfferNAP, Accept, Decline, BreakAlliance, BreakNAP). The client must not submit authoritative relationship state, root status, agreement validity, hierarchy membership, or expiration truth. The server revalidates.

**Root validation.** Actions succeed only if the relevant actors are currently independent/root. Hierarchy remains authoritative for liege, vassals, root, and greater-realm membership. Diplomacy **consumes** that truth. Diplomacy must **not** duplicate or independently maintain the hierarchy tree.

**Requests.** Creation uses a pending-request model in the same spirit as Vassalage: Offer → Pending → Accept / Decline / Expire. Only successful server Accept creates the agreement. A pending request identifies at least: request ID, agreement type, sender root, receiver root, expiration. Exact structures are implementation detail.

**Lifetime.** Pending diplomatic requests last **30 seconds** (existing prototype convention). After expiration the request is invalid; Accept cannot establish; Decline cannot act on a nonexistent request. No configurable diplomacy clocks in V0.1.

**Duplicates.** Reject self-diplomacy; duplicate active Alliance; duplicate active NAP; duplicate **pending** request of the **same** agreement type between the same two realms. The pair is **unordered** for duplicates (A→B Alliance pending blocks B→A Alliance pending). Alliance pending does **not** block NAP pending. No rate limits or cooldowns in V0.1.

**Breaking.** Break Alliance removes Alliance only. Break NAP removes NAP only. Breaking one does not remove the other. No consent. Both sides receive authoritative feedback. **No V0.1 penalty.**

**Loss of independence (locked).** If an independent ruler who holds external agreements later becomes a vassal/subject, **that ruler’s independent external agreements are dissolved**. They are **not** transferred to the new liege. Pending external requests involving the ruler who loses independence become invalid. No vassal diplomatic inheritance.

Example: Cody ↔ Steve Alliance; Cody later becomes Bob’s vassal → Cody ↔ Steve Alliance dissolves; Bob does **not** inherit an Alliance with Steve (Bob never agreed).

**Disconnect.** Temporary match state. If a ruler is removed: their active agreements and pending requests are removed/invalidated; remaining rulers receive updated state. No reconnect restoration, AI takeover, persistence, succession, or diplomatic inheritance.

**Identity.** Agreements belong to the two participating independent greater-realm actors. They are not territory relationships, title objects, player-friendship, or account-level relationships. For the current baseline, player = match ruler; independent roots are the diplomatic actors.

**Queryability.** Authoritative systems may ask equivalents of `AreAllied(rulerA, rulerB)` and `HasNonAggressionPact(rulerA, rulerB)` (exact names are implementation detail). **Warfare / Conquest V0.1** (implemented) **consumes** that diplomatic state. Diplomacy V0.1 must **not** implement warfare.

**No map effect.** Diplomacy does not change ownership, realm colors, holder colors, adjacency, starting territories, or map geometry. Do not recolor allied realms the same color. Diplomatic map modes are deferred.

**No title effect.** Diplomacy does not change rank, title eligibility, greater-realm territory count, Prestige, or Establish requirements.

**GUI.** Respect current prototype UI: `PrototypeGuiTheme`; map as primary workspace; no uncontrolled permanent stacking; stable assigned regions; higher GUI blocks map input beneath it; priority requests use an overlay/action surface; results use toasts; no state-driven primary-panel geometry. Do **not** assign keybinds. Future UI shell remains specified, not implemented. Exact player-facing copy is not locked; both participants should get clear feedback for offer/accept/decline/break/expire and dissolution on loss of independence.

**Explicitly deferred from Diplomacy V0.1:** warfare and war participation; call to arms; military access; peace/truces/casus belli/claims; coalitions; guarantees; tributaries; trade/economy/diplomatic currency; opinion/trust/favors/hooks/reputation; vassal diplomatic autonomy; diplomatic inheritance; AI diplomacy; marriages/dynasties/succession; persistence/reconnect; diplomatic map modes.

## Realm & Vassal Management

Vassalage, realm formation, and recursive subject relationships are foundational (see Political Hierarchy V0.1). Large realms should create internal political gameplay. Powerful subjects should matter.

A large empire should potentially be powerful externally while politically unstable internally.

When a ruler’s liege relationship changes (joining or leaving a greater realm), existing subordinate trees stay attached; internal hierarchy is not flattened. Vassal **obligations** (tax, military contribution, and similar) are **not specified**. Exact remaining realm-administration mechanics remain unspecified until designed.

## Schemes & Politics (Internal Politics)

Future systems may include:

- Political factions
- Independence movements
- Rival claimants
- Realm demands
- Loyalty
- Political influence
- Rebellions
- Leadership challenges

Complex factions, schemes, and assassination are **not** authorized for immediate implementation.

## Warfare

War is important and must stay compatible with GUI-first design.

The game does **not** require 3D player-controlled armies. Long-term military conflict can be represented through strategic interfaces, territory state, armies as data, commanders, combat calculations, progress, and visual feedback.

War should have clear political objectives. Losing a war does **not** necessarily mean elimination. Conquest must **not necessarily** eliminate players. Hierarchy-changing war outcomes (forced vassalage, independence, political concessions) remain unspecified beyond Warfare / Conquest V0.1.

### Warfare / Conquest V0.1

Specified design checkpoint. **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Warfare V0.1 only** (independent-root external wars, one enemy-controlled **territory**, debug resolution, player-relevant ordinary GUI). It does **not** mean warfare is feature-complete for the final game. **Military / Armies V0.1** later **supersedes** same-target multiplicity (see below and Military / Armies V0.1). Do not reopen Political Hierarchy V0.1, Territory / Map Foundation V0.1, Title Progression V0.1, Diplomacy V0.1, or Economy V0.1 Gold. Future military systems must **build on** this V0.1 war-lifecycle authority, not replace or duplicate it without an explicit architecture decision.

**Purpose.** Minimum server-authoritative warfare primitive to prove that independent greater realms can declare external wars, target one enemy-controlled territory, validate borders through existing greater-realm territory, coexist in multiple simultaneous wars, resolve wars through a **server-only debug** mechanism, and transfer territory after a valid attacker victory. Infrastructure testing only. Not a military simulation.

**Actors.** Only an **independent root ruler** may declare an external war. Subjects / vassals do **not** independently declare external wars. A subject participates politically as part of the greater realm of their root. Hierarchy remains the source of truth for independence, liege/vassal, root, and greater-realm membership. Warfare **must not** duplicate the political hierarchy tree.

Example: independent King Bob; Duke Cody is Bob’s subject and owns a border territory next to Emperor Steve. Bob may declare the external war against Steve using that greater-realm border. Cody may not independently declare that external war.

**War target.** Every war targets **one** specific enemy-controlled territory. A declaration must identify the contested territory. The target must currently be controlled by **another** greater realm, must **not** belong to the attacker’s own greater realm, must **not** be Unclaimed, must satisfy greater-realm adjacency, and must otherwise pass server validation. Warfare V0.1 **cannot** claim Unclaimed territory. Unclaimed expansion was deferred in the accepted V0.1 baseline; the explicitly authorized Unclaimed conquest V0.x addition below supersedes that restriction for neutral militia conquest only.

**Greater-realm adjacency.** Adjacency is evaluated using the **entire attacking greater realm**. A target is eligible when it is MapConfiguration-adjacent to **any** territory controlled by **any** ruler in the attacking root’s greater realm (Vale: immediate edge or corner neighbor). The neighboring land need not be personally owned by the root. Territory / Map remains the source of truth for ownership, map adjacency, and territorial transfer. Hierarchy determines which rulers’ territories constitute the greater realm.

Example: Bob personally owns Westmere; vassal Cody owns Northvale; Northvale borders Steve’s Greyfen. Bob’s greater realm borders Greyfen; Bob may declare war for Greyfen; Cody may not independently declare it.

**Declaration.** War declarations are **not** requests. There is no Accept / Decline flow. If the server validates the declaration, the war begins immediately. The defender does not consent. The server owns all authoritative war state. The client sends `DeclareWar` **intent** only.

**NAP.** An active Non-Aggression Pact between attacking and defending greater realms **blocks declaration**. The server rejects the declaration while the NAP exists. Warfare V0.1 does **not** automatically break the NAP, apply a violation penalty, create a truce, or alter reputation/Prestige. Diplomacy remains the source of truth for NAP state.

**Alliance.** Alliance does **not** automatically join another realm’s war. No call to arms, allied armies, shared wars, military access, or automatic co-belligerents. Those are deferred. Diplomacy remains the source of truth for Alliance state.

**Multiple simultaneous wars.** A ruler / greater realm may participate in **multiple** active wars at once. There is no “one war at a time **per realm**” restriction. **Different territories** may be targeted by separate wars. A defender may declare a separate valid war in the opposite direction for a **different** eligible enemy-controlled bordering territory. There is **no** special counter-war mechanic. That second declaration uses the same validation rules. It is simply another war object.

**Multiple wars, same territory (Warfare V0.1 historical rule — SUPERSEDED).** Warfare / Conquest V0.1 originally allowed multiple active wars on the same target and forbade a one-active-war-per-territory restriction. That rule was **Director-accepted and Director-verified** (competing same-target wars + stale cleanup after first capture). **Military / Armies V0.1 intentionally supersedes it** (Director decision 2026-08-24). It is **not** a bugfix and is **not** permission to redesign Warfare generally.

**Current rule (Military / Armies V0.1 supersession).** A territory may be the target of **at most one** active war at a time. The first valid server-authorized declaration places that territory in a **CONTESTED** state for war-declaration eligibility. Later declarations targeting that same territory are **rejected** while it remains contested (concept: “Territory is already contested.”). No declaration queue. First valid declaration processed by the authoritative server wins the contest. When that war resolves or cancels under the final lifecycle rules, the territory enters the designed **10-second post-war territory cooldown** where applicable, then becomes normally attackable again. Simultaneous wars remain allowed only when they target **different** territories.

**Stale / invalid resolution.** Before applying a result, the server revalidates. If the target has left the **original defending greater realm** (for example admin/debug ownership change), the war is invalid/stale and terminates **without** transferring the territory. V0.1 does **not** retarget the new owner, automatically create a war against the new occupier, or model contested occupation, three-way wars, hostile third parties, continuation against a new occupier, war-score inheritance, or peace-conference claims. Competing same-target player wars are no longer created under the Military supersession; stale cleanup remains relevant for ownership changes while a single contest exists.

**Resolution.** Warfare / Conquest V0.1 itself has no player armies. Until Military / Armies V0.1 is implemented, active wars remain unresolved until **server-only debug** Attacker/Defender Victory (`DebugResolveWar`). That path is **not** ordinary player authority. After Military implementation, ordinary wars resolve through Military battle results feeding this same Attacker/Defender application path; `resolvewar` remains privileged and must **reject** after Military mechanical resolution (see Military / Armies V0.1).

**Attacker Victory.** The server must revalidate the war before changing ownership. If still valid: **target territory → direct ownership of the attacking root ruler**. Do not automatically distribute conquered land to vassals, neighboring subjects, title holders, previous owners, or AI administrators. Realm administration / conquered-land redistribution is deferred.

**Defender Victory.** The war ends; target ownership remains unchanged. No V0.1 reparations, Prestige, penalties, diplomatic truces, claims, or opinion. The **10-second post-war territory cooldown** is a Military / Armies V0.1 declaration-eligibility window, not a diplomatic truce.

**Disconnect.** If a participating **root ruler** disconnects, affected active wars involving that ruler are cancelled / terminated. No automatic victory. No territory transfer because of disconnect. No persistence, reconnect restoration, AI takeover, or succession handoff. **Director-verified** for both attacker-root and defender-root disconnect; remaining client sees cancellation; ordinary Territory UI shows no active wars; no stale active war remains.

**Loss of independence.** If a participating root loses independence and becomes somebody else’s subject during an active external war, affected wars involving that former root terminate. The war does **not** transfer to the new liege. The new liege does **not** inherit the war. No automatic territorial result merely because independence was lost. Same baseline philosophy as external Diplomacy V0.1. Advanced realm-war inheritance is deferred. **Director-verified.**

**Territory integration.** Warfare does **not** maintain a duplicate ownership model. Territory / Map remains authoritative. Successful conquest uses the existing ownership path. Economy V0.1 pays **future** Gold income to the new **direct owner**; it does **not** transfer the defeated ruler’s Gold treasury.

**Hierarchy integration.** Warfare consumes Hierarchy for root, independence, and greater-realm membership. Subjects contribute territory to greater-realm adjacency but do not gain independent external-war authority.

**Diplomacy integration.** Warfare queries existing Diplomacy. NAP blocks declaration. Alliance does not auto-join. Warfare does not duplicate Alliance/NAP state.

**Title integration.** Warfare does **not** directly grant rank, Prestige, promotion, or demotion. Successful conquest changes ownership; Title Progression may observe the new control counts through existing architecture. Warfare itself does not promote the ruler.

**GUI.** Respect current prototype UI: `PrototypeGuiTheme`; map as primary workspace; no uncontrolled permanent stacking; stable assigned regions; higher GUI blocks map input beneath it; toasts for results; no state-driven primary-panel geometry. Do **not** assign warfare keybinds. Declare War lives in `TerritoryInfo`. Ordinary player-facing war lists show only wars involving the local player’s **greater realm** (subjects inherit the root’s view). Unrelated third-party wars stay out of TerritoryInfo. Global war lists remain admin/debug (`;inspectwars`, WarfareDebug). Future UI shell remains specified, not implemented. Prototype “additional war” copy for two roots targeting the **same** territory is obsolete under the Military same-target supersession; additional wars may still exist for **different** territories.

**Director acceptance (2026-08-24).** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** Recorded PASS at acceptance time: valid adjacent declaration; non-adjacent rejection; duplicate/matching active-war rejection; attacker victory with target **territory** transfer; defender victory with ownership unchanged; **simultaneous competing wars on the same target territory** and **stale-war cleanup after another attacker captures the target** (those two PASSes are **historical Warfare V0.1 verification**; same-target multiplicity is **superseded** by Military / Armies V0.1); loss of independence during an active war terminates the war and the new liege does not inherit it; defender-root disconnect terminates the war without conquest; attacker-root disconnect terminates the war without conquest (most recent: Player1 attacker vs Player3 defender for frostfield; remaining client “War cancelled (left the match).”; ordinary Territory UI no active wars; no transfer); disconnect cleanup leaves no active stale war; ordinary Warfare GUI is player/realm-relevant; admin InspectWars remains global; AdminBridge ResolveWar uses `WarfareService.DebugResolveWar`.

**Explicitly deferred from Warfare / Conquest V0.1:** armies, units, troop counts, troop movement, battles, combat simulation, sieges, occupations, casualties, military economy, recruitment, reinforcement, supply, logistics, commanders, generals, army AI, claims, casus belli, war goals beyond the single target territory, war score, peace negotiations, peace treaties, surrender, reparations, truces, cooldowns, Prestige rewards/penalties, opinion/reputation, aggressive expansion, coalitions, call to arms, alliance war participation, military access, guarantees, tributaries, contested occupation, multi-party peace, automatic continuation against a new territory owner, vassal independent warfare, vassal war autonomy, conquered-territory redistribution, unclaimed-territory warfare, persistence, reconnect restoration, succession/inheritance of wars, AI warfare, advanced war GUI, warfare keybinds.

### Military / Armies V0.1 (IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED)

**Status.** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** for **ordinary V0.1 acceptance scope only**. Not a complete military game. Do not expand into V0.2. Agent verification is not Director verification. Eight MIL-MP overlay/race cases remain deferred in `AI/PLAYTEST_BACKLOG.md` (deferred ≠ PASS; not a V0.x progress blocker). Canonical 18-item PASS list: `AI/PROGRESS.md`.

**Why.** Replace debug-only war outcomes with a short military contest: Territory → Gold → Troops → War → Battle / Casualties → Conquest → more Territory → more Gold.

**Authorities.** Military owns Troops, commitments, battle calculation, and casualty application. Warfare owns war lifecycle, contest/cooldown eligibility, and Attacker/Defender outcome application (including revalidation). Territory owns ownership/geometry. Economy owns Gold (`TrySpend` for recruitment). Diplomacy remains NAP/Alliance truth. Hierarchy remains root/independence truth. Military must not `SetOwner` or create wars. Clients must not set Troops or battle results.

#### Troops

- Resource name **Troops**. **1 Troop = 1 soldier.** Whole numbers only. Finite. Casualties remove actual soldiers.
- Each ruler has **one personal pool**. Territory does **not** store Troops. Greater realms do **not** auto-pool. Alliance does **not** contribute.
- **Start:** **1,000** Troops per ruler (prototype balance, not final). Init on ruler create. On ruler **removal**, that ruler’s Troop state is destroyed (no transfer), like Gold.
- **Invariant:** Total = Available + Troops committed across all active wars.
- Subjecthood and title changes must **not** merge, confiscate, or transfer personal Troops. Landless-liege politics remain a **separate** unresolved hierarchy/title case.

#### Recruitment

- Instant. **1 Gold recruits 3 Troops.** Purchases must be **multiples of 3 Troops** (minimum 3 Troops / 1 Gold). No fractional Gold. Gold deduction **only** through `EconomyService.TrySpend`.
- Client requests an amount (example: Recruit 300). Server validates; client cannot grant Troops.
- **Max recruit (M):** compact Military-panel button immediately right of Recruit. Client sends a **RecruitMax** intent with **no Gold/Troop amount**. The server re-reads current Gold at processing time and recruits `CurrentGold × 3`. Does not require TextBox input. Manual Troops-entry Recruit remains. 0 Gold recruits nothing (`Insufficient Gold.`). Allowed during unlocked commitment (emergency Available troops). Never changes a locked commitment.
- Recruit **0**, non-multiples of 3, malformed/negative amounts: **reject** (not interaction, not a spend).
- Allowed while at war. New Troops enter **Available**. They may be committed only to a battle whose commitment is **not** locked. Recruitment never changes a locked commitment.

#### Wars, contest, cooldown

- **Same-target supersession** of Warfare V0.1 competing same-target wars: at most **one** active war per territory. First valid server declaration wins **CONTESTED**. Later same-target declarations rejected (concept: “Territory is already contested.”). No queue.
- Simultaneous wars remain allowed on **different** territories (strict Available accounting; overextension is intended).
- After the war **resolves or cancels**, the target enters a **10-second territory-only** post-war cooldown, then AVAILABLE. Not a diplomatic truce, not ruler immunity, not a global war cooldown. Other territories stay attackable. Recruitment stays allowed.
- Lifecycle: AVAILABLE → CONTESTED → POST-WAR COOLDOWN (10s) → AVAILABLE.

#### Commitment actors and windows

- Only the **two war root rulers** commit, each from their **personal** pool. A subject who directly owns the target is **not** the commitment actor. Subjects do not auto-contribute. Lieges do not seize/merge/borrow/pool subject Troops.
- Each side independently chooses how many **currently Available** Troops to commit. No automatic full-army commit. Server rejects overcommit. Commitment is to the **war**, not the territory. Same Troops cannot be in two wars. After lock, commitment cannot change or be pulled out.
- Opponent commitments stay hidden until **both** lock, then reveal **simultaneously** (fielded count only; not Total/Available).
- While own commitment is unlocked: UI like “Opponent preparing forces” — do **not** reveal whether they manually locked. After own lock: “Waiting for opponent” — still no lock/amount leak.
- If both manually lock early: proceed immediately (do not wait out the rest of the 40s window).
- **Pacing:** “The timer should pressure indecision, not punish normal thinking.” The ~30-minute match target remains a broad design goal; the commitment window must not feel rushed merely to satisfy that goal. The window is a **ceiling**, not a mandatory delay. Military wars still resolve immediately when both sides Ready early.
- **0–40s** normal decision window: the commitment amount field is the intended commitment. Valid field changes are sent automatically as SetCommit intents (no separate “Set Forces” button). Optional early Lock/Ready freezes the **latest server-accepted** value immediately. The local TextBox is never authoritative. Do **not** auto-lock before 40s merely because a valid intent exists. Over-Available input is rejected; last valid intermediate auto-submit while editing digits is **Director-accepted as-is for V0.1** (not a remaining UX fix).
- **Selected-territory Military context:** when the local player selects a territory that is the target of one of their active Military wars, the Military panel displays and controls **that war only** (independent commitment, lock, timer). Selecting another of their war targets switches context. Selection does **not** SetCommit, lock, cancel, or move Troops. An unrelated selected territory must not present another war as if it belonged to that land. Last Battle uses the same selected-territory rule. **SELECTED-TERRITORY MILITARY CONTEXT: DIRECTOR PASS. TERRITORY-CONTEXTUAL LAST BATTLE: DIRECTOR PASS.**
- **Interacted** = the server has accepted **at least one valid commitment-intent amount**. Opening UI, focusing a field, blank input, or typing locally is **not** interaction. Rejected malformed/negative/overcommit is **not** interaction and does **not** replace the last accepted intent. Accepted **0** **is** interaction. Later accepted 600→750 replaces the latest valid value.
- At **40s:** if interacted, auto-lock the **latest accepted** value. If never interacted, remain non-responsive until 55s. **40–55s** is AFK / nonresponsive grace only — not extra thinking time for players who already interacted.
- At **55s** hard timeout, completely nonresponsive: attacker → engagement **fails/cancels**; defender → lock **0**. Valid attacker force vs defender 0 → **unopposed** attacker victory. **NEVER-INTERACTED ATTACKER 55s CANCEL: DIRECTOR PASS.** **DEFENDER-0 / UNOPPOSED: DIRECTOR PASS.**
- Attacker may declare with 0 Available; must lock at least **1** Troop or the engagement fails (locking 0 after interaction still fails). Player-facing notice: **Attack cancelled: you committed 0 Troops.** (not only “Forces locked.”). Defender may start at 0 Available, emergency-recruit while unlocked, commit new Troops before lock; if still 0 when locked → unopposed if attacker has force.

#### Battle (one battle = one war)

- Combat effectiveness (hidden): each side Committed × random **0.90–1.10**. Defender also × independent random **1.00–1.05**. These rolls do **not** add/remove soldiers. Players see actual committed counts, not Effective Strength.
- Higher Effective Strength wins. **Exact ties favor defender** (treat as defender win when attacker Effective Strength is not greater).
- Randomness must not rescue terrible numerical strategy.
- **Unopposed** (attacker has valid committed force, defender commitment = 0): no effectiveness/defense/ratio/casualty rolls; attacker casualties 0; defender battle casualties 0.
- Otherwise **Victory Ratio** = winner Effective ÷ loser Effective:
  - **CLOSE** ratio < 1.15: winner 20–25%, loser 25–35%
  - **CLEAR** 1.15 ≤ ratio < 1.50: winner 15–20%, loser 35–40%
  - **DECISIVE** ratio ≥ 1.50: winner 10–15%, loser 40–50%
- Percents independently randomized in-band. Casualties = **floor**(committed × percent). No fractional soldiers, no carried fractions. Winning does **not** guarantee fewer absolute casualties. Floor may be 0 at very small committed counts (no minimum-casualty rule).
- Casualties permanently reduce **Total**. Survivors of that war’s commitment return to **Available** when the war concludes (no wounded, recovery, travel-home, retreat, or postwar army cooldown).
- No repeated battles, campaign, war score, or reinforcement cycle. Pace: generally well under ~1–2 minutes, supporting repeated fights in a ~30-minute match.

#### Mechanical resolution vs presentation

- When **both** valid commitments are locked, Military **immediately** calculates the battle (rolls, winner, ratio/band, casualties). The result is **mechanically final**.
- Then ~**5 seconds** of **presentation only** (prototype timing). UI may look “in progress”; nothing in those 5 seconds may reinforce, change commitments, reroll, change casualties, retreat, or change the winner through ordinary play.
- After ~5s, show the final result and apply normal Warfare outcome display. Do **not** show rolls, defense multiplier, ratio, or casualty-percent rolls to ordinary players.
- **Last Battle summary (participant Military panel):** after conclusion, cache each participant-authorized BattleResult **per territory** for ~**20 seconds** (independent expiry per result). Selecting that territory shows **that** summary. Another territory’s later battle does not overwrite it. An **active** war on a territory supersedes that territory’s old Last Battle. Unrelated selected land must not show another territory’s summary. Empty selection with exactly one cached result may show it (single-war). ResultToast remains the brief “this just happened” notice. No battle history. Third parties do not get this summary. **LAST BATTLE READABILITY: DIRECTOR PASS. TERRITORY-CONTEXTUAL LAST BATTLE: DIRECTOR PASS.**

#### Outcomes

- **Attacker Military victory:** apply casualties; report attacker victory to Warfare; Warfare performs accepted conquest (target → attacking **root** after revalidation).
- **Defender Military victory:** apply casualties; report defender victory to Warfare; ownership unchanged; war ends.
- Participant result UI (examples): VICTORY — GREYFEN CAPTURED / DEFENDED — GREYFEN HELD, with each side Committed / Casualties / Survivors. Unopposed defender: Committed 0 / Casualties 0 (not misleading “0 survivors”).
- Non-participants: public war/map outcome only; no exact commitment/casualty report.
- Outside battle: no exact Total/Available/Committed of other rulers; no weak/moderate/strong estimate. Hierarchy/alliance grant **no** extra military intel. Espionage is **future**.
- Map: associate presentation with the contested territory and, where practical, a relevant border. No geographic army objects. Exact placement algorithm **not** locked.

#### Cancel, unwind, admin resolve

- If a war is canceled **before** Military mechanical resolution: no battle, **zero** casualties, committed Troops of **surviving/non-removed** rulers return to Available, that war’s commitment ledger is cleared, no duplicate Troops, do **not** destroy Troops merely because the war canceled. Applies to disconnect cleanup, attacker timeout/cancel, stale/invalid war, and other legitimate cancels unless another explicit rule says otherwise. No new political cancel consequences.
- **Admin `resolvewar` before** mechanical resolution: Military unwinds unresolved commitments (zero casualties, return Available); Warfare then applies the forced Attacker/Defender result on its normal path. Admin does not mutate client state as authority.
- **Admin `resolvewar` after** mechanical resolution (including during the 5s presentation): **reject** (already resolving/resolved). Do not overwrite the calculated casualties/outcome.

#### Visibility, testing, deferred

- Hidden-state testability and **agent-first verification** apply at implementation (server/admin/debug; optional seeded RNG for tests; ordinary match RNG may stay random). Ordinary remotes must not leak diagnostics.
- Two-human disconnect, independence-during-war, simultaneous post-dual-lock reveal, subject-as-commitment-actor, and last-millisecond races: `AI/PLAYTEST_BACKLOG.md` MIL-MP-01–05, 07, 10, remaining 11 (**DEFERRED ≠ PASS**). If later testing shows Troop duplication, dropped outcomes, double resolution, stuck CONTESTED, or equivalent authoritative corruption, treat it as a real defect.
- **Deferred:** physical armies, movement, interception, terrain, forts, sieges, occupation, commanders, unit classes, supply, morale, mercenaries, levies, navy, pathfinding, tactical sim, war score, peace, claims/CB, manpower, military buildings, timed reinforcement, loyalty/desertion, espionage, troop quality, tall-vs-wide military, delegated military authority, ally access/CTA, subject military obligations.

## Religion

Religion is intended to become a meaningful political and strategic system.

Players may potentially:

- Follow religions
- Spread religious influence
- Convert
- Pressure others to convert
- Use religion diplomatically
- Create political blocs around religion
- Engage in religious conflict

**Exact religious mechanics will be designed later.** Religion is deferred from immediate implementation.

## Economy

Characters may possess wealth. An **economic** victory category remains conceptual (overwhelming economic influence of a player or political hierarchy). Buildings, development, tax-law, markets, debt, realm treasuries, inheritance, military upkeep, and detailed economy formulas remain **deferred** except for the approved resource architecture and **Economy / Resources V0.1** Gold foundation below.

Do **not** introduce **Credits** as a replacement for Gold. Do **not** collapse Gold, Prestige, and Influence into one generic currency.

### Match resources (reset each match)

Three conceptually distinct match resources:

```text
Gold      = economic/material power
Prestige  = reputation/legitimacy
Influence = political leverage
```

Do not design them as interchangeable currencies with different icons. Each should eventually have a recognizable strategic purpose.

**Gold** — economic and material power. **Economy / Resources V0.1** (below) is the Gold foundation. Gold may eventually interact with military expenses, territorial investment, economic development, political transactions, and other tangible expenditures. Those sinks are **not** V0.1 gameplay.

**Prestige** — reputation, status, renown, and political legitimacy. May eventually be gained through significant accomplishments (successful rule, warfare, political advancement, dynastic achievements, diplomacy, or other approved systems). May be used as a **requirement** for political actions. For title establishment: a **minimum Prestige threshold is required; that Prestige is not consumed**. Vale Title Progression V0.1 **test** thresholds are 100 / 250 / 500 for Duke / King / Emperor; those are not the full Prestige economy. Title Progression V0.1 uses temporary server-side test Prestige only. Prestige **income, decay, spending, caps, and persistence remain unresolved**. Economy V0.1 does **not** implement Prestige.

**Influence** — political leverage and political capital. May eventually interact with political organization, factions, political demands, support for political objectives, and other political actions. **Deferred** until those political systems are designed. Economy V0.1 does **not** implement Influence.

### Account-level (persist between matches)

**Crowns** — working name for persistent premium/support currency. Exists **outside** the competitive match economy. Unlike Gold, Prestige, and Influence, Crowns **persist between matches**. May eventually be purchasable with Robux. Packages, prices, earning methods, store design, and monetization implementation remain unresolved.

**Crowns must not provide competitive match power.** Do not design Crown purchases of match Gold, Prestige, Influence, extra territory, stronger armies, better combat statistics, political advantages, faster title qualification, or other pay-to-win advantages. Crowns are intended primarily for cosmetic, presentation, personalization, and supporter-oriented content (conceptual examples only: heraldry, banners, realm presentation, UI themes, profile/portrait presentation, title-establishment presentation effects, cosmetic map presentation). Exact products are unresolved.

**Lifetime Support** — account-level statistic, **not a spendable currency**. Recognizes players who financially support development (potential uses: supporter recognition, supporter leaderboards, other noncompetitive recognition). Spending Crowns should **not** reduce historical Lifetime Support. Crown Balance = current spendable premium currency; Lifetime Support = historical support statistic. Exact calculations, Robux accounting, leaderboards, privacy, display, and rewards remain unresolved.

```text
MATCH RESOURCES          ACCOUNT-LEVEL
├── Gold                 ├── Crowns (persistent premium/cosmetic)
├── Prestige             └── Lifetime Support (non-spendable statistic)
└── Influence
```

### Economy / Resources V0.1

Specified design checkpoint, now **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** Gold foundation only. Not the finished economy. Do not modify accepted Hierarchy, Territory / Map, Title, Diplomacy, or Warfare authority merely to accommodate Economy. Future systems must **consume** Economy’s Gold authority rather than duplicating or directly mutating balances.

**Purpose.** Establish ruler Gold state, starting Gold, territory-generated Gold income, authoritative income delivery, safe add/deduct, player-relevant replication/display, and admin/debug inspection and mutation for testing. Integrate by **reading** existing Territory ownership and Hierarchy ruler identity. Do **not** invent temporary shops, buildings, armies, or placeholder purchases merely so Gold can be spent.

**Starting Gold (prototype).** Every ruler begins with **150 Gold**. This is Economy V0.1 prototype balance (about 15 minutes of baseline production from one territory at 10 Gold/min). It is **not** declared permanently balanced for the finished game. It may be rebalanced after real Gold sinks, armies, development, buildings, and published match testing exist.

**Baseline territory income.** Configured per territory as `baseGoldIncome` (Gold per minute) on the map definition. Vale prototype territories use **10 Gold/min**. EconomyService converts Gold/min to the 6-second payout (`goldPerMinute * 6 / 60`). V0.1 requires that conversion to be a **whole number**; invalid map values error at Economy start (no silent fractional carry). Do **not** design rich/poor provinces in V0.1 beyond that config field.

**Income recipient.** Territory-generated Gold belongs to the territory’s **direct owner**. Greater-realm membership alone creates **no** automatic tax, tribute, treasury share, or Gold redirection. Example: Lord B directly owns Greyfen under King A; Greyfen’s V0.1 income goes to Lord B, not to King A. Future taxation/obligations/realm-economic systems may deliberately move Gold; do **not** fake them in V0.1.

**Unclaimed.** An Unclaimed territory has no direct owner and generates Gold for **nobody**. No global treasury or hidden recipient.

**Income delivery.** One **global** server tick every **six seconds**. All eligible rulers are paid on that tick. Whole-number Gold. For Vale 10 Gold/min: **+1 Gold every 6 seconds** per directly owned territory. At each payout, use **current** authoritative ownership. A newly acquired territory contributes to the **new** direct owner’s **subsequent** payouts. Do not prorate partial six-second intervals.

**Conquest.** Capturing another ruler’s territory does **not** steal, transfer, loot, or confiscate that ruler’s existing Gold. The V0.1 economic reward of conquest is the territory’s **future income stream** (more directly owned territories → higher payout). Looting, reparations, treasury seizure, surrender payments, and war indemnities are deferred.

**Subjects.** Becoming a subject does **not** reset, transfer, merge, confiscate, or give Gold to the liege. Personal Gold remains the ruler’s. The subject continues receiving Gold from territories they **directly** own. Hierarchy status and Economy V0.1 treasury are distinct.

**Disconnect / removal (V0.1 only).** When a ruler leaves the match and their match ruler/economy state is removed, their Gold is **removed**. It does **not** transfer to liege, subjects, enemies, territory owners, another ruler, or a global treasury. No V0.1 inheritance or redistribution. **This is not the intended final polished behavior.** Future wealth succession/distribution when a ruler disappears, dies, is succeeded, or otherwise leaves political control is **unresolved**. Do not select succession, heirs, subjects, realm treasury, dissolution, or contract rules now.

**Spending.** Economy V0.1 has **no required player-facing Gold sink**. Prove safe deduction via server/admin/debug testing. Authoritative API concepts: inspect/get balance, add Gold, safe spend/deduct, debug/admin set Gold (exact names follow project conventions). Normal authoritative spending **must not** allow the balance below 0: spend succeeds fully or is **rejected** with **no partial deduction** and **no negative balance**. **No debt** in V0.1. Future systems must spend through Economy’s API, not mutate balances themselves.

**Server authority.** Gold is server-authoritative. Clients must not set, add, deduct, determine payouts, determine ownership for income, or mutate another ruler’s economy. No generic client-accessible “set economy” remote. UI displays replicated player-relevant state only.

**Admin / testing.** Kohl `;inspectgold` `;setgold` `;addgold` `;spendgold` → AdminBridge → `EconomyService`. Kohl is **not** economic authority. Studio `AdminDebug.Invoke` and `EconomyDebug.Invoke` are server-only.

**Ordinary player UI (minimal).** Player-relevant only: **current Gold** (example `Gold: 150`); **current income rate** (example `Income: +10 Gold/min`); **next payout countdown** cycling through the six-second interval (conceptually `0:06` … `0:01`, payout, then `0:06`). If direct ownership changes, the displayed Gold/min updates (1 territory +10; capture another +20). Do **not** expose every ruler’s treasury in ordinary UI. Admin/debug may inspect global/player economy state. Do **not** build transaction history, graphs, giant treasury dashboards, detailed province income breakdowns, or a complex economy menu unless later authorized.

**Must not become (V0.1).** Civilization-style strategic resource inventory; food/wood/stone/iron/trade-good simulation; population or manpower simulation; tax-law or market simulation; debt/loans; buildings; development; realm treasury; inheritance; military upkeep. Gold is enough for this checkpoint.

**Director acceptance (2026-08-24).** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Economy / Resources V0.1 only** (Gold foundation). It is not a complete economy.

**Director-verified PASS (Local Server):**

- Multiplayer start **150 Gold**; both clients shared the same global 6-second payout countdown; one-territory income as specified
- Direct-owner income: **10 Gold/min** per baseline territory; **+1** Gold per global tick per owned territory; two territories **+20 Gold/min / +2 per tick**; three territories **+30 Gold/min / +3 per tick**
- Warfare conquest: target transferred; **treasury not stolen**; future income follows new direct owner; landless defeated ruler **+0 Gold/min** and treasury stopped increasing
- Direct ownership transfer (non-war): future income follows the new owner; old owner’s Gold remains intact
- Subjecthood: Player3 vassal of Player1 **kept personal Gold**; still received **+10 Gold/min / +1 per tick** from their directly owned land; liege received **no** share from that land; no reset/merge/confiscation/tax
- Unclaimed: after ownership removed, income **+0 Gold/min**; Gold stopped increasing across multiple ticks; unclaimed land pays **nobody**; ownership restorable via the existing `TerritoryMapService` path (Kohl `;setowner <id> unclaimed` is admin/debug, not a new unclaim gameplay system)
- **Spend / overspend:** static 0-income ruler at 209 Gold; `;spendgold Player2 500` → `Insufficient Gold.`, balance **209**; `;spendgold Player2 100` → `Spent 100 Gold.`, balance **109**; no partial spend; no negative balance
- **Disconnect Gold wipe:** Player2 disconnected with 109 Gold; remaining players did **not** receive that Gold; they continued only normal territorial income; Player2’s active war cancelled by existing Warfare disconnect cleanup; no inheritance/redistribution
- Kohl raw-target autocomplete/admin UX (Player1/Player2/Player3/`unclaimed` on `setowner`; `setowner`/`setgold` work)
- Accepted Hierarchy / Territory / Title / Diplomacy / Warfare systems were exercised during this testing without an Economy-blocking regression

A landless liege with surviving subjects is a **separate unresolved hierarchy/title design case**. Economy V0.1 may show **+0 Gold/min** for a landless ruler. Do **not** change accepted Hierarchy, Territory, Title, Diplomacy, or Warfare rules to “solve” that case. This acceptance does **not** include taxation, tribute, realm treasury, buildings, development, trade, debt, armies/upkeep, inheritance, reconnect/persistence, Prestige/Influence economies, Crowns, Lifetime Support, delegated permissions, or economic victory scoring.

### Future economic direction — tall vs wide (not Economy V0.1)

The polished economy should support meaningful competition between **building wide** and **building tall**. This is **future design direction**, not V0.1 implementation.

- **Wide:** expand territorial control; more **directly owned** territories → greater baseline Gold income. Economy V0.1 already supplies that primitive.
- **Tall:** a ruler with less land should eventually be able to invest in and develop territory so highly developed land can become substantially more economically productive.

**Locked future principle:** territorial **quantity** should matter, and territorial **quality** should eventually matter too. A smaller, highly developed realm should eventually be capable of economically competing with a larger but poorly developed realm. Neither wide expansion nor tall development should automatically be the only viable economic strategy.

Possible future contributors (not locked, not implemented): buildings, development, territorial investment, population/citizen-related systems **if later adopted**, economic modifiers, other systems. Do **not** lock exact formulas. Do **not** invent a citizen-trust mechanic from this direction. Do **not** implement development now.

## Events & Emergent Storytelling

The game should generate stories through **interacting systems**, not primarily through predetermined scripted narratives.

Desirable emergent situations include:

- A subordinate becoming more powerful than their ruler
- Multiple subjects coordinating a rebellion
- A ruler conquering former enemies and later relying on them
- A dynasty spreading across several politically independent realms
- An alliance collapsing after succession
- A religious movement spreading through diplomacy rather than conquest
- An empire rapidly expanding and then collapsing due to internal politics
- A formerly defeated ruler eventually becoming emperor
- Players betraying alliances for political advantage

The game should create conditions where these events can happen naturally.

Complex character events are deferred. Do not implement a content event pipeline from this section alone.

## GUI-First Presentation

The GUI is the **primary game environment**. The **interactive political map** is the primary strategic board (central portion of the interface long-term). See Titles & Territory for map capabilities and unresolved rendering/input details.

Major interfaces may eventually include:

- Political map
- Character panel
- Realm panel
- Dynasty/family view
- Diplomacy interface
- War interface
- Military interface
- Religion interface
- Political/faction interface
- Economy interface
- Event windows
- Notifications
- Match/victory interface

The GUI should expose the simulation clearly rather than overwhelm players with raw data. Information should be interconnected. Players should be able to navigate naturally between relevant characters, territories, dynasties, rulers, subjects, wars, and political relationships.

Polished production UI is deferred. GUI instances are created in Studio, not as source-controlled instance trees (see `docs/ARCHITECTURE.md`).

### Configurable controls (future — not current work)

The future UI shell already requires **centralized** navigation/keybinds with **no keys assigned** and forbids each controller inventing a private key. The long-term **public product** should go further: a Settings / Controls menu where players can **view** gameplay and GUI/menu binds and **rebind** supported actions, conceptually similar to grand-strategy control settings (not a clone of another game’s UI).

**Intended input architecture (not an implementation choice):** Physical Input → configurable **logical action** → gameplay/UI controller. Controllers should eventually respond to actions such as `OpenMilitary`, `OpenDiplomacy`, `OpenRealm`, `OpenEconomy`, `OpenSettings` (examples only; catalog **unresolved**) rather than treating a particular physical key as the permanent contract.

The **first published playtest** may use temporary/default binds if any keys are later authorized. Configurable remapping, Settings/Controls GUI, bind persistence, DataStores, and device remapping are **not** required for that playtest unless the Director later says so. Do **not** implement Settings/Controls, remapping, or new keybinds from this section. Future player-facing systems should avoid unnecessarily hardcoding GUI-open behavior in a way that would make remapping difficult later; do **not** over-engineer the current prototype.

## Accessibility of Complexity

Sophisticated underlying simulation is allowed. The player should not need to manually manage every calculation. Translate complicated simulation into understandable decisions.

Prefer: “Your strongest subject is becoming disloyal.” — not many hidden calculations.

Prefer: “This marriage creates an alliance.” — not an unnecessarily complicated relationship formula.

Depth should come from meaningful decisions and interactions, not unnecessary interface complexity.

## AI Simulation

NPCs may fill supporting roles humans cannot reasonably fill. Human players drive major geopolitical decisions. The political hierarchy must eventually be able to include both human and NPC rulers under the same conceptual rules unless a later design says otherwise. AI-controlled rulers should **not** require a separate political hierarchy model. A map remains structurally valid regardless of how many positions are human- vs AI-controlled. Human player count does not determine map size or title-scaling rules.

Detailed NPC political behavior, AI population, player replacement of AI positions, AI political memory, and AI decision-making are unspecified / deferred.

**Advanced AI rulers** are part of the long-term vision and are **not** authorized for immediate implementation.

## Saving/Persistence

Match structure is a shared ~30-minute session on a server of ~50 players. **Match** resources (Gold, Prestige, Influence) reset between matches. **Account-level** Crowns and Lifetime Support persist across matches. Detailed match save/load and remaining persistence mechanics are otherwise **unspecified** unless directors design them.

## Victory Conditions

Matches should have **multiple paths to victory**. Victory should not require every other player to be eliminated.

Conceptual categories (thresholds, scoring, and leadership rules **will be designed later**):

### Domination

A player’s political hierarchy becomes the overwhelmingly dominant political authority on the map. Territory controlled by subordinate rulers counts toward the larger realm. The top ruler does not need to personally own every territory.

### Religious

A religion associated with a player or political movement becomes overwhelmingly dominant across the world.

### Dynasty

A player’s dynasty becomes overwhelmingly influential through political positions, titles, marriages, prestige, or related measures.

### Economic

A player or political hierarchy achieves overwhelming economic influence.

### Diplomatic

A player achieves overwhelming political influence through alliances, coalitions, recognition, or another non-conquest mechanism.

**Other victory conditions remain conceptual and deferred.** The Director explicitly authorized the following Unclaimed conquest and Domination V0.x addition on 2026-10-10; it does not authorize other victory types.

### Authorized Unclaimed conquest and Domination V0.x — 2026-10-10

Unclaimed provinces represent local independent settlements with territory-owned militia, not fake players/rulers. Ordinary acquisition requires military conquest through the existing Warfare/Military pipeline. Preserve normal independent-root authority, greater-realm adjacency, same-target contest lock, personal Troop reservations, commitment timers and 10s cooldown. An independent root may conquer using adjacency supplied by subjects; subjects do not independently declare conquest under current authority. No peaceful integration, claims, NPC country, loot or hidden treasury. Starting territory assignment and privileged testing retain their existing purpose.

Defense is configurable per province, then map, then NeutralDefenseConfig fallback. Prototype starting maximum is 300 (balance subject to playtest); current survivors persist after failed attacks for this match, never negative or above maximum. Regeneration is deferred for V0.x. Successful conquest assigns the land to the attacking root through normal ownership events, adds future direct-owner income and updates title qualification. Ownership revision rejects stale neutral outcomes even after claimed/unclaimed transitions.

Domination counts all conquerable map territories, including Unclaimed in the denominator. Root plus all deeper descendants count together through authoritative Hierarchy truth. Map victory config uses type Domination and territoryControlPercent 0.70; required holdings = ceil(total * threshold), giving 12 of 16 in The Vale. Emperor is not automatically victory. The independent root is the one political winner; its subjects share REALM VICTORY. Root gets VICTORY, others DEFEAT.

VictoryService evaluates meaningful ownership/hierarchy changes, records the first winning root/title/realm/member snapshot and ends exactly once. Major competitive actions, ownership transfers, recruitment/spending/payouts, title/fealty/diplomacy mutations and remaining war outcomes freeze; pending military survivors return, already incurred casualties remain. Final political/ownership state is retained across post-victory disconnects; late joins inspect the ended match without a new starting ruler/territory. Map inspection, Realm Overview, final-result inspection and existing safe Communications remain available. No kicks, rematch, lobby, persistent rewards or other victory types. Agent implementation/verification does not imply Director acceptance.

## Replayability

Every match should be capable of producing a substantially different political history, from different players, alliances, wars, rulers, dynasties, betrayals, hierarchies, religious movements, and victory strategies.

The intended feeling: “Let’s play another match and see what happens this time.”

## Version 0.1 Scope

Do not attempt to implement the entire design simultaneously. Systems should be built incrementally and verified individually.

A full numbered 0.1 feature freeze beyond the following is **not** specified.

**Political Hierarchy V0.1** is specified in this document and the prototype is **accepted / complete**. Do not reopen it.

**Territory / Map Foundation V0.1** is specified under Titles & Territory. The prototype is **accepted / complete**. Do not expand it into deferred systems.

**Title Progression V0.1** is specified under Titles & Territory. The prototype is **accepted / complete**. Sequential Lord → Duke → King → Emperor, Vale test thresholds, greater-realm control, manual establish, server revalidation, test Prestige not spent, no auto-demotion.

**Diplomacy V0.1** is specified under Relationships & Diplomacy. The prototype is **accepted / complete**. Independent-root Alliance and Non-Aggression Pact only; pending 30s requests; server authority; consume hierarchy; dissolve on loss of independence; no opinion/autonomy. Warfare / Conquest V0.1 **queries** NAP/Alliance; Diplomacy does not implement wars.

**Warfare / Conquest V0.1** is specified under Warfare. **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** Independent-root external wars; one enemy-controlled **territory** target; greater-realm adjacency (Vale 8-neighbor lattice **director-verified**); NAP blocks declaration; Alliance does not auto-join; multiple simultaneous wars on **different** territories; server-only debug Attacker/Defender Victory. Historical Warfare V0.1 verification included competing same-target wars; **Military / Armies V0.1 supersedes** same-target multiplicity (at most one active war per territory). Director-verified including attacker/defender victory, disconnect of attacker or defender root, loss of independence without liege inheritance, player-relevant ordinary GUI, and global admin InspectWars. AdminBridge `resolvewar` uses `WarfareService.DebugResolveWar`. This is **V0.1 only**, not a complete military game. Future warfare must build on this authority. Economy V0.1 **reads** post-conquest ownership for future Gold income; conquest does **not** steal existing Gold.

**Military / Armies V0.1** is specified under Warfare. **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope; PASS list in `AI/PROGRESS.md`). Director-locked contract is in that section. Ordinary wars resolve through Military battle into Warfare attacker/defender application. `resolvewar` remains privileged (unwind if pre-mechanical; reject after). Eight MIL-MP overlay cases remain deferred (deferred ≠ PASS).

**Player communications / Communications V0.x** is specified under Product / Player communications. **PRE-V0.5 REQUIRED — IMPLEMENTED — PARTIAL AGENT VERIFICATION — NOT DIRECTOR-ACCEPTED.** Replacement authorized 2026-10-09. Ordinary paths: Diplomatic (replaces retired General), Council (direct-liege), Allies (per Alliance, not NAP), Direct (personal-territory adjacency, no grandfathering; Director clarification). Admin/Observer is separate. Canonical freeze: that section and `AI/DECISIONS.md`.

**Admin / Testing Infrastructure V0.1** is specified under Admin / Testing. Official Kohl loader is in the place; listed AdminBridge commands are live for GameTester UserIds (plus Studio synthetic UserId exception). Owner/ruler tokens use `adminOwnerToken` / `adminRulerToken` (**Director-verified PASS** Local Server autocomplete including `unclaimed` on `setowner`). It is **not** a finished admin product. Convenient copy/reuse of reusable IDs is required before the first published playtest, not implemented now.

**Economy / Resources V0.1** is specified under Economy. **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** Gold foundation only (`EconomyService`; Vale `baseGoldIncome` 10; start 150; global 6s tick; direct-owner income). Prestige remains Title V0.1 test Prestige. Influence remains deferred. Landless-liege political consequences remain unresolved and are not part of this acceptance.

**Naming formulas and monetization** remain specified only at the earlier checkpoint level except where Title Progression V0.1 already locks Vale test Prestige thresholds and Economy V0.1 locks prototype Gold numbers. Additional map assets, real Prestige/Influence gameplay, Crown products, and buildings/development remain unresolved / deferred.

Political Hierarchy V0.1 remains a foundational dependency for later warfare, rebellion, title progression, diplomacy, and victory conditions. Territory ownership is a separate concept from hierarchy membership.

## Explicitly Deferred Features

Part of the long-term vision, **not** authorized for immediate implementation merely because they appear here. Each requires **separate design approval** before implementation:

- Warfare beyond V0.1 (armies, battles, sieges, claims, casus belli, war score, peace, alliance participation, and the rest of the V0.1 deferred list)
- Religion
- Detailed economy beyond Economy / Resources V0.1 (buildings, development, taxation, trade, realm treasury, inheritance, markets, debt)
- Schemes
- Assassination
- Complex factions
- Detailed succession
- Large dynasty simulation
- Advanced AI rulers
- Detailed military simulation
- Buildings
- Development (tall-vs-wide quality is **future direction**, not implemented)
- Council systems (gameplay councils — **not** the same as the future **Council** chat channel under Player communications)
- Player communications / chat (PRE-V0.5 REQUIRED; **IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED**; recommendation B authorized 2026-10-09; real-account native peer filtering/privacy remains outstanding)
- Complex character events
- Final victory-condition calculations
- Polished production UI
- Battle History / War Chronicle (optional future flavor: scrollable prior battles, territory, victory/defeat, fielded forces, casualties/survivors, timestamps, notable stats). **Not** Military V0.1. **Not** a blocker. Do not implement from this line.
- Settings / Controls menu and player-configurable keybind remapping (long-term product; not automatically required for the first published playtest)
- Title-scaling formula and numerical thresholds for maps **other than** Vale Title Progression V0.1 test numbers (Duke 2/100, King 5/250, Emperor 10/500)
- Real Prestige resource system (income, decay, spending, UI economy, persistence); V0.1 titles use temporary server-side test Prestige only
- Title-loss systems
- Vassal obligations (tax, military contribution, contracts, formulas). Economy V0.1 has **no automatic tax**
- Independence gameplay methods
- Disconnect / reconnect beyond the temporary V0.1 hierarchy cleanup, the specified Unclaimed-on-leave map rule, and Economy V0.1 Gold removal without redistribution (polished wealth succession remains unresolved)
- Join-in-progress mechanics
- Starting-territory player choice / lobby map voting
- Public-product lobby / hub, world/map selection, join/queue, and matchmaking (not required for the first published playtest; not Military V0.1)
- Behavior when more humans join than the selected map has territories
- Additional production maps beyond the 16-territory V0.1 test map
- Touch / controller map input (architecturally possible; not required for V0.1)
- Gold / Prestige / Influence **caps** and remaining formulas; Prestige/Influence **starting amounts and rates**; Gold **final** (non-prototype) balance after sinks exist. Economy V0.1 locks prototype **150 starting Gold** and **10 Gold/min** baseline per claimed territory only
- Crown prices, packages, earning methods, and exact cosmetics
- Lifetime Support calculations and monetization implementation
- Procedural naming algorithm and final geographic/political names
- Player replacement of AI rulers and detailed AI political behavior
- Diplomacy beyond V0.1 (opinion, vassal diplomatic autonomy, inheritance, map modes, extra agreement types, NAP auto-break / violation penalties)
- Delegated greater-realm authority / permission catalog (architecture specified; not implemented; catalog unresolved)
- Civilization-style strategic resources, food/wood/stone/iron, trade goods, population/manpower simulation, tax-law simulation, markets, debt/loans

## Long-Term Vision

A ~30-minute, ~50-player Roblox match in which players create fictional political history through character-driven hierarchy, diplomacy, war, religion, dynasty, and internal politics — with multiple non-elimination victory paths, GUI-first presentation, and subordination remaining playable.

## Performance Philosophy

Performance remains an explicit architectural concern as the simulation grows. Prefer designs that store authoritative state, recalculate when meaningful state changes occur, avoid unnecessary continuous polling, avoid repeatedly recalculating unchanged political information, use event-driven / state-change-driven updates where appropriate, keep expensive simulation work controlled and intentional, and avoid making every NPC continuously evaluate every possible action every frame.

**Store state; calculate on meaningful change; do not continuously recalculate what has not changed.**

This is a design/architecture philosophy, not authorization to prematurely optimize systems that do not exist yet.

## Current Development Philosophy

- Directors define game mechanics.
- Implementation agents implement those mechanics.
- Agents must not invent major game systems merely because a concept appears in this document.
- Unspecified mechanics remain unspecified until designed.
- **Agent-first verification** (canonical: `.cursor/rules/project.mdc`): agents verify as much as the environment allows before asking the Director to test; agent PASS is not Director acceptance.

## Authority

`AI/GAME_DESIGN.md` is the authoritative product vision. Directors determine design direction. Agents implement approved designs and must ask when an important mechanic is unspecified.
