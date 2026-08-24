# Game Design

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
- Vassal obligations (tax, military contribution, contracts, percentages, penalties, formulas)
- Independence **gameplay methods** (the hierarchy must support becoming independent later; methods are unspecified)
- Disconnect / reconnect behavior
- Join-in-progress participation

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

The first meaningful **gameplay prototype** (Political Hierarchy V0.1) is **accepted / complete**. It must **not** expand into a deep autonomous character simulation. Territory / Map Foundation V0.1 is **accepted / complete**. Diplomacy V0.1 is **accepted / complete**. Warfare / Conquest V0.1 is **implemented — partially director-verified — acceptance testing in progress — not director-accepted**.

## Admin / Testing Infrastructure V0.1

Director-approved **tooling architecture**, not a gameplay system. **Kohl's Admin** is the command/auth presentation layer only. It is **not** gameplay authority.

Custom testing commands must go: Kohl (or Studio debug) → project **Admin Bridge** → existing authoritative service APIs → normal replication. The admin layer must never become an alternative source of truth. Gameplay services must not depend on Kohl's Admin.

**GameTester** is a distinct high-trust UserId allowlist (server-enforced). Ordinary Kohl moderator roles must **not** automatically receive game-state mutation. Never trust client-supplied admin status, ruler identity, or mutations. Do not expose arbitrary code execution or generic “set anything” remotes.

**V0.1 status:** architecture recorded. Official Kohl's Admin (@Scripth, asset 172732271) is installed under `ServerScriptService`. Live GameTester commands (`adminhelp`, `inspectwars`, `inspectterritory`, `inspectruler`, `setowner`, `setprestige`, `resolvewar`) go through `AdminKohlAddon` → `AdminBridge`. Command feedback uses project ResultToast / compact inspect overlay; Kohl chrome is restyled from PrototypeGuiTheme after load. Kohl rank is not enough. Studio `AdminDebug.Invoke` and per-system `*Debug` folders remain. Do not treat this tooling as a complete gameplay system.

**Future systems:** when a new server-authoritative gameplay system is implemented, consider exposing Director/testing operations through the Admin Bridge after the system's own APIs exist. Do not implement deferred gameplay (economy, armies, etc.) as fake admin commands.

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

Every territory is selectable, including unclaimed. Selection opens a simple information panel only: territory name, territory ID, owner, owner rank, independent/subject status, greater realm/root ruler. Unclaimed must read as Unclaimed. Do **not** add economy, gold, military, religion, development, claims, war actions, buildings, or population. Architect the panel so later systems can extend it. There is **no Claim/Conquer** action in Territory / Map Foundation V0.1. Player conquest, when authorized, belongs to **Warfare / Conquest V0.1** (specified — not implemented), not this map checkpoint.

Desktop V0.1 navigation: click-and-drag pan, mouse-wheel zoom, click to select. Bounded strategy-map camera: no infinite pan away from the map; reasonable min/max zoom; pan constrained to map bounds; initial view frames the entire 16-territory test map. “Focus my realm” is **not** V0.1.

**Adjacency** is static map definition from the start (each territory lists neighboring IDs) and is **MapConfiguration truth**, not runtime distance. Territory / Map Foundation V0.1 stores adjacency; it does not itself declare or resolve wars. **Warfare / Conquest V0.1** queries that adjacency plus greater-realm membership for declaration validation.

**Vale prototype adjacency (director-corrected, later director-verified).** On the current 4×4 Vale lattice, a territory is adjacent to every **immediate** neighboring cell that shares an **edge or a corner** (8-neighbor). Interior cells may have up to 8 neighbors; edge non-corners up to 5; corners up to 3. Two cells away is not adjacent. Other maps author their own graphs; do not assume every future map is 8-neighbor. Do not infer adjacency from visual proximity.

