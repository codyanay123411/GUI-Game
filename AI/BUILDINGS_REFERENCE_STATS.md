# Buildings reference stats — 2026-10-14

Planning calculation sheet, **not implemented behavior or proven balance**. Current rules, proposed tables and unresolved assumptions are separated below; [balance proposal](BUILDINGS_BALANCE_PROPOSAL.md) owns detail and remaining decisions.

Scenario: 20 personally owned provinces with Castle/Town/Farm level5 on each and **one** active Capital level5; five direct subjects; this ruler is also subject to a liege with five direct subjects; Emperor rank for Gold. This assumes the proposed coexistence slots permit the scenario, not 20 Capitals.

| Stat | Result | Status |
| --- | --- | --- |
| Base Gold income | 20 ×5 =100/min | Approved future economy |
| Farm Gold income | 20 ×20 =400/min | Approved future Farm totals, independently per province |
| Total Gold income | 500/min | Derived approved totals, before rank |
| Emperor Gold income | 500 ×1.02 =510/min | Approved rank-on-base-plus-Farm; existing rank rate/fractional accounting |
| Base Prestige income | 20 ×20 =400/min | Existing personal earning rule retained |
| Capital-adjusted Prestige | 440/min | Approved future +10% personal earning |
| Subject strength | +14% | Existing 9% +1% ×5 immediate-liege subjects |
| Capital combat strength | +15% | Approved future total; applicability below unresolved |
| Combined combat modifier | 1.14 ×1.15 =1.311 (+31.1%) | Conditional on Capital combat applying in the context |
| Separate defense modifier | 1.15 ×1.10 =1.265 (+26.5%) | Capital defense and existing five-direct-subject personal-land defense |
| Max Castle unsupported strength | 125 before modifiers | Conditional recommended level5 maximum500 × approved25% baseline |
| Support requirement | 375 real Troops per Castle | Conditional recommended table; approved3 ×125 unmodified baseline |
| All20 fully supported simultaneously | 7500 real Troops | Assumes exclusive support allocation; policy unresolved |
| Max Castle full contribution | 500 before modifiers | Recommended +10 points ×50; numeric table unapproved |
| Unsupported Castle after all assumed modifiers | 125 ×1.311 ×1.265 =207.301875 | Assumes Capital combat and all applicable defensive factors affect garrison |
| Supported Castle after those modifiers | 500 ×1.311 ×1.265 =829.2075 | Same unresolved modifier assumptions |
| Authority with7500 surviving Troops | 20 ×100 +7500 ÷10 =2750 | Existing personal authority formula; Castle strength excluded |
| Proposed max Town price | 90 Gold per100 Troops | Unapproved base100 minus fixed local discount10 |

Castle figures exclude separate actual committed defending strength and combat/defense random rolls. Twenty Castles create no movable army; support is real existing troops, not a grant. Reservations remain in surviving Total for authority. Modifiers cannot raise the375 support requirement. Do not treat7500 as simultaneously available for support **and** commitments elsewhere.

Approved future Capital levels: absent−5% defense;1 replaces penalty with+10% defense;2 adds5% combat;3 adds10% for15% total;4 adds5% defense for15% total;5 adds10% personal Prestige. These exclude descendant holdings. Independent modifiers multiply, no ancestor stacking. Whether combat applies to defense and Castle garrisons must be confirmed; the two207.301875/829.2075 figures are expressly conditional, not promises.

Unresolved: committed versus reserve support, exclusive allocation/partial transition and support casualty policy; slots, local recruitment capacity, whole-batch contract, prices, repair semantics and elimination lifecycle. No troop total or private enemy strength should be exposed through ordinary UI merely to reproduce this sheet.

Checked with lightweight exact-decimal arithmetic; no Studio, match run or balance acceptance. Supersedes conflicting older reference values; historical prototypes remain dated in existing records.
