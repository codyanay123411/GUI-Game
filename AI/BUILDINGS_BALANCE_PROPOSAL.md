# Buildings, Capital capture and actionable controls

2026-10-14 latest Director revision — **APPROVED FUTURE RULES; RECOMMENDED NUMERIC TUNING AND UNRESOLVED POLICIES. Not implemented or balanced.** Planning only. [Reference stat sheet](BUILDINGS_REFERENCE_STATS.md) distinguishes agreed arithmetic from assumptions.

## Evidence, scope and supersession

Current local evidence: EconomyConfig remains150 starting Gold/10 per personal province/min; MilitaryConfig remains1000 starting Troops/3 Troops per Gold; NeutralDefenseConfig remains300 militia. TitleProgressionConfig remains20 personal Prestige/province/min, with local Vale32 titles4/200,10/500,20/1000 and Domination23/32. Rank Gold is0/0.5/1/2%; fractional carry and six-second payouts exist. Existing combat/hierarchy/reservation and [conquest report](CONQUEST_VICTORY.md) evidence is reused; local Vale32/source work remains uncommitted, not assumed to be on GitHub. No Studio inspection or runtime tests in this task. Shared [theme/component contract](GAME_PRESENTATION_SETTINGS.md#gui-component-contract) remains implementation authority until authorized migration.

This revision supersedes all earlier active Farm tables, including +60/+10/+7 maximums mentioned in Director history, the previous local +25 maximum and +6-per-level recommendation. **Approved Farm totals are2/5/9/14/20**, exceeding the earlier1–10 limit deliberately. Reject200-start/15-base; approved future economy is100/5. Supersede percentage Castles with local fixed defensive strength and percentage/global/strongest-Town recruitment with fixed province-local discounts. Capital3 remains additive15% combat; remove obsolete Capital4 construction discount. Earlier 2026-10-13 and earlier2026-10-14 proposals/commits preserve provenance only; their rejected mechanics/prices are not current instructions. Retained prices below are provisional recommendations, never automatic approvals.

## Approved rules and recommended tables

**Approved:** Starting Gold100; base personal province income5/min. Each Farm independently adds its province's fixed total2/5/9/14/20, replacing its earlier-level value. Rank bonus applies to base+Farm production, with existing fractional accounting. Prestige rate and automatic title scaling remain intact. Castle/Town/Farm/Capital have placement1 then four upgrades; successive prices increase. Castle is local non-troop strength; Town benefit is fixed and province-local. One active Capital on personal land, excludes descendants. Capture/Repair, elimination and yellow/dark direction below remain approved only to their explicitly stated extent.

**Unapproved:** Castle point table, Town price/discount table and whole-batch contract; every purchase price, slots, instant purchase timing, Castle support allocation/transition, local recruitment capacity, Capital combat applicability to defense and garrisons; repair and elimination edge resolutions. Recommended coexistence is one slot each Castle/Town/Farm plus Capital, not approved. No new armies, taxes, voting or production chains.

| Level | Farm total added Gold/min (approved) | Castle points / maximum strength (recommended) | Town local Gold discount per100-Troop batch (recommended) | Capital total effects (approved) |
| --- | --- | --- | --- | --- |
| 1 | +2 | +2 /100 | 2 (price98) | +10% defense |
| 2 | +5 | +4 /200 | 4 (price96) | +10% defense, +5% combat |
| 3 | +9 | +6 /300 | 6 (price94) | +10% defense, +15% combat |
| 4 | +14 | +8 /400 | 8 (price92) | +15% defense, +15% combat |
| 5 | +20 | +10 /500 | 10 (price90) | +15% defense, +15% combat, +10% personal Prestige |

| Level | Castle purchase price | Town purchase price | Farm purchase price | Capital purchase price |
| --- | --- | --- | --- | --- |
| 1 | 25 | 30 | 20 | 40 |
| 2 | 40 | 45 | 35 | 60 |
| 3 | 65 | 70 | 60 | 90 |
| 4 | 100 | 110 | 100 | 130 |
| 5 | 150 | 165 | 160 | 180 |

All purchase prices remain recommendations. They are individual level purchases, not cumulative cost; levels/effects replace earlier totals. Capital absent defense−5%;1 replaces penalty with+10%;2 adds5% combat;3 adds another10% (15% total);4 adds5% defense (15% total);5 adds10% personal Prestige. No construction discount. Current-rank Gold applies to Farm+base, never grants/starting Gold or descendant income. Capital5 gives22 personal Prestige/province/min, not earned-Prestige multiplication.

## Castle support recommendation — unresolved

Each recommended defense point equals50 fixed troop-equivalents. Unsupported Castle provides25% maximum even at zero committed defense; full support requirement is three times this **unmodified** baseline. Level1–5 baselines25/50/75/100/125, requirements75/150/225/300/375 real Troops, full contributions100/200/300/400/500. Percentage buffs never raise support requirement. Castle cannot attack, recruit, enter Troop Total or political authority. Future combat must distinguish zero real defenders with a nonzero Castle from the current unopposed branch; do not bypass a functioning Castle as zero defense.

**Recommended simple standing-reserve policy, not approved:** support comes from otherwise available personal Troops, exclusively earmarked server-side when a defense engagement begins; cannot also be committed, recruited-as-new or support another simultaneous defense. Allocate in accepted defense-start time/war-ID order; release on cancellation/conclusion through Military accounting. Freeze an allocation for that engagement, so later recruitment cannot silently resubmit it. Recommend linear partial support: Castle contribution=baseline+(maximum−baseline)×min(allocated/requirement,1). Require approval over partial versus all-or-nothing and committed-defender versus reserve interpretation. Earmarked support remains real surviving Troops in Total/authority; do not add those troops a second time to actual committed defending strength. Whether supporting reserves suffer casualties or provide only backing is unresolved; recommend backing-only for the smallest first policy, explicitly visible in own ledger. This is a new reservation purpose needing conservation tests, not assumed existing behavior. Twenty level5 Castles need7500 exclusive supporters to reach full strength simultaneously under this policy; their virtual strength is not a movable army.

Capital combat on **both attack and defense**, including Castle garrison strength, remains an assumption needing confirmation. Under that assumption personal defense combined percentage factor at max Capital is1.15 combat×1.15 defense=1.3225, before other modifiers. Existing subject factor1.14 (five immediate-liege subjects) and personal defense1.10 (five own subjects) give1.311 combat and1.265 separate defense. Multiply independent factors, no ancestral stacking or troop/authority inflation. See exact garrison arithmetic in the reference sheet. Actual defending Troops contribute separately; do not confuse unsupported Castle strength with real troops or support cost. Capital personal scope excludes descendant targets: root defending a subject province must not borrow that root's personal Capital modifier; this boundary needs explicit confirmation.

## Province-local Town recruitment — recommended contract, not approved table

Recommended base100 Gold per whole100-Troop batch; local Town discounts2/4/6/8/10 Gold, max price90. Only Town on the selected personally owned recruitment province applies; damaged-effect policy still unresolved. Recruit adds to existing shared personal pool, never creates province armies. This replaces current3 Troops/Gold and multiple-of3 validation: **whole-batch recruitment is a proposed contract change**, requiring explicit approval and service/preview changes together.

Recommended bar interpretation: available batches=min(floor(spendableGold/localBatchPrice), localCapacity); selected batches=floor(availableBatches×stop/100); Troops=100×batches, Gold=price×batches. Use existing25/35/50/75/100 stops;0 batches is a disabled preview/reason, not a selectable0 stop. Opening at25% does not recruit. Server revalidates source ownership, capacity, price, funds and request receipt on explicit Recruit. Whole batches mean100 Gold at base affords1 batch:25/35/50/75 all round to0; only100% recruits. Show this honestly, not fractional batches. Commitment stops remain10/25/35/50/75.

Extra Towns otherwise have little value: unlimited instant recruitment can repeatedly use the best one. **Capacity recommendation requiring approval:** each personal province can recruit up to2 batches per60-second window, with no accumulated catch-up; each Town level adds1 batch of local capacity (3–7). Spending consumes local capacity, not troops from an imaginary local army; server ownership revision/window bookkeeping prevents transfer/reconnect refresh exploits. Reset at shared match restart. This adds a real local constraint and needs explicit approval of amount, clock, transfer semantics and whether Town capacity scales; it is not approved by the fixed-discount direction. A smaller rollout could omit capacity initially but must disclose that multiple Towns then offer limited utility, not claim this solved.

## Lightweight balance analysis

Assume Lord income, fixed holdings/no grants, current starting1000 Troops retained unless later approved otherwise. Calculations are hypotheses, not match simulations. Low100-start/5-base remains fixed direction, not raised to compensate for new recruitment prices.

Farm incremental payback at proposed prices:20/2=10min;35/3=11.67;60/4=15;100/5=20;160/6=26.67. All levels cost375 and add20/min: completed-state simple payback18.75min; sequential financing delays returns. Rank2% shortens payback only by about2%. Starting100 cannot max a Farm; expensive late levels may not pay back before match end. Capturing developed land is attractive, subject to Repair costs and lost production. Four Farm1 cost80, raise four-land20/min to28/min. Capital1+four Farm1 cost120: buyCapital40+threeFarms60, leaving0, income26/min; fourth needs20/26=0.769min (~46seconds plus payout alignment). Acquisition time/casualties are omitted. Four-land Capital/Farms is viable as an opening hypothesis, not guaranteed dominant. One land after spending all100 waits8 minutes for recommendedCapital40 or4 minutes forFarm20, a significant waiting risk.

| Settled state | Gold/min (before rank) | Gross10 /20min from that state |
| --- | --- | --- |
| Wide8 personal, no Farms | 40 | 400 /800 |
| Tall4, Farm1 on each (80 investment) | 28 | 280 /560 |
| Tall4, Farm2 on each (220 investment) | 40 | 400 /800 |
| Tall4, Farm3 on each (460 investment) | 56 | 560 /1120 |
| Tall4, Farm5 on each (1500 investment) | 100 | 1000 /2000 |
| Late10, four Farm3 | 86 | 860 /1720 |

Buildings are paid, not free starting states. Farm2 tall4 matches wide8 production but trails land/title/authority; Farm3's16/min lead needs28.75minutes to recover460 relative to that wide state. Development has less conquest exposure but is capturable; do not claim proven tall viability or a separate tall victory. Emperor on late86 gives87.72; reference20 max Farms gives510. Personal Prestige/title timing unchanged: four land Duke200 takes2.5minutes fromzero, ten King500 takes2.5, twenty Emperor1000 takes2.5, sequential manual establishment still required. Liege with2 personal/18 descendants needs25minutes for1000 Prestige (22.73 atCapital5). Domination23 may precede high title/Capital upgrades.

Current militia300, favorable500-Troop attack wins arithmetically over ordinary300 militia across current roll bounds (minimum450 vs maximum346.5), before future Castle/Capital changes. Winners lose10–25%, or50–125 actual Troops for500 commitment. Existing starting1000 can fund early neutral expansion without Gold declarations, but the **proposed**100/batch price makes replacing these losses cost100–200 Gold in whole batches, instead of current17–42. At one province5/min that is20–40minutes of production; four20/min means5–10minutes. The initial100 only buys100 troops (also at Town5,90 leaves10), compared with300 under current rules. Castle fixed100 atlevel1 for25 may be a strong early defense purchase versus100-Troop recruitment100; explicitly test Capital rush/turtling and recovery. This price table is a substantial military-economy retune, not approved or proven affordable for sustained war.

Town5 discount10 saves10 perbatch (11.11% purchasing-power improvement before batch rounding); proposed Town investment420 requires42 batches to repay from discount alone. Extra capacity, if approved, may be its major utility, but this cost may be too high. No percentage/global Town stacking. Farm5repair80 restores20/min (4min payback); Castle5repair75 restores local strength, not recruitable troops. Capital1 removes−5% and gives+10% defense but exposes decisive elimination; raid targeting and initial1000 armies can make Capitals a liability. Measure fund-waiting and early elimination before approving prices. No new rates/timers or automatic balancing.

## Capture damage and Repair: approved core, unresolved policy

Server randomness, never client-selected: one receipt keyed by match generation, accepted capture ID and ownership revision; atomically choose distinct buildings once, record affected IDs and saved levels. Retried calls reuse the receipt. Preserve levels; damaged becomes Repair before Upgrade/Max, including damaged level5. Unaffected buildings remain active and owe no repair. No damage on merely decided/cosmetic fronts; apply at accepted ownership transfer.

**Count recommendation (unapproved):** for n existing buildings, sample f uniformly40–60%, then randomized-round n×f (floor plus Bernoulli of fractional part), sample that many without replacement. n=1 gives0 or1; n=2 may give0/1/2, mostly1; n=3 typically1/2; n=4 can give1/2/3, mostly2. No integer rule can literally damage40–60% for n=1 or3. This rule matches the fraction in expectation, not guaranteed per capture. Approval must choose this versus deterministic nearest-count with small-count exceptions. Recommend only currently undamaged functional buildings enter the draw; pre-existing Repair stays damaged without stacking costs/rerolls. Clarify whether 'existing buildings' includes inert Capital ruins before implementation.

**Repair basis recommendation (unapproved):** half the current-level individual purchase/upgrade price, not cumulative investment; round up to whole Gold. Farm3 would cost30, notceil(115/2)=58; Castle3ceil(65/2)=33. Farm5repair80 restores20/min (4minute standalone payback); Farm1repair10 restores2/min (5minutes). Four damaged ordinary level1 Farms/Towns/Castles across provinces can create meaningful upkeep without paying full build cost. A province with Castle3/Town2/Farm3 has recommended repairs33/23/30: if two uniformly selected, bill53–63, average57.33, rather than a free developed province. Capital cost basis remains defined even if the recommended ruin policy makes player repair unavailable.

Recommend suspend **all** damaged effects until repaired: Castle defense, Town discount, Farm income, active Capital bonuses. This requires explicit approval, especially damaged Capital: recommend damaged is still the unique Capital/capture objective, receives no bonuses and incurs no-Capital defense penalty until repair; damage must never shield it from decisive capture. Revalidate effects, settle Prestige rate boundaries, preserve normal Gold payouts and actor privacy. Repair is paid by current direct owner, no refund/upgrade until repaired. Distinct damaging captures may damage previously repaired buildings again; duplicate/admin/surrender events cannot.

**Separate transfer recommendations, unapproved:** no random damage/elimination on admin transfer; log and deactivate outgoing active Capital without gifting an active one, repair only through explicit AdminBridge correction when warranted. Mass surrender transfers ordinary existing levels/Repair flags with **no second damage roll**; only the directly conquered province rolls. Disconnect retains ordinary buildings/Repair on now-unclaimed land, deactivates its Capital into an inert marker; no later Capital elimination of a departed owner. Shared restart clears buildings/damage/receipts. These policies must be approved before implementation.

## Elimination/hierarchy: recommendations only, NOT approved resolutions

Approved capture eliminates the owner and surrenders their **personal**, not descendant, holdings. Recommend recipient is accepted attacker ID using personal resources, including autonomous subject and nested betrayal, never automatically root liege. Captured Capital becomes an inert historical ruin; does not become attacker's second active Capital or inherit its effects. Whether it occupies a slot/can be cleared/rebuilt and counts for damage remains unresolved. Recommend no moving/demolishing an active Capital or player rebuilding it in the same match, preventing capture avoidance; this restriction is unapproved.

Retain earlier recommended safe integration: non-yielding transaction at existing post-result ownership boundary; revalidate Capital revision and actors, settle Prestige interval, retain already-applied mechanical casualties once, keep existing Gold payout clock, mark elimination and transfer personal land. Recommend detach defeated owner; direct subjects become independent retaining descendants/resources/Capitals. Recompute councils/domains; invalidate affected offers, remove defeated treaties, never inherit them automatically. These hierarchy/treaty/council choices remain unresolved.

Recommend Military cancel unresolved eliminated/domain-stale wars/transports using existing survivor/refund conventions. For already mechanically decided results retain casualties/result once, release survivors, suppress stale ownership transfer with readable superseded-result feedback. Retire defeated survivors into an explicit inactive ledger, not attacker troops or silent deletion; freeze Gold/Prestige/rank inspection, no new earnings/actions. Conservation must cover total-before, casualties, surviving releases and retirement. Exact ongoing-war/troop-retirement policy requires approval.

Recommend finalizations ordered by `(presentationEndsAt, warId)` within due batch, each Capital receipt once. First elimination may prevent later attacker ownership mutation while preserving its calculated casualties; crossed Capitals cannot create troops/duplicate estates. Evaluate Domination after the batch's final ownership/hierarchy to avoid transient wins. This timing policy is **unapproved**, including captures before another result finalizes.

Recommend elimination keeps connected spectating/result inspection/restart votes; chat follows existing eligibility/filtering with no new audience and no retained stale Council/Allies access. Details require approval; no private enemy military display. Landless-without-captured-Capital stays playable per current rules, earns zero, cannot place without land. Normal late-join/end inspection stays unchanged. Proposed eliminated UserId tombstones until shared restart prevent reconnect avoidance, but conflict with current disconnect wipe/reconnect reset: explicitly unresolved, no assumed exception. Ordinary elimination must not call generic disconnect removal.

## Build menu and yellow-action theme

Reuse personal province → Build → existing right contextual drawer, four measured rows, vertical compact scrolling; no duplicate progression/build panel. Show level, next effect/cost and concise reason. Healthy absent: Build; present<5: Upgrade; healthy5: Max; damaged at any level: Repair with restored effect and cost, never Upgrade. Pending says Building/Repairing, disables repeat requests; unaffordable/unavailable/Max dark with reason, enabled Build/Upgrade/Repair yellow. Opening never spends. Server checks ownership/level/revision/generation/funds/unique Capital and idempotent receipt; UI predicts only. Final/defeated remains inspectable, no build edits. Preserve drawer transitions, non-button map pass-through and shared font/density/opacity settings.

Approved global direction does not blacken every passive surface or change political map colors. Treatments below remain recommendations:

| Ambiguous surface | Recommended treatment for approval |
| --- | --- |
| Selected navigation | Yellow while enabled, outline/check for selected; selection is not disabled |
| Toggles | Enabled On/Off both yellow, text/check/knob conveys state; dark means unavailable, not Off |
| Bar stops | Enabled stops yellow, selected marker/outline; neutral track; retain map input isolation |
| Destructive confirmation | Yellow actionable fill with red warning icon/border and explicit consequences; no unexplained danger exception |
| Pending / Max / unaffordable | Dark readable text, visible status/reason; no hover/activation |
| Read-only cards/wells | Retain slate/neutral and normal text; do not label passive surfaces disabled |
| Admin/vendor | Project-owned controls follow shared roles; supported Kohl adapter only, no vendor fork or assumed global recolor of native chrome |

Use shared theme/component roles for generated/reopened controls and distinct focus/hover feedback; disabled reasons must not require clicking a disabled button. Theme migration is future work, not applied here.

## Staged delivery and measurable playtest

First manageable implementation: after approval of Farm prices/slots/repair basics, Farm1–5 with Build drawer, approved100/5 economy and affected yellow/dark states. No Capital exposed until capture/elimination is complete. Second: province-local whole-batch Town quotes/capacity/bar, Castle support allocation and global control inventory. Third: Capital uniqueness/bonuses, damage and coordinated elimination together after lifecycle approvals. Server BuildingService owns levels/Capital/damage only; existing Economy/Military/Title/Territory services retain spending, troops, accrual and ownership. No client/admin authority expansion, new production chains/taxation/voting or loop duplication. Each stage includes affected generation/reset, receipt, ownership and compact theme checks.

Small proposed playtest: six players rotating aggression/development/cooperation starts over three sessions. Measure first capture/purchase/Capital, idle time waiting for funds, Farm payback achieved, Town savings, repair expenditure, captured development, title timestamps, Capital eliminations and match duration. Revisit if most matches finish<15minutes, first affordable actions require >3minutes idle after ordinary spending, no Farm pays back, >70% share one opening or >half Capital eliminations occur before minute5. These are investigation flags, not proven fairness/automatic retuning. Preserve100/5; tune proposed prices/effects only with approval. Check subject/root ownership and modifier conservation separately from economy pacing, not full historical suites.

Documentation checks: relevant configuration reads and arithmetic (payback, discounts, capital factors, four-land financing); local links/whitespace and actual planning diff reviewed. No runtime, multiplayer, Studio or human balance passes claimed for this revision. Next: resolve capture rounding/repair semantics, strength applicability and lifecycle policies before gameplay implementation.