Territory / Map Foundation V0.1 includes **no** conquest, war, armies, claims, occupation, annexation, claiming unclaimed land, trading, gifting, or purchase of territory. Ownership changes beyond initial assignment and disconnect may use **server-only debug helpers** for verification, not player gameplay. Successful attacker victory under Warfare / Conquest V0.1, when later implemented, must use this map’s existing authoritative ownership path.

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

Specified design checkpoint. **Accepted / complete** after director Local Server multiplayer verification. Do not reopen Political Hierarchy V0.1, Territory / Map Foundation V0.1, Title Progression V0.1, or Diplomacy V0.1. Do not implement Warfare / Conquest V0.1, economy, AI, relationships/opinion, or vassal diplomatic autonomy from this Diplomacy section.

**Purpose.** Authoritative political relationships **between independent greater realms**. It answers: which independent realms currently have formal diplomatic agreements with each other? Baseline infrastructure only. Not a complete diplomatic simulation.

**Actors.** External diplomacy is conducted only by **root / independent rulers**. The root represents the entire greater realm. Subjects **cannot** independently offer, accept, decline, or break those external agreements. A subject’s external diplomatic alignment follows their greater-realm root. **Vassal diplomatic autonomy is not V0.1.**

Example: independent King Bob may diplomatically engage independent Emperor Steve. Duke Cody, vassal of Bob, may not offer Alliance or NAP to Steve, accept or decline Steve’s external requests, or break Bob’s external agreements.

**Agreement types (exactly two):**

1. **Alliance**
2. **Non-Aggression Pact (NAP)**

Do not add guarantees, tributaries, trade agreements, marriages, defensive pacts, coalitions, federations, truces, favors/hooks, opinion, trust, diplomatic reputation, embassies, subject-negotiated diplomacy, or war participation.

**Alliance V0.1.** Mutual formal relationship between two independent greater realms. Flow: root A offers Alliance to root B → server pending request → B Accept or Decline → only successful server Accept creates the Alliance. Either root may later **unilaterally Break Alliance** (no consent). V0.1 meaning only: these two greater realms are formally allied. Diplomacy must **not** implement automatic military assistance, call to arms, shared wars, troop access, joint victory, defensive/offensive obligations, or Prestige/economic effects. **Warfare / Conquest V0.1** (specified — not implemented) **queries** Alliance state and does **not** auto-join allies to wars.

**Non-Aggression Pact V0.1.** Mutual formal relationship between two independent greater realms. Same offer → pending → Accept/Decline / expire flow. Either root may unilaterally **Break NAP**. V0.1 meaning only: these two greater realms currently have a formal non-aggression agreement. Diplomacy must **not** auto-break the pact, apply violation penalties, create truces, or alter reputation/Prestige. **Warfare / Conquest V0.1** (specified — not implemented) **queries** NAP via Diplomacy and **rejects war declaration** while the pact exists. The player must no longer have the blocking NAP before a valid declaration.

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

**Queryability.** Authoritative systems may ask equivalents of `AreAllied(rulerA, rulerB)` and `HasNonAggressionPact(rulerA, rulerB)` (exact names are implementation detail). **Warfare / Conquest V0.1** (specified — not implemented) **consumes** that diplomatic state. Diplomacy V0.1 must **not** implement warfare.

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

Specified design checkpoint. **Implemented — partially director-verified — acceptance testing in progress — not director-accepted.** Director-verified resolution: **Attacker Victory PASS**, **Defender Victory PASS**. Next remaining director test: competing same-target wars / stale-war resolution. Do not reopen Political Hierarchy V0.1, Territory / Map Foundation V0.1, Title Progression V0.1, or Diplomacy V0.1. Do not begin armies, battles, sieges, claims, casus belli, peace negotiations, war score, or other deferred military systems from this checkpoint.

**Purpose.** Minimum server-authoritative warfare primitive to prove that independent greater realms can declare external wars, target one enemy-controlled territory, validate borders through existing greater-realm territory, coexist in multiple simultaneous wars, resolve wars through a **server-only debug** mechanism, and transfer territory after a valid attacker victory. Infrastructure testing only. Not a military simulation.

