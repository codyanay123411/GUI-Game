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

## Political Hierarchy

Political Hierarchy Design **V0.1** is specified below. It is **foundational**. It is **not** authorization to implement gameplay in a documentation task.

Players exist in a shared political world as **independent rulers** or **subordinate rulers**. Relationships must support **nested** hierarchies.

### Landed title ranks

There are **four** primary landed political levels (intentionally few, for ~30-minute matches):

**Lord → Duke → King → Emperor**

This **supersedes** earlier conceptual ranks that used Count. Do not add extra landed title tiers.

Title **establishment** is specified under Titles & Territory (dynamic map-based realm-control plus a minimum Prestige threshold; player action; server revalidation). Exact numerical thresholds and the scaling formula remain unresolved. Gold and Influence are **not** title-establishment requirements. Promotion is **not** automatic.

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

Example at match start: Bob, Henry, and Robert swear to Cody (all Lords). Cody’s greater realm then conceptually controls four territories if each holds one, which can contribute toward later **eligibility** to establish a Duchy (see Titles & Territory). Exact thresholds remain unresolved.

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

- Exact title-scaling formula and numerical realm-control / Prestige thresholds
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

The first meaningful **gameplay prototype** must **not** be a deep autonomous character simulation. It should focus on **multiplayer political hierarchy** (see Version 0.1 Scope). Do not implement that prototype as part of documentation work.

## Character Traits & Attributes

Characters may possess traits and attributes. Detailed trait/attribute mechanics are **unspecified** and must be designed by directors before implementation.

## Titles & Territory

The primary world representation is a **GUI-first 2D interactive political map**. It is the primary strategic game board, not a decorative background. Long-term it should occupy the central portion of the interface.

The long-term map should be capable of supporting concepts such as panning, zooming, territory selection, highlighting, political ownership visualization, realm visualization, contextual information, and different informational/map modes where appropriate. Players should eventually interact with individual territories and navigate political information through the map.

Exact rendering technology, territory hit detection, map geometry format, input implementation, mobile controls, and visual design are **not approved**. Do not choose or implement them from this document.

There is no requirement for a traditional explorable 3D Roblox world.

Approved landed ranks are **Lord → Duke → King → Emperor**. Each normal starting player is an Independent Lord with **one** starting territory.

### Multiple maps and stable geography

The long-term game should support **multiple selectable fictional maps**. A future lobby/match-selection flow may allow players to choose or vote between maps. Approximately five maps has been discussed; **five is not a locked production requirement**.

Each map may have a different number, arrangement, and shape of territories. Territory counts need not match across maps. Political systems must **not** assume every map has the same number of territories.

Maps are **not** selected or scaled by human player count. Do not use concepts such as RecommendedPlayers as a foundation for map or title progression. The selected map keeps its intended geography regardless of current human population. Title progression and political scaling must **not** fundamentally depend on how many humans are in the match.

Each designed map has recognizable geography. Territories have **stable geographic identities and names** for that map (illustrative only, not final names: Blackmere, Northwatch, Ravenford, Eastvale, Stormrest). If a territory is named Blackmere, it remains Blackmere for the match. Ownership, realm membership, rulers, and titles may change; **geographic identity does not**.

**Geography and political realms are separate.** A territory’s geographic name is not the political realm controlling it. Example: the Duchy of Blackmere may comprise Blackmere, Ravenford, Eastvale, and Stormrest. Blackmere stays a geographic territory; “Duchy of Blackmere” is a political entity layered over geography. Multiple duchies may exist inside a kingdom, and multiple kingdom-level structures inside an empire. Political organization must not overwrite geographic identities.

Exact maps, territory counts, layouts, lobby voting, and selection UI remain unresolved.

### Title qualification and establishment

Higher-title qualification **adapts to the selected map**. Do **not** permanently hardcode universal territory counts (Duke always X, King always Y, Emperor always Z). Conceptually: `TitleRequirements = f(MapConfiguration)`. Human player count is **not** part of this calculation. The calculation should be **deterministic and configuration-driven**, not randomly different between otherwise identical matches. Exact formula, percentages, minimums, rounding, and per-map tuning remain **unresolved**.

Qualification uses the ruler’s **greater realm**, not only personally held land. Territory controlled through the subordinate hierarchy counts. Voluntary vassalage can therefore contribute toward title progression alongside direct acquisition.

**Eligibility and establishment are separate.** Meeting requirements does **not** automatically grant the title:

```text
Meet requirements
→ Become eligible
→ Player chooses to establish title
→ Server revalidates eligibility
→ Title is formally established
```

