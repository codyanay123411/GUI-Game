# Political expansion and AI ruler plan

**Planning only — Director directions recorded 2026-10-15; no implementation authorization.** This is the authoritative expansion specification for the supplied political/AI discussion. **Direction** identifies Director requirements; **Recommendation** is not approved; **Decision needed** blocks the affected implementation. Discussion and arithmetic are not implementation evidence or Director acceptance. Existing gameplay remains active until an explicitly authorized replacement is integrated.

## Current baseline and boundaries

Current contracts: [authority, council and permissions](GAME_DESIGN.md#approved-political-authority-and-council-foundation--2026-10-13), [personal-domain autonomy/betrayal](GAME_DESIGN.md#approved-personal-domain-permissionsautonomybetrayal--2026-10-13), [Vale32/restart](GAME_DESIGN.md#approved-vale32-automatic-naval-and-shared-restart--2026-10-13), [Capital lifecycle](BUILDINGS_BALANCE_PROPOSAL.md#final-building-stage--capital-damagerepair-and-elimination--2026-10-14), and [architecture](../docs/ARCHITECTURE.md).

- Personal authority is `100 × personally owned conquerable provinces + total surviving personal real troops / 10`. Reservations, transports and Castle backing remain real troops counted once. Virtual Castle strength and combat modifiers, descendant holdings/armies, rank, Gold and Prestige add no authority.
- Existing direct-liege grants and strictly-stronger-subject autonomy cover personal external war/conquest and own-domain Alliance/NAP actions. They do not bypass treaties, costs, targeting, validation, match freeze or security. Existing betrayal transfers 30% of personal surviving troops; this plan does not retune it.
- Up to five direct-subject council seats currently grant no permissions or votes. Membership replacement's 10%/30-second policy is separate from immediate autonomy and the proposed government threshold.
- Capital capture currently eliminates its owner, surrenders personal land and enters spectating/reconnect protection. That implemented lifecycle is the migration baseline, not the new intended defeat outcome.
- Current titles are sequential manual player ranks with cumulative, unspent Prestige and subtree land eligibility. Vale has 32 conquerable definitions; Duke/King/Emperor requirements are 4/200, 10/500, 20/1,000 land/Prestige. Domination remains 70%, hence 23 provinces including subjects.

## 1. Defeat becomes forced vassalage

**Direction:** a defeated ruler becomes a subject of the ruler who defeated them and continues playing. This supersedes elimination as the intended future outcome; it does not yet replace live code.

**Recommendation, unapproved:** transfer the attacked Capital province normally, retain the defeated ruler's other personal provinces, surviving troops and remaining buildings, and replace mass surrender/elimination with forced vassalage. Buildings on the captured province follow that province; other buildings remain with their land. Resolve ordinary capture damage separately, without inventing damage on retained holdings.

**Decisions needed:** define the exact defeat trigger (Capital capture, final land, another condition); provide meaningful play after losing the last province; decide who receives overlordship when the winner is itself a subject. Specify defeats of existing subjects/ancestors and nested lieges without hierarchy cycles, treatment of existing descendants, active Capital versus ruins/replacement restrictions, engagements/transports/reservations and already mechanically resolved results. Define reconnect state and how old eliminated/spectator records migrate or reset. If territorial rank restrictions are adopted, define same-rank forced relationships rather than silently rejecting defeat.

Forced vassalage can immediately raise root-plus-descendant control to Domination. Victory evaluation order/freeze must remain deliberate; changing its threshold or excluding forced subjects is not approved.

## 2. Province grants

**Direction:** rulers can give away provinces, including to subjects, inspired by CK3.

**Recommendation, unapproved:** explicitly transfer selected personally owned land with its buildings and existing levels/Repair flags; peaceful grants cause no battle-damage roll. Settle the old owner's income/Prestige interval at the ownership boundary; subsequent personal income, Town capacity and land authority follow the new owner. Existing Gold and earned Prestige stay with their original owner; a grant to a subject keeps the land within the greater realm. No free troops are created. Existing over-cap retention is relevant if the giver loses a Town.

**Decisions needed:** recipient eligibility (humans/AI, direct/indirect subjects, outsiders), recipient acceptance, last-province protection and active Capital/ruin handling. Authority to give personal land never authorizes redistributing another subject's land. Reuse validated ownership/building transactions and match-generation/revision guards; political acquisition is a separate action.

## 3. Compensated acquisition by a liege

**Direction:** a liege can take subject territory by paying its current owner **30% of total territory value**, accounting for buildings/upgrades. The payment transfers liege Gold to owner; it is neither a sink nor newly minted Gold.

**Recommendation, unapproved valuation:** `province base value + cumulative individual level costs represented by existing buildings`. Current ordinary-building cumulative costs are **10/25/45/75/115**; Capital cumulative costs **15/40/75/120/180**. These derive from current approved price tables, not obsolete Farm/Town costs. Keep a valuation version/quote explicit if prices change; no rounding or historical-versus-current-cost basis is settled.

**Decisions needed:** province base value; damaged/Repair/Capital/ruin values; exact fractional payment/rounding; price-change policy; direct versus indirect subject reach; consent or democratic approval; final-land/Capital protections; repeated grant/acquisition abuse. Recommend a single validated ownership/payment transaction, never payment followed by a separately fallible transfer.

Acquisition shifts personal land authority toward the liege and away from the subject. Without political protections it could cheaply manufacture dictatorship or bypass democratic constraints; valuation alone does not solve that problem.

## 4. Authority-driven government

**Direction:** dictatorship requires the ruler's authority to be **at least 1.5 times the strongest subject's**. Below that boundary democracy activates automatically, without a council vote to initiate it; equality qualifies for dictatorship and reaching the boundary restores it. Preserve the current authority formula and real-troop accounting above.

**Recommendation, unapproved:** compare only direct subjects, independently at every hierarchy level. The no-eligible-subject case, eligible subject set and zero-authority case still require explicit policy. Do not silently apply council eligibility to government comparison.

**Decisions needed for playable democracy:** electorate and equal/weighted votes; actions needing approval; majority/quorum; deadlines/ties/abstentions/disconnects; ruler residual powers/vetoes; pending proposals during government transitions; interactions with immediate stronger-subject autonomy, war/treaties, grants and compensated acquisition. Existing council seats do not automatically become voters or gain powers. Rapid oscillation is a risk, but no delay/hysteresis is approved. A government label without action-approval rules is not an implemented democracy.

Exact authority/comparisons reveal military information and remain server-only under current privacy rules. Any additional government-state inference/audience must be designed explicitly; do not publish troop-derived scores in ordinary UI.

## 5. Territorial titles inspired by CK3

**Direction:** explore land hierarchy and grants inspired by CK3. Keep these concepts distinct:

| Concept | Meaning for the proposed design |
| --- | --- |
| Province/buildings | Direct ownership of playable land and its improvements |
| Territorial title | Proposed barony/county/duchy/kingdom/empire grouping or office |
| Personal domain | Provinces owned directly by that ruler |
| Greater realm | Ruler plus descendants' actual controlled land |
| De jure geography | Authored title groupings, distinct from current ownership/allegiance |

A higher territorial title does not automatically give personal ownership of every province beneath it. **Decision needed:** replace the existing Duke/King/Emperor player-rank progression or run a separate territorial-title system alongside it; define mapping before changing eligibility or rank retention. CK3's lower-rank-vassal restriction and subordinate-vassal transfers are reference mechanics only, not approved rules here. Do not import inheritance, claims, taxation, domain formulas or title-creation rules wholesale.

## 6. Personal domain allowance and overextension

**Approved direction:** apply equally to human and AI rulers; Lord allowance **2 personal provinces**; higher-rank allowance **75% of that rank's resolved map-specific land requirement**. Subject holdings do not use the liege's allowance. Do not hardcode Vale or derive from current claimed population.

**Recommendation, rounding unapproved:** `max(1, floor(requiredLand × .75))` above Lord. On current Vale32:

| Rank | Resolved title land | Proposed rounded allowance |
| --- | ---: | ---: |
| Lord | No establishment threshold | 2 (approved fixed allowance) |
| Duke | 4 | 3 |
| King | 10 | 7 |
| Emperor | 20 | 15 |

Purpose: encourage delegation and building tall. **Recommendation, not approved:** a soft allowance, with each excess province subtracting 10 percentage points from personal Gold income and adding 10 percentage points to recruitment cost, capped at −50%/+50%. Suggested Gold scope is base plus Farm income; suggested recruitment sequence is local Town price then surcharge. No troop disobedience, forced troop deletion, combat penalty or Prestige penalty is proposed.

**Decisions needed:** rounding/minimum, whether and when penalties apply, final amounts/caps, interaction/order with rank Gold bonuses and exact recruitment batches/affordability, rank-loss behavior and exemptions if any. Do not enable penalties before useful delegation exists in Solo/quiet servers. Limited personal land also makes the 1.5× requirement harder: a liege's large greater realm does not itself raise personal authority. Review this intended tension without changing the formula automatically.

## 7. AI rulers and quiet-server events

**Direction:** investigate random AI lords on quiet servers; AI recipients are a prerequisite before enabling domain penalties so a Solo ruler can delegate.

**Recommended foundation, not an approved implementation:** server-owned ruler IDs distinct from Roblox Player/UserId identities, using the same validated economy, personal ownership, buildings, troops, warfare/diplomacy and political rules. Bound population and decision frequency. No invisible income, invented armies or special authority advantages. Audit Player-dependent lifecycle, authorization, filtering/audiences and account lookup before adding non-player identities; never fabricate a Roblox account for an AI. Decide AI eligibility for the currently connected-player council rule and future voting rather than silently treating an NPC as a connected player.

**Recommendation, unapproved:** appoint an AI lord by granting a province, guaranteeing a recipient without waiting for a random event. Define activation/acceptance, resources and where any starting troops/Gold come from; do not silently clone a human's starting grant or current army. Normal approved income/recruitment may then operate through ordinary APIs.

**Random-event proposal, unapproved:** establish independent AI lords on eligible unclaimed land; announce arrival and provide preparation time; stop further spawning when human population rises; retain existing AI under explicit lifecycle rules. AI can become subjects, develop land and eventually delegate. **Decisions needed:** human thresholds, population cap, resource sourcing, cadence, preparation duration, targeting/behavior, names, human-arrival handling, disconnect replacement and AI delegation. Do not silently turn a disconnected player into an AI.

Use rule-based NPC decisions as the recommended first approach. No external LLM/API, paid inference or Discord integration is authorized. Define how AI chooses integer commitments, submits Ready/locks and honors existing defender/transport deadlines without stalling humans or gaining timing intelligence. AI must freeze at match end and clear/reset with the match; final inspection must remain coherent.

## Worked examples

Numbers below use current config; ownership/lifecycle outcomes and valuation base values are **hypothetical proposals**, not approved transactions.

1. **Lord delegates to AI:** with 3 personal provinces and 500 actual troops, authority is `300+50=350`. Granting one province leaves 2 personal and authority **250**, assuming troops stay put. An AI recipient with one province and **0** troops has authority **100**, not a free 500-troop army. Greater-realm control remains 3 if the AI becomes a subject. Lord allowance is 2; any penalty relief remains contingent on penalty/appointment approval.
2. **Grant/acquisition:** a liege with 2 provinces/500 troops has **250** authority; a subject with 3/500 has **350**. Granting one of the liege's provinces to that subject changes them to **150/450**. Instead acquiring one subject province from the original state changes them to **350/250**. Treasury payment changes neither score. A hypothetical base value **100**, Farm3 **45** cumulative cost and Town2 **25** yield value **170**, compensation **51 Gold**. A plain province with that hypothetical base would pay **30 Gold**.
3. **Exact government boundary:** against strongest-subject authority **250**, ruler **375** qualifies for dictatorship (`375 = 1.5×250`); **374.9** triggers democracy. For example, 3 personal provinces plus 750 actual troops gives 375; 749 troops gives 374.9 (one functioning Town2 can provide the 750 personal cap). A ruler at 350 versus 250 remains below 375 despite being personally stronger. A subject at 350 versus its ruler's 250 also retains the existing strictly-stronger autonomy comparison; the two thresholds are different.
4. **One-province defeat:** capturing the only province of a player with a Capital leaves zero personal land. Forced subjection alone supplies no income, Prestige generation, recruitment province or place to rebuild. Existing earned resources do not solve access to land. Choose land retention, a guaranteed grant/recovery route or another meaningful landless role before replacing elimination; none is approved here.
5. **Nested relationship:** A→B→C, with personal authority **600/450/250**. Under the recommended direct-only comparison, A is below **675** and would be democratic; B is at least **375** and remains dictatorial. C's land/troops are not added to B's score. If C defeats ancestor A, attaching A beneath C without restructuring A→B→C creates a cycle; winner, intervening links, descendants and title compatibility need explicit resolution.
6. **Victory:** on Vale32, a root controlling 18 provinces incorporating a separate 5-province realm through forced vassalage reaches **23**, satisfying existing Domination. All surviving subjects may continue in the hierarchy but the match still ends/freeze applies. Do not promise ongoing play after a victory-triggering defeat or silently raise the threshold.

## Dependencies and recommended delivery

This sequence is a recommendation, not a frozen commitment or coding approval:

| Stage | Deliverable and dependency |
| --- | --- |
| A | Settle defeat, grants and non-player identity decisions; define invariant/lifecycle contracts before transactions. |
| B | AI identity foundation plus functioning province delegation/appointment; first narrow playable milestone, including Solo recipient and income/capacity boundaries. |
| C | Forced-vassalage defeat, after landless recovery, cycle-safe hierarchy, Capital and battle-ledger lifecycle are decided. |
| D | Domain penalties only after humans/AI can actually delegate in Solo/quiet servers; allowance rounding and penalties need approval. |
| E | Compensated acquisition and real democracy approval/voting rules, designed together to prevent authority manipulation bypasses. |
| F | Territorial title groupings and random independent AI events, once identity/lifecycle and title compatibility exist. |

Before coding B, resolve recipient creation/consent, last-land/Capital protections and AI starting resources/identity/reset policy. Existing services remain authoritative; UI and AI are callers, not alternate state owners. Future verification should cover conserved payments/troops, exact ownership intervals, replay/stale requests, nested cycles, reservations/results, privacy, victory/freeze/restart and human/AI parity. No Studio session, runtime test, source/UI/config edit or gameplay acceptance is claimed by this documentation task.