**Actors.** Only an **independent root ruler** may declare an external war. Subjects / vassals do **not** independently declare external wars. A subject participates politically as part of the greater realm of their root. Hierarchy remains the source of truth for independence, liege/vassal, root, and greater-realm membership. Warfare **must not** duplicate the political hierarchy tree.

Example: independent King Bob; Duke Cody is Bob’s subject and owns a border territory next to Emperor Steve. Bob may declare the external war against Steve using that greater-realm border. Cody may not independently declare that external war.

**War target.** Every war targets **one** specific enemy-controlled territory. A declaration must identify the contested territory. The target must currently be controlled by **another** greater realm, must **not** belong to the attacker’s own greater realm, must **not** be Unclaimed, must satisfy greater-realm adjacency, and must otherwise pass server validation. Warfare V0.1 **cannot** claim Unclaimed territory. Unclaimed expansion is deferred.

**Greater-realm adjacency.** Adjacency is evaluated using the **entire attacking greater realm**. A target is eligible when it is MapConfiguration-adjacent to **any** territory controlled by **any** ruler in the attacking root’s greater realm (Vale: immediate edge or corner neighbor). The neighboring land need not be personally owned by the root. Territory / Map remains the source of truth for ownership, map adjacency, and territorial transfer. Hierarchy determines which rulers’ territories constitute the greater realm.

Example: Bob personally owns Westmere; vassal Cody owns Northvale; Northvale borders Steve’s Greyfen. Bob’s greater realm borders Greyfen; Bob may declare war for Greyfen; Cody may not independently declare it.

**Declaration.** War declarations are **not** requests. There is no Accept / Decline flow. If the server validates the declaration, the war begins immediately. The defender does not consent. The server owns all authoritative war state. Client input, when later implemented, is intent only.

**NAP.** An active Non-Aggression Pact between attacking and defending greater realms **blocks declaration**. The server rejects the declaration while the NAP exists. Warfare V0.1 does **not** automatically break the NAP, apply a violation penalty, create a truce, or alter reputation/Prestige. Diplomacy remains the source of truth for NAP state.

**Alliance.** Alliance does **not** automatically join another realm’s war. No call to arms, allied armies, shared wars, military access, or automatic co-belligerents. Those are deferred. Diplomacy remains the source of truth for Alliance state.

**Multiple simultaneous wars.** A ruler / greater realm may participate in **multiple** active wars at once. There is no “one war at a time” restriction. Different territories may be targeted by separate wars. A defender may declare a separate valid war in the opposite direction. There is **no** special counter-war or counterattack mechanic: if Realm A attacks Realm B, Realm B may independently declare another valid war against Realm A for a **different** eligible enemy-controlled bordering territory. That second declaration uses the same validation rules. It is simply another war object.

**Multiple wars, same territory.** Multiple active wars **may** target the same territory. Do **not** introduce a one-active-war-per-territory restriction. Each war is an independent authoritative record. At minimum it must retain attacker root, defender root, target territory, and active/resolved state. Resolution **must revalidate** the target before applying territorial transfer.

Example: Player1, Player3, and Player4 may all have active wars against Player2 for Greyfen. If Player1 wins first and Greyfen validly leaves Player2’s greater realm, remaining wars against Player2 for Greyfen are **stale**. They must **not** subsequently transfer Greyfen merely because debug resolution says attacker victory.

**Stale / invalid resolution.** Before applying a result, the server revalidates. If another war already caused the target to leave the **original defending greater realm**, competing wars over that target become invalid/stale and terminate **without** transferring the territory. V0.1 does **not** retarget the new owner, automatically create a war against the new occupier, or model contested occupation, three-way wars, hostile third parties, continuation against a new occupier, war-score inheritance, or peace-conference claims.

**Resolution.** There are no real armies or battles in V0.1. Active wars remain unresolved until a **server-only debug** mechanism resolves them. That mechanism must support at least **Attacker Victory** and **Defender Victory**. It exists solely to prove warfare infrastructure independently from future military simulation. It must **not** be exposed as a normal player authority mechanism.