A Lord who meets Duchy requirements becomes **eligible to establish a Duchy** and remains a Lord until they deliberately establish it. Then they become a Duke. The same principle applies: **Lord → Duke → King → Emperor**.

Establishing a higher title requires two conceptual conditions:

1. **Dynamically scaled realm-control** for that title on the selected map.
2. **Minimum Prestige** for that title (reputation/legitimacy). **Prestige is not spent** on establishment.

Gold is **not** an approved title-establishment requirement. Influence is **not** an approved title-establishment requirement. Exact Prestige amounts are **not** approved.

Title establishment is **authoritative game state**. The client may display eligibility and request establishment. The client must **not** grant Duke, King, or Emperor. The server must determine whether the player still satisfies approved requirements. Exact implementation is deferred.

Once a title is legitimately established, falling below the original creation requirements does **not** automatically demote the ruler. Creation thresholds govern **creation**, not continuous holding. Future systems may allow titles to be revoked, usurped, surrendered, destroyed, or lost through warfare, succession, or other politics; **those systems are not designed**. Do not invent them.

Formal rank and current practical power may **diverge** (a weakened Duke may hold less land or military strength than a powerful Lord). This is intentional.

Conceptual progression (thresholds unresolved): Independent Lord → eligible for Duchy (dynamic realm-control + min Prestige) → player establishes → Duke → eligible for Kingdom (larger dynamic realm-control + larger min Prestige) → player establishes → King → eligible for Empire (largest dynamic realm-control + highest min Prestige) → player establishes → Emperor.

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

Long-term design includes concepts such as:

- Alliances
- Political agreements
- Marriage diplomacy
- Vassalage
- Offers of protection
- Demands
- Negotiation
- Claims
- Independence
- Political coalitions

**Voluntary vassalage** (both parties agree, rank rules in Political Hierarchy) is an approved action. Exact remaining diplomatic mechanics are unspecified. Do not implement a full diplomacy system from this list alone.

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

The game does **not** require 3D player-controlled armies. Military conflict can be represented through strategic interfaces, territory state, armies as data, commanders, combat calculations, progress, and visual feedback.

War should have clear political objectives. Losing a war does **not** necessarily mean elimination.

Possible consequences may include territorial loss, forced vassalage, independence, political concessions, hierarchy changes, or other objective-specific outcomes. Conquest must **not necessarily** eliminate players.

**Exact war mechanics will be designed later.** Full warfare and detailed military simulation are deferred.

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

**Prestige** — reputation, status, renown, and political legitimacy. May eventually be gained through significant accomplishments (successful rule, warfare, political advancement, dynastic achievements, diplomacy, or other approved systems). May be used as a **requirement** for political actions. For title establishment: a **minimum Prestige threshold is required; that Prestige is not consumed**.

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

**Political Hierarchy Design V0.1 is specified in this document and is not implemented.**

**Current prototype priority (not to be implemented in documentation tasks):** the first meaningful gameplay prototype should focus on that **multiplayer political hierarchy**, not a deep autonomous character simulation.

That prototype must eventually prove the game can represent relationships such as:

- Player B → ruler of Player A
- Player B → Player A → Player C

The simulation must be capable of determining:

- Immediate ruler (direct liege)
- Direct vassals / direct subjects
- Indirect subjects
- Higher political authority
- Realm membership
- Political independence
- Top ruler of a hierarchy

It should eventually support changing these relationships through gameplay (including voluntary vassalage under the approved rank rules, preserving subordinate trees, and rejecting cycles), with the **server** validating results.

This hierarchy is a foundational dependency for later vassalage, realm formation, warfare, rebellion, territory, diplomacy, and victory conditions.

**Maps, title progression, naming, economy, and performance checkpoint** is specified in Titles & Territory, Economy, and Performance Philosophy. It is **documented, not implemented**. Exact formulas, map assets, currencies implementation, and monetization products remain unresolved.

## Explicitly Deferred Features

Part of the long-term vision, **not** authorized for immediate implementation merely because they appear here. Each requires **separate design approval** before implementation:

- Full warfare
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
- Exact title-scaling formula and numerical Duke/King/Emperor realm-control and Prestige thresholds
- Title-loss systems
- Vassal obligations (tax, military contribution, contracts, formulas)
- Independence gameplay methods
- Disconnect / reconnect behavior
- Join-in-progress mechanics
- Map artwork, geometry, renderer, interaction implementation, lobby/voting
- Gold / Prestige / Influence starting amounts, rates, caps, and formulas
- Crown prices, packages, earning methods, and exact cosmetics
- Lifetime Support calculations and monetization implementation
- Procedural naming algorithm and final geographic/political names
- Player replacement of AI rulers and detailed AI political behavior

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
