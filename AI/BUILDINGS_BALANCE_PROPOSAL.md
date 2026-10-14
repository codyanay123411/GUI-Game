# Buildings, Capital capture and actionable controls

2026-10-14 revision — **APPROVED FUTURE DIRECTION WITH UNAPPROVED BALANCE/LIFECYCLE RECOMMENDATIONS. Not implemented or playtested.** This supersedes the 2026-10-13 proposal where stated. Documentation-only revision; no gameplay/UI changes or Studio session. Publishing to Roblox is not authorized.

## Evidence and supersession

Relevant local sources inspected: EconomyConfig, MilitaryConfig, NeutralDefenseConfig, TitleProgressionConfig, ValePrototypeMap, RecruitmentPolicy, MilitaryCombat/VassalCombat and the existing ownership/lifecycle reports. [conquest report](CONQUEST_VICTORY.md) describes local 32-province/three-island work; it is not a claim that this work is committed on main. Prior scoped Studio evidence is reused, not refreshed. [Shared component contract](GAME_PRESENTATION_SETTINGS.md#gui-component-contract) remains the implementation reference until an authorized theme migration.

Runtime configuration currently remains 150 starting Gold, 10 Gold/min per personal province, 1000 starting Troops and 1 Gold → 3 Troops; this task does not change it. Neutral militia starts at 300, without regeneration; defenders persist after an unsuccessful attack. Gold pays on a six-second clock. Current personal Prestige is 20/province/min; titles on local Vale32 are Duke 4/200, King 10/500, Emperor 20/1000 and Domination 23/32. Rank Gold bonuses remain 0/0.5/1/2%. Subject strength is 9% +1% per immediate liege's direct subject; personal-land defense is 2% per own direct subject. No descendant resource share or ancestor stacking.

**Superseded recommendations:** starting Gold 200 and base income 15 are rejected, replaced by approved 100/5. Previous Farm +6-per-level and price tables are replaced by the recommendations below. Capital3 replaces neither level2 nor its strength bonus: +5% then another +10% means +15% total. Capital4's proposed construction discount is removed; it adds defense instead. Previous attack-only interpretation and lifecycle/slot/relocation/reconnect resolutions were suggestions, not approvals. The earlier 2026-10-13 conversation/file is historical provenance; useful conservation, server-authority, theme and staged-test analysis is retained here.

## Approved rules versus recommendations

**Approved:** four buildings, each placement at level1 then upgrades through level5; successive level costs must rise. Castle gives local defense, Town discounts recruitment, Farm adds fixed Gold/min. Each ruler has one Capital on personal land; its benefits exclude descendants. Starting Gold100, base personal income5/min; preserve current Prestige and automatically scaled title requirements. Capital capture eliminates its owner and surrenders remaining personal holdings to the attacker. Conquest damages 40–60% of existing buildings into Repair, preserving levels; repair costs50% of the applicable pre-damage-level cost. Damaged rows say Repair, unaffected rows incur no repair charge. Yellow actionable/dark unavailable or Max controls with reasons. These are future design approvals, not implementation acceptance.

**Still proposed:** all prices, Farm/Castle/Town values, Farm rank treatment, building slots, purchase timing, Town scope/formula, damaged-effect suspension, Capital strength applicability and all lifecycle edge resolutions below. No buildings, Capital capture or elimination exist in current gameplay. Ordinary conquest/subordination remains playable and distinct from this future elimination exception.

## Recommended five-level tuning

Costs are Gold for that individual placement/upgrade, not cumulative investment. Effects are total at that level. Recommend immediate validated purchases, sequential levels, no added construction timer. Recommend one slot each for Castle/Town/Farm plus Capital, but coexistence versus competing slots **requires approval**.

| Level | Castle cost / local defense | Town cost / discount | Farm cost / total additional Gold/min | Capital cost (proposed) / effects (approved) |
| --- | --- | --- | --- | --- |
| 1 | 25 / +5% | 30 / 5% | 20 / +3 | 40 / defense +10% |
| 2 | 40 / +10% | 45 / 10% | 35 / +7 | 60 / defense +10%, combat +5% |
| 3 | 65 / +15% | 70 / 15% | 60 / +12 | 90 / defense +10%, combat +15% |
| 4 | 100 / +20% | 110 / 20% | 100 / +18 | 130 / defense +15%, combat +15% |
| 5 | 150 / +25% | 165 / 25% | 160 / +25 | 180 / defense +15%, combat +15%, Prestige +10% |

No Capital means defense −5%. Level1 replaces .95 with1.10; level4 replaces1.10 with1.15. Combat progression is additive within that modifier (5% then +10%=15%), not multiplicative1.05×1.10. Defense and combat are separate factors. Level5 totals are exactly +15% defense, +15% combat, +10% personal Prestige income; no building-cost discount.

Recommend combat strength applies to **attack and defense**, sampled at mechanical resolution. This interpretation is **unapproved**. Offense would multiply by1.15 at Capital3–5; personal defense at Capital4–5 by1.15×1.15=1.3225, not1.30. Capital defense only applies when the actual defender directly owns the target; Capital combat applies to its owner's army, never descendants' army/land. Clarify root defense of a subject province before implementation: recommend no Capital bonus there, to honor the personal-territory limitation. Castle follows the target province, even if a different root ruler supplies its defense. Recommend damaged buildings provide no effects until repaired. All modifiers affect effective strength, not troop balances, reservations, authority or direct casualty counts; zero committed defense remains unopposed. Castle strengthening existing neutral militia on developed unclaimed land also requires approval, never creates militia.

With the recommended both-sided interpretation: subject of a five-subject liege has1.14, personal-land defender with three own subjects has1.06. Castle3/Capital5 gives1.14×1.06×1.15×1.15×1.15=1.8378 before rolls; same ruler without Capital gives1.3202. Capital3 offense×subject gives1.311. The existing defense roll1.00–1.05 remains separate. Combined uncapped hierarchy and buildings can strongly favor turtling; no existing vassalage rates are changed here.

Recommend rank bonuses apply to personal base+Farm income, excluding starting Gold/grants, with fractional carry and unchanged six-second payouts. Farm is province production; this avoids inconsistent income classes. Personal Prestige stays20/min/province, or22 with active Capital5; cumulative title eligibility is never spent. Subjects earn their own resources.

Town recommendation: strongest **undamaged personal Town**, max25%, no sum and no descendant contribution. Recruitment remains personal/global rather than adding province-local armies. Blocks = three Troops; maximum blocks=floor(floor(spendable Gold)×100/(100−discount)); selected blocks=floor(maximum blocks×stop/100); cost=ceil(blocks×(100−discount)/100). Positive blocks always cost at least1, never negative/free. Keep recruitment25/35/50/75/100 stops, commitments10/25/35/50/75. This proposed change selects a percentage of maximum affordable **troops**, identical to existing behavior at0% discount, rather than promising an exact percentage of Gold expenditure. Server revalidates quote/balance/Town on deliberate Recruit; previews never recruit, stale ownership can reject, no automatic spending. Town scope and bar interpretation both require approval.

## Low-income pacing and opportunity cost

These are lightweight arithmetic examples, not measured playability. Assume personal Lord land, no grants, unchanged starting1000 Troops, uninterrupted holdings and no spending except stated. Times omit acquisition/travel/decision delays; actual payout boundaries can delay affordability by up to a payout interval. The existing ~30-minute aspiration is not a new timer.

**Early conquest:** no declaration purchase cost exists. Five commitment stops on the initial1000 give100/250/350/500/750. Against300 militia, 500 gives an unmodified effective ratio1.43–1.83 across existing rolls, before proposed no-Capital defense semantics; its minimum450 exceeds militia maximum346.5, so arithmetic favors attacker victory. Current casualty bands charge winners10–25%: 50–125 actual Troops for a500 commitment (17–42 Gold to replace in three-Troop blocks). Three such favorable conquests could lose150–375 total, leaving625–850 without recruiting; later force previews change and victories are not guaranteed by this sketch. Neutral300 is an NPC, not automatically subject to a ruler's no-Capital penalty. Aggression can reach roughly four provinces from the starting army; the100 Gold buys at most300 replacement troops without Town. Income1province=5/min makes replenishment slow, a real risk rather than a hidden subsidy.

**Four-land opening:** base20/min, Prestige80/min. Capital1+four Farm1 cost120: from100 with no recruitment, the20 shortfall takes1 minute of base production. Buying Capital40 and two Farms40 leaves20, income26/min; third Farm can be bought immediately, leaving0 and income29/min, fourth needs20/29=0.69minute (~42 seconds plus payout alignment). Completed income32/min. Spending40 instead on120 troops may enable expansion; waiting for buildings must not be mandatory. Capital1 costs8 minutes of one-land base income or2 minutes at four land if starting funds were spent. Losing developed land interrupts payback.

| Farm purchase | Added income over previous level | Incremental payback (minutes) |
| --- | --- | --- |
| 1:20 Gold | +3 | 6.67 |
| 2:35 | +4 | 8.75 |
| 3:60 | +5 | 12 |
| 4:100 | +6 | 16.67 |
| 5:160 | +7 | 22.86 |

Full Farm investment375 adds25/min: simple completed-state payback15 minutes, but sequential financing postpones returns. Starting100 cannot max one immediately. Capital40 leaves60, enough for Farm1+2 (55), leaving5 and income12/min on one province. Level3's remaining55 takes4.58minutes, level4 at17/min needs5.88, level5 at23/min needs6.96: all levels finish about17.42minutes after this static start, with no recruitment or expansion. Increasing marginal paybacks discourage automatic maxing; if matches end too early, high levels are traps, not balanced choices.

| Representative settled holdings | Income/min | Gross production over10 /20 minutes at fixed state |
| --- | --- | --- |
| Wide:8 personal, no Farms | 40 | 400 /800 |
| Tall:4 personal, four Farm1 (80 cost) | 32 | 320 /640 |
| Tall:4 personal, four Farm2 (220 cumulative) | 48 | 480 /960 |
| Tall:4 personal, four Farm3 (460 cumulative) | 68 | 680 /1360 |
| Late:10 personal, four Farm3 | 98 | 980 /1960 |

These compare steady states, not free buildings or simulated acquisition. Relative to wide8, Farm2 tall4 leads8/min but spends220; that gap alone repays investment in27.5minutes. Farm3 leads28/min at460,16.43minutes. Wide may capture the investment and also has stronger land authority/title/victory progress; tall is viable funding/defense, not an alternative victory condition. King raises late98 to98.98; Emperor adds only2%, not a Farm snowball multiplier. At25% Town discount100 Gold buys399 troops for100 versus300; at10% it buys333. A30-Gold Town1 saves only~5% recruitment cost, needing about600 undiscounted Gold of recruitment to repay; it may be poor very early. Castle25 for5% defense competes with75 immediate recruits.

Prestige unchanged: stationary four personal land reaches Duke200 in2.5minutes; ten reaches King500 in2.5; twenty reaches Emperor1000 in2.5, subject to sequential manual establishment. A liege with two personal plus18 descendant land has Emperor land but needs25minutes fromzero Prestige (22.73 with Capital5). Capital costs total500 and gives late22 versus20 per province/min; acquiring23 lands may produce Domination before either Capital5 or Emperor establishment. Do not change title/victory rules to force upgrades. Four provinces and Farms reduce low-income waiting, but one-land players who spent100 have long recovery; measure this explicitly before calling the economy viable.

## Capture damage and Repair: approved core, unresolved policy

Server randomness, never client-selected: one receipt keyed by match generation, accepted capture ID and ownership revision; atomically choose distinct buildings once, record affected IDs and saved levels. Retried calls reuse the receipt. Preserve levels; damaged becomes Repair before Upgrade/Max, including damaged level5. Unaffected buildings remain active and owe no repair. No damage on merely decided/cosmetic fronts; apply at accepted ownership transfer.

**Count recommendation (unapproved):** for n existing buildings, sample f uniformly40–60%, then randomized-round n×f (floor plus Bernoulli of fractional part), sample that many without replacement. n=1 gives0 or1; n=2 may give0/1/2, mostly1; n=3 typically1/2; n=4 can give1/2/3, mostly2. No integer rule can literally damage40–60% for n=1 or3. This rule matches the fraction in expectation, not guaranteed per capture. Approval must choose this versus deterministic nearest-count with small-count exceptions. Recommend only currently undamaged functional buildings enter the draw; pre-existing Repair stays damaged without stacking costs/rerolls. Clarify whether 'existing buildings' includes inert Capital ruins before implementation.

**Repair basis recommendation (unapproved):** half the current-level individual purchase/upgrade price, not cumulative investment; round up to whole Gold. Farm3 would cost30, notceil(115/2)=58; Castle3ceil(65/2)=33. Farm5repair80 restores25/min (3.2minute standalone payback); Farm1repair10 restores3/min (3.33minutes). Four damaged ordinary level1 Farms/Towns/Castles across provinces can create meaningful upkeep without paying full build cost. A province with Castle3/Town2/Farm3 has recommended repairs33/23/30: if two uniformly selected, bill53–63, average57.33, rather than a free developed province. Capital cost basis remains defined even if the recommended ruin policy makes player repair unavailable.

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

First manageable implementation: after approval of Farm prices/slots/repair basics, Farm1–5 with Build drawer, approved100/5 economy and affected yellow/dark states. No Capital exposed until capture/elimination is complete. Second: Town quotes/rounding/bar, Castle modifiers and global control inventory. Third: Capital uniqueness/bonuses, damage and coordinated elimination together after lifecycle approvals. Server BuildingService owns levels/Capital/damage only; existing Economy/Military/Title/Territory services retain spending, troops, accrual and ownership. No client/admin authority expansion, new production chains/taxation/voting or loop duplication. Each stage includes affected generation/reset, receipt, ownership and compact theme checks.

Small proposed playtest: six players rotating aggression/development/cooperation starts over three sessions. Measure first capture/purchase/Capital, idle time waiting for funds, Farm payback achieved, Town savings, repair expenditure, captured development, title timestamps, Capital eliminations and match duration. Revisit if most matches finish<15minutes, first affordable actions require >3minutes idle after ordinary spending, no Farm pays back, >70% share one opening or >half Capital eliminations occur before minute5. These are investigation flags, not proven fairness/automatic retuning. Preserve100/5; tune proposed prices/effects only with approval. Check subject/root ownership and modifier conservation separately from economy pacing, not full historical suites.

Documentation checks: relevant configuration reads and arithmetic (payback, discounts, capital factors, four-land financing); local links/whitespace and actual planning diff reviewed. No runtime, multiplayer, Studio or human balance passes claimed for this revision. Next: resolve capture rounding/repair semantics, strength applicability and lifecycle policies before gameplay implementation.