**Attacker Victory.** The server must revalidate the war before changing ownership. If still valid: **target territory → direct ownership of the attacking root ruler**. Do not automatically distribute conquered land to vassals, neighboring subjects, title holders, previous owners, or AI administrators. Realm administration / conquered-land redistribution is deferred.

**Defender Victory.** The war ends; target ownership remains unchanged. No V0.1 reparations, Prestige, penalties, truces, cooldowns, claims, opinion, or economic effects.

**Disconnect.** If a participating **root ruler** disconnects, affected active wars involving that ruler are cancelled / terminated. No automatic victory. No territory transfer because of disconnect. No persistence, reconnect restoration, AI takeover, or succession handoff.

**Loss of independence.** If a participating root loses independence and becomes somebody else’s subject during an active external war, affected wars involving that former root terminate. The war does **not** transfer to the new liege. The new liege does **not** inherit the war. No automatic territorial result merely because independence was lost. Same baseline philosophy as external Diplomacy V0.1. Advanced realm-war inheritance is deferred.

**Territory integration.** Warfare does **not** maintain a duplicate ownership model. Territory / Map remains authoritative. Successful conquest uses the existing ownership path.

**Hierarchy integration.** Warfare consumes Hierarchy for root, independence, and greater-realm membership. Subjects contribute territory to greater-realm adjacency but do not gain independent external-war authority.

**Diplomacy integration.** Warfare queries existing Diplomacy. NAP blocks declaration. Alliance does not auto-join. Warfare does not duplicate Alliance/NAP state.

**Title integration.** Warfare does **not** directly grant rank, Prestige, promotion, or demotion. Successful conquest changes ownership; Title Progression may observe the new control counts through existing architecture. Warfare itself does not promote the ruler.

**GUI.** Respect current prototype UI: `PrototypeGuiTheme`; map as primary workspace; no uncontrolled permanent stacking; stable assigned regions; higher GUI blocks map input beneath it; toasts for results; no state-driven primary-panel geometry. Do **not** assign warfare keybinds. Declare War lives in `TerritoryInfo`. Future UI shell remains specified, not implemented.

**Explicitly deferred from Warfare / Conquest V0.1:** armies, units, troop counts, troop movement, battles, combat simulation, sieges, occupations, casualties, military economy, recruitment, reinforcement, supply, logistics, commanders, generals, army AI, claims, casus belli, war goals beyond the single target territory, war score, peace negotiations, peace treaties, surrender, reparations, truces, cooldowns, Prestige rewards/penalties, opinion/reputation, aggressive expansion, coalitions, call to arms, alliance war participation, military access, guarantees, tributaries, contested occupation, multi-party peace, automatic continuation against a new territory owner, vassal independent warfare, vassal war autonomy, conquered-territory redistribution, unclaimed-territory warfare, persistence, reconnect restoration, succession/inheritance of wars, AI warfare, advanced war GUI, warfare keybinds.

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

Characters may possess wealth. An **economic** victory category remains conceptual (overwhelming economic influence of a player or political hierarchy). Buildings, development, and detailed economy formulas are deferred except for the approved resource architecture below. Exact earning rates, starting amounts, costs, sinks, caps, and interactions remain unresolved. Do not invent them.

### Match resources (reset each match)

Three conceptually distinct match resources:

```text
Gold      = economic/material power
Prestige  = reputation/legitimacy
Influence = political leverage
```

Do not design them as interchangeable currencies with different icons. Each should eventually have a recognizable strategic purpose.

**Gold** — economic and material power. May eventually interact with military expenses, territorial investment, economic development, political transactions, and other tangible expenditures.

