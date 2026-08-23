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

Players can exist at different levels of a political hierarchy. Conceptually this may resemble:

Emperor → King → Duke → Count

Exact final terminology and title requirements may be refined later.

Hierarchy is hierarchical and potentially recursive: a ruler may have subjects who themselves have subjects. Political authority ultimately flows upward.

The game must understand:

- Who a character’s **immediate ruler** is
- What **larger realm** that hierarchy belongs to

## Subordination Is Gameplay, Not Elimination

**Core principle.** Being conquered or becoming another player’s subject does **not** automatically remove a player from the match.

A formerly independent ruler may continue as a subordinate ruler.

Example: King Robert loses a war to Emperor Aldric. Robert may become Duke Robert, subject to Aldric’s realm. Robert remains an active player with territory, resources, political influence, relationships, military capability, potential subjects, and political goals.

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

The primary world representation is a **2D interactive political map**.

- Territories should be clickable and able to display relevant information.
- The map should visually communicate political control and realm relationships.
- The map exists primarily to communicate strategic and political information.

There is no requirement for a traditional explorable 3D Roblox world.

Exact title ranks, map topology, and territorial rules beyond the conceptual hierarchy above remain unspecified until designed.

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

Exact diplomatic mechanics are unspecified until designed. Do not implement a full diplomacy system from this list alone.

## Realm & Vassal Management

Vassalage, realm formation, and recursive subject relationships are foundational. Large realms should create internal political gameplay. Powerful subjects should matter.

A large empire should potentially be powerful externally while politically unstable internally.

Exact realm-administration mechanics remain unspecified until designed.

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

Possible consequences may include territorial loss, forced vassalage, independence, political concessions, hierarchy changes, or other objective-specific outcomes.

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

Characters may possess wealth. An **economic** victory category is conceptual (overwhelming economic influence of a player or political hierarchy).

**Detailed economy, buildings, and development are deferred.** Exact economic mechanics will be designed later.

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

The GUI is the **primary game environment**.

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

NPCs may fill supporting roles humans cannot reasonably fill. Human players drive major geopolitical decisions.

**Advanced AI rulers** are part of the long-term vision and are **not** authorized for immediate implementation.

## Saving/Persistence

Match structure is a shared ~30-minute session on a server of ~50 players. Detailed saving/persistence mechanics are **unspecified** and not authorized by this document. Persistence remains a later roadmap concern unless directors design it.

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

**Current prototype priority (not to be implemented in documentation tasks):** the first meaningful gameplay prototype should focus on the **multiplayer political hierarchy**, not a deep autonomous character simulation.

That prototype must eventually prove the game can represent relationships such as:

- Player B → ruler of Player A
- Player B → Player A → Player C

The simulation must be capable of determining:

- Immediate ruler
- Direct subjects
- Higher political authority
- Realm membership
- Political independence

It should eventually support changing these relationships through gameplay.

This hierarchy is a foundational dependency for later vassalage, realm formation, warfare, rebellion, territory, diplomacy, and victory conditions.

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

## Long-Term Vision

A ~30-minute, ~50-player Roblox match in which players create fictional political history through character-driven hierarchy, diplomacy, war, religion, dynasty, and internal politics — with multiple non-elimination victory paths, GUI-first presentation, and subordination remaining playable.

## Current Development Philosophy

- Directors define game mechanics.
- Implementation agents implement those mechanics.
- Agents must not invent major game systems merely because a concept appears in this document.
- Unspecified mechanics remain unspecified until designed.

## Authority

`AI/GAME_DESIGN.md` is the authoritative product vision. Directors determine design direction. Agents implement approved designs and must ask when an important mechanic is unspecified.