**Prestige** — reputation, status, renown, and political legitimacy. May eventually be gained through significant accomplishments (successful rule, warfare, political advancement, dynastic achievements, diplomacy, or other approved systems). May be used as a **requirement** for political actions. For title establishment: a **minimum Prestige threshold is required; that Prestige is not consumed**. Vale Title Progression V0.1 **test** thresholds are 100 / 250 / 500 for Duke / King / Emperor; those are not the full Prestige economy. Title Progression V0.1 uses temporary server-side test Prestige only. Income, decay, spending, caps, and persistence remain unresolved.

**Influence** — political leverage and political capital. May eventually interact with political organization, factions, political demands, support for political objectives, and other political actions.

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

**Victory conditions are conceptual.** They must **not** be implemented until their individual systems have been formally designed. Final victory-condition calculations are deferred.

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

**Warfare / Conquest V0.1** is specified under Warfare. **Implemented — partially director-verified — acceptance testing in progress — not director-accepted.** Independent-root external wars; one enemy-controlled territory target; greater-realm adjacency (Vale 8-neighbor lattice **director-verified**); NAP blocks declaration; Alliance does not auto-join; multiple simultaneous wars (including same target); server-only debug Attacker/Defender Victory; **attacker victory** and **defender victory** director-verified. Next director test: competing same-target wars / stale-war resolution. Disconnect and loss-of-independence cancellation remain implemented but **not** director-verified. Resolution may be driven from `WarfareDebug` or GameTester `resolvewar` via AdminBridge (same `DebugResolveWar` path).

**Admin / Testing Infrastructure V0.1** is specified under Admin / Testing. Architecture recorded; small Admin Bridge foundation for current systems; Kohl loader not in the place until the Director inserts it.

**Naming formulas, economy, and monetization** remain specified only at the earlier checkpoint level except where Title Progression V0.1 already locks Vale test Prestige thresholds. Additional map assets, real Prestige/Gold/Influence gameplay, and monetization products remain unresolved.

Political Hierarchy V0.1 remains a foundational dependency for later warfare, rebellion, title progression, diplomacy, and victory conditions. Territory ownership is a separate concept from hierarchy membership.

## Explicitly Deferred Features

Part of the long-term vision, **not** authorized for immediate implementation merely because they appear here. Each requires **separate design approval** before implementation:

- Warfare beyond V0.1 (armies, battles, sieges, claims, casus belli, war score, peace, alliance participation, and the rest of the V0.1 deferred list)
- Religion
- Detailed economy
- Schemes
- Assassination
- Complex factions
- Detailed succession
- Large dynasty simulation
- Advanced AI rulers
- Detailed military simulation
- Buildings
- Development
- Council systems
- Complex character events
- Final victory-condition calculations
- Polished production UI
- Title-scaling formula and numerical thresholds for maps **other than** Vale Title Progression V0.1 test numbers (Duke 2/100, King 5/250, Emperor 10/500)
- Real Prestige resource system (income, decay, spending, UI economy, persistence); V0.1 titles use temporary server-side test Prestige only
- Title-loss systems
- Vassal obligations (tax, military contribution, contracts, formulas)
- Independence gameplay methods
- Disconnect / reconnect beyond the temporary V0.1 hierarchy cleanup and the specified Unclaimed-on-leave map rule
- Join-in-progress mechanics
- Starting-territory player choice / lobby map voting
- Behavior when more humans join than the selected map has territories
- Additional production maps beyond the 16-territory V0.1 test map
- Touch / controller map input (architecturally possible; not required for V0.1)
- Gold / Prestige / Influence starting amounts, rates, caps, and formulas
- Crown prices, packages, earning methods, and exact cosmetics
- Lifetime Support calculations and monetization implementation
- Procedural naming algorithm and final geographic/political names
- Player replacement of AI rulers and detailed AI political behavior
- Diplomacy beyond V0.1 (opinion, vassal diplomatic autonomy, inheritance, map modes, extra agreement types, NAP auto-break / violation penalties)

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

## Authority

`AI/GAME_DESIGN.md` is the authoritative product vision. Directors determine design direction. Agents implement approved designs and must ask when an important mechanic is unspecified.
