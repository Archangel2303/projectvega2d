# Tower of Vega — Working Design Reference

This document consolidates the game vision shared so far. It is intended as a
portable project reference for future design and implementation work. The
system summaries capture the current direction; conflicts listed under **Open
questions** remain unsettled and should not be silently resolved by inventing
rules.

## 1. Project at a glance

- **Genre and presentation:** 2D pixel-art, turn-based roguelike deck-builder
  with node-based runs, build-driven combat, and persistent account progression.
- **Setting:** The Tower of Vega, a former luxury mega-structure turned into a
  lethal broadcast spectacle after societal collapse.
- **Player fantasy:** Build a powerful, expressive combat setup from augments,
  equipment, consumables, and synergies; survive increasingly dangerous floors
  using tactical choices.
- **Difficulty goal:** Bosses should be demanding but fair. Access conditions
  are boss-specific; temporarily limiting the boss pool to support repeated
  balance testing is a developer test setup, not player-facing progression.
- **Visual reference:** The supplied player-character concept depicts a rugged,
  blond, heavily equipped wasteland survivor with a rifle, layered scavenged
  clothing, armor, packs, and cyan-lit technology. The shipped game target is
  pixel art; the concept image is a design reference, not the final art style.

## 2. Run structure and exploration

### Floors and progression through a run

- A standard run has **five floors**, begins on Floor 1, and ends on Floor 5.
- The initial estimate was **15–25 unique floor designs**; the current main
  catalog has 15 floors plus secret floors (see §20 for the status of this
  change).
- Mid-run floors are drawn from a deck/pool of floors (the shared example says
  Floors 2–15) and should ascend in difficulty.
- Enemy strength is based on **run progression**, not simply the raw floor
  number.
- Each floor has its own theme, enemies, and encounters; recurring enemies can
  return with scaling where appropriate.
- Every floor ends with a boss. Mini-bosses may appear mid-floor.
- Rest is always available before the floor boss.

### Node types

- Combat
- Elite / mini-boss
- Shop (for example rogue-AI traders or cult vendors)
- Random encounter / event
- Rest
- Removal shop

Rest offers a choice between **Rest** (heal) and **Tune** (upgrade an augment).
Events can appear through random-encounter nodes or flag triggers.

### Deck and draw logic

- **Node decks:** Drawn per floor to create its route. One example composition
  is four combats, one mini-boss, one shop, and one rest; this is an example,
  not a locked count.
- **Event deck:** Each random-encounter node has a 30–50% chance to draw an
  event.
- **Augment deck:** Drop pool is seeded/modified by floor progression and flags.
- **Enemy decks:** Each floor draws from a curated enemy list, with chances for
  rare or flag-gated enemies.
- **Secret decks:** Available only when conditions are met; may contain event
  chains, special floors, or hidden shops.

## 3. Combat systems

### Combat engine design philosophy: containers and effects

The combat engine should use a simple **container-and-effect** model. Containers
hold game data and organize ownership; effects are the executable operations
that change game state.

- **Player character container:** Holds character stats, equipped augments, and
  inventory contents such as unequipped augments, Nanites, and Echoes of
  Elysium.
- **Enemy container:** Holds enemy stats and abilities.
- **Augment container:** Holds augment identity and metadata, including
  archetype/brand, along with its abilities. An augment generally has one or
  two activatable abilities, may have a passive, and almost always provides an
  Overdrive or Herculean ability as appropriate to its archetype.
- **Ability container:** Holds one or more effects. Effects perform the actual
  gameplay operations, such as dealing damage, granting Block, healing, or
  applying a status.
- **Consumable container:** Holds its effects like an ability, but is generally
  consumed after one use.

Containers describe what owns or groups information; effects describe what
happens. Keep this as the conceptual model for combat content without requiring
every container to behave as a specific implementation class.

### Focus

- Start with **3 Focus**.
- At the start of each turn, Focus refreshes up to the current cap; unspent
  Focus does not carry over unless a specific effect says otherwise.
- Focus generated during combat can exceed the cap.
- Focus is the main action-economy resource.
- Starting combat actions:
  - **Punch:** 5 damage, costs 1 Focus (called “mana” in the original note).
  - **Block:** 7 block, costs 1 Focus.
  - **Hack:** No base hack actions defined yet.
- The player also has an **Item/consumable** menu. Overdrive starts inactive
  until its unlock condition is met.
- Base player HP is **100/100**.

### Overdrive

- Overdrive is a battle-menu option and its abilities are tied to equipped
  augments.
- Overdrive abilities cost Focus. Each has an independent Focus cost and
  cooldown; a powerful ability can therefore be expensive but come back sooner,
  or be cheap but have a longer cooldown.
- More powerful moves can misfire. Misfire is a tunable stat affected by
  augments, statuses, floors/boss auras, flags, gear, and relics.
- Misfire outcomes can include backlash, glitch, or partial/reduced success.
- Lower HP softcap levels deepen Overdrive scaling and risk. The intended
  direction is to let scaling reach very low softcaps (as low as 5%) with
  commensurately greater risk and reward.
- A maximum effect bonus may be used to keep the system powerful without
  spiraling out of control.

### Augments and extra slots

- The current layout is **seven fixed slots**: Head, Torso, left/right Arm,
  left/right Leg, and Core.
- All seven fixed slots and **three extra slots** are available from the start.
  Events can expand the extra slots, and they can later be converted into
  additional limb slots.
- Extra slots can hold standard augments and grant:
  - The augment's Overdrive skill, when it has one and Overdrive is active.
  - Its passive **Extra Effect** while it is in an extra slot.
  - Not its regular active ability; regular actives require the augment to be in
    a normal body slot.
- Extra slots are therefore a way to gain additional Overdrives and passives,
  with increased HP-softcap instability as a tradeoff.
- Equipping is free. Removing/replacing an augment costs Nanites at vendors.
- Each augment can be tuned once to upgrade. Some augments may be found already
  upgraded.
- Stat bonuses, passives, and active abilities depend on slot type.
- Boss augments may be Divine when the loot roll allows.

### Augment rarities, builds, and synergy sets

- Core rarity direction: **Common → Uncommon → Rare**.
- A later expansion proposes **Divine** above Rare:
  - Common: basic effects, often single-use/setup tools.
  - Uncommon: combo logic or minor synergy.
  - Rare: signature mechanics, scaling, or reactive triggers.
  - Divine: powerful augment-enders; may introduce flags, unique mechanics, or
    deck/unlock triggers.
- Augments should have **1–2 active abilities**.
- Status effects are not gated; they are expressive build tools. Do not avoid
  strong status combinations merely to prevent power-gaming.
- Players should be able to create builds that feel “broken,” while diverse
  top-end paths remain comparably strong.
- Synergy augments work like sets and reward specific builds. They check
  conditions (such as owning three Void augments or applying four Bleeds in a
  turn), grant passive effects, and may transform related skills. They can
  integrate with the flag system.
- Example synergies:
  - **Eye of the Storm:** With three Lightning augments equipped, gain +1 Focus
    every two turns.
  - **Pillar of Decay:** If an enemy has 3+ damage-over-time effects, those
    effects deal +1 damage per turn.

### Status effects and combat vocabulary

- Existing status concepts: **Bleed, Burn, Stun, Virus**.
- **Glitch:** Chaotic random targeting; can hit anyone, including the user or
  allies.
- Additional proposed status/mechanics vocabulary includes damage reduction,
  blocking, absorb, mitigation, Disoriented, Shred, Bruise, Blind, Cripple,
  Rooted, and stability. Final definitions and stacking rules are not yet
  specified.
- Boss status resistances/immunities are reserved for high-level, thematic
  fights and should add tactical depth.
- Status conversion is a desired mechanic that expands combo and interaction
  possibilities.

### Enemies, turns, and initiative

- Enemies do not spend Focus.
- At the start of each cycle, enemies choose an action and a forecast type
  (attack, block, hack, etc.).
- After the player ends their turn, enemies execute in initiative order.
- The player usually acts first. Some enemies always surprise; others have a
  50/50 initiative chance.
- Non-boss enemies should avoid repeatedly using their strongest abilities:
  use internal cooldowns or behavior heuristics, use lower-tier skills more
  often, and respond to player state when appropriate.
- Bosses are exempt from the non-boss pacing safeguard and may use strong moves
  aggressively.
- Bosses have unique mechanics, phases, and enrage behavior; some have
  Overdrive-like abilities.
- Mini-bosses are build/loot checks with strong rewards.
- Hard mode adds more mini-boss nodes and a global percentage increase to enemy
  damage.

## 4. Equipment, consumables, and relics

### Non-augment equipment

- Persistent gear occupies non-augment slots or acts as passive side-grade
  gear. It does not interact with HP softcap mechanics.
- Supports “meat” builds and other alternatives to augment-focused play.
- Typically gives passive stats/keywords rather than direct active abilities;
  may have set bonuses or synergy traits.
- Example gear concepts:
  - **Baseball Bat:** +3 damage to unarmed melee; 15% chance to inflict Bruise.
  - **Tactical Vest:** −10% damage from physical hits.
  - **Reinforced Mask:** Immune to Blind; −10% chance to receive debuffs.
  - **Kinetic Gloves:** Attacks grant +1 block.
  - **Echo Rifle:** First attack each combat gains +50% damage.
  - **Graveplate:** Gain 5 HP on kill (maximum three times per turn).
  - **Hazard Boots:** Immune to Cripple and Rooted.
- Equipment sets may provide combined bonuses (example: an Armored Raider set
  grants HP, stagger resistance, and a crush effect on hit).
- Some gear may be unique drops from floors, Pantheon members, or elite nodes,
  and may visually reflect factions or lore.

### Consumables

- One-use inventory items, separate from augments and not counted against
  augment slots or softcap rules.
- Usable in combat or between rooms; limited quantities encourage planning.
- Can be found/replenished at rest nodes, shops, and random encounters.
- Intended to empower every build type, reward timing, enable emergency
  turnarounds/turn-skips, and add expression outside augments.
- Possible examples:
  - **Stimpack:** Restore 30 HP (one use).
  - **Focus Pill:** +2 Focus (one use).
  - **Disruption Mine:** Apply Disoriented and 2 Shred to all enemies.
  - **Null Gel:** Remove all negative status effects.
  - **Adrenal Burst:** +1 Focus and +25% damage next turn.
  - **Overdrive Core:** Set misfire chance to 0% for two turns.
  - **Soul Key:** Opens a hidden path on the current floor.
  - **Ration Pack:** Heal 15 HP, up to three uses per run.
- Consumables can have synergies with augments/equipment. Keywords such as
  **Bypass augment system** can prevent an item from contributing to softcap or
  augment-based status stacking.
- A small meatman-only item pool may appear when the player has zero augments;
  example **Raw Meat** gives +10 HP and +1 passive regeneration.

### Echoes / relics

- “Echoes” are described as relics in the style of *Slay the Spire*.
- They are an intended run/build layer, but their exact rules, acquisition,
  rarity, and interactions remain to be defined.

## 5. HP softcap, Overdrive, and boss access

- Player base HP: **100**.
- An equipped augment's softcap is the percentage of available Max HP it costs
  while equipped. Sum equipped softcap percentage points, subtract that share
  from the player's base Max HP plus positive augment Max HP bonuses, and
  recalculate when equipment changes. Unequipping or replacing an augment
  removes its softcap cost. Softcap therefore reduces the actual Max HP cap; it
  is not merely an unlock meter or a current-HP threshold.
- HP softcap is central to Overdrive unlock/scaling, risk/reward, and some
  cosmetic/meta bleed. Extra augment-slot use can increase softcap instability.
- Boss access can depend on run interactions/events, permanent unlocks earned
  from prior interactions, or lore progression; define the specific condition
  for each boss. During balance passes, temporarily limiting the available
  boss pool (even to one boss for repeated testing) is a developer test setup,
  not a player-facing progression gate.

### Current Overdrive rule

Overdrive unlocks when cumulative equipped augment/system softcap reaches
**60%**; this is not a current-HP threshold. Each full +3 percentage points of softcap adds
**+12% Overdrive damage** and **+7 percentage points of misfire chance**.
Scaling is linear and currently uncapped. Older ≤40% current-HP and 30–40%
unlock proposals are superseded.

## 6. Account progression, flags, and unlocks

### Metal Level

- **Metal Level = account level.**
- Runs convert end-of-run points into XP, which increases Metal Level.
- Metal Level unlocks tech, augments, enemies, and items for future runs.
- Achievements, special events, and first-time flags can also unlock content.
- There is no between-run currency; progression is account-based.
- Cosmetics and meta bleed are tied to HP-softcap mechanics.

### Flag system

- Flags are a procedural backbone: they can determine augment availability,
  enemy types, secrets, events, and other content.
- Specific item + action combinations can trigger hidden flags.
- Flags persist across runs, tied to the account/Metal Level.
- Flags can unlock bosses, events, endings, and secret content.
- Secret events/cutscenes can include betrayal/redemption (bosses switch sides
  or variants awaken), Pantheon returns (dead gods reappear in altered forms),
  and Cult Ascension (enough cult relic augments replace the final boss with a
  Chrome Demiurge).

**Example flag — “Cursed Mirror Broken”**

- Trigger: Finish **Mirror of the Lost** and select **Smash**.
- Immediate effect: Add **Fractured Phantom** mini-boss to the next node deck.
- Persistent effect: Add **Reflection Burn** to the augment drop pool.
- Forced flag: Guarantee **Fractured Phantom** next run, then convert it to a
  standard encounter flag.

## 7. World, factions, and lore

### The Tower of Vega

- Before the Collapse, the Tower was a luxury mega-structure built by Vega Corp
  and marketed as a paradise/ascension resort.
- After the Collapse, Kronos turned it into a death game broadcast.
- Each floor is a corrupted version of a former “wondrous experience.”

### Vega Corp

- Pre-Collapse: clean, polished corporate image.
- Secret purpose: harvest chrome-compatible humans and forge them into living
  weapons, the Pantheon.
- Lotteries targeted low-income guests under the cover of recruitment.
- Post-Collapse: a warlord/corporate hybrid that is openly sadistic.

### Pantheon and Titans

- The original Pantheon were heavily chromed enforcers named after mythic gods.
- Their memories were erased and they were used as weapons of war.
- Their recovery of memory and rebellion triggered the Collapse.
- Surviving original Titans: **Kronos** (Vega Corp ruler), **Gaia** (hidden),
  and **Uranus** (missing).
- A second Pantheon was created by Kronos to enforce post-Collapse order, with
  false family memories that cast Kronos as their father.
- **Jupiter/Zeus** led a rebellion to free the siblings; **Ares** betrayed him,
  leading to war.
- Kronos defeated the second Pantheon and “consumed” their augments into
  himself and his loyalists.

### Cultists

- Chrome-addled extremists worship Pantheon members as gods.
- They construct temples from rust, chrome, and neon and fight rival cult
  factions.
- Cultists call chromed individuals who ascend members of the Pantheon.

### Boss categories

- Titans (survivors of the original Pantheon)
- Gods (second-generation Pantheon, including surviving or consumed members)
- Cult Leaders (chrome zealots with mythic themes)
- Device Bosses: Concierge, Curator, Therapist, Hostess, Shepherd, Evaluator
- Monsters of Myth: mythological creatures reimagined as bio-chrome horrors

## 8. Lore collection and endings

### Lore books

- Plan for **10–14 books**, each about a world pillar (Vega Corp, Pantheon,
  Cults, Wastelands, Chrome Rot, Devices, etc.).
- Lore entries unlock by collecting items across runs. Some entries are
  verified facts (**True Lore**); most may be inaccurate because of narrator
  bias (**False Lore**).
- Completing sets of True Lore rewards the player with greater variation in
  the Tower. Whether the game explicitly labels False Lore to the player is
  undecided; do not reveal its status by default.
- The earlier three-perspective book structure is a proposal, not a confirmed
  requirement; reconcile it with the True/False Lore collection model before
  authoring the full codex.

### Book I: *The Chrome Pantheon: A History of Vega Corp and the Tower of Vega*

- Seven entries, each with three versions: **Corporate propaganda**, **Cult
  myth**, and **True record**.
- This is an early concept illustration, not a confirmed codex schema; the
  number and relationship of variants remain open under the True/False Lore
  model above.
- Example, Entry II — *The Ascension Project*:
  - Corporate: chrome uplifted heroes and saviors; no slavery or memory-wiping.
  - Cult: the Pantheon were born perfect, chrome was divine, and Vega was
    fate's chosen vessel.
  - True record: the Pantheon were stripped humans sold as products; their
    oppression was accidental rather than their original design.

### Endings / modes

- Standard ending
- True ending
- “Meat Lovers” ending for organic/meat-focused builds
- Endless mode
- Hidden special modes

## 9. Architecture and implementation context

The supplied folder-architecture proposal is an **Unreal Engine example**,
organized around C++ source, Blueprints, DataAssets, and per-floor content. The
current workspace is a **Godot 4.6 project**, so that example is a conceptual
separation-of-concerns reference, not a directory structure to copy literally.

### Unreal example captured from the proposal

```text
Source/
  Core/         GameInstance, GameMode, PlayerController, InventorySubsystem
  Combat/       CombatSubsystem (turn loop)
  Encounters/   EncounterSubsystem, BaseEncounterActor
  Components/   StatsComponent, StatusComponent, AbilitiesComponent
  Data/         PrimaryDataAsset classes, enums, structs
  Characters/   Exploration pawn, combat pawns
  UI/           Optional C++ base widgets

Content/
  Core/
    Augments/ Combat/ Echoes/ UI/ DataTables/ Player/ Utilities/
  Floors/
    Floor_01/
      Data/ Encounters/ Enemies/ Augments/ Echoes/
      Environment/ Misc/
  Vendors/ Consumables/ Audio/ VFX/ Misc/
```

For Godot implementation, preserve the **logical boundaries** (core/run state,
combat, encounters, reusable components, data definitions, characters, UI,
shared content, and floor-specific content) while using Godot-native scenes,
resources, scripts, and assets. Do not treat the Unreal class names or folder
names as established project code.

## 10. Open questions and conflicts to preserve

The project has accumulated several iterations of system notes. The more
recent, specific implementation and content conflicts are consolidated in
**§20, Design conflicts and decisions to revisit**; treat that section as the
authoritative open-question list. Older floor-scale, rarity, and augment-slot
proposals are retained in context but should not be combined with later
proposals unless explicitly resolved.

## 11. Workspace note

The workspace is a Godot 4.6 project with a playable Floor 1 vertical-slice
prototype; see §30. The prototype is test scaffolding, not production
implementation of the full systems or content catalog.

## 12. Combat screen and action baseline

### Combat UI sketch

The supplied rough combat-screen sketch establishes these elements:

- Player combatant on the left with name and HP.
- Enemy combatants across the upper battlefield; enemy name and HP/status area
  on the right. One enemy HP display may be hidden.
- Buff/debuff indicators near combatants.
- A player action menu near the bottom with **Fight**, **Item**,
  **Overdrive**, **Hack**, and **Block**.
- The sketch also includes a small Focus indicator; the value
  shown is 3.

This is a layout/concept reference, not a final UI specification.

### Move content target

- Target around **294 augments**.
- Aim for **2–3 regular moves per augment**, plus a separate Overdrive move
  per augment.
- Author's current estimate: roughly **600–700 attack/hack move slots** total
  and **500–600 distinct moves** after overlap, especially within
  Common–Rare ranges.
- Confirm whether the 2–3 moves per augment count includes or excludes that
  augment's Overdrive move before using these estimates for production planning.
- Content breadth should be varied, with a scope somewhat below *Slay the
  Spire* around its Mage expansion.

## 13. Status-effect catalog

The following is the supplied “OG 50 effects rebalanced” subset/catalog so far.
Durations, stack limits, and trigger wording below are retained as provided;
effects without a duration are event-triggered/reactive. Exact timing order
and stack interactions remain to be implemented.

### Control and disruption

- **Time Fracture:** Delay next action by 1 full turn. (1 turn)
- **Entangled:** 50% chance to lose current action. (2 turns)
- **Crystallized:** +15% damage taken; 33% chance to remain frozen when acting,
  losing the action on failure. (2 turns)
- **Echocapture:** Next skill (attack/tech/Overdrive) is selected randomly, with
  random targets. (1 turn)
- **Neuralock (Boss):** Lose 5 Focus at start of turn per stack. (3 turns,
  3 stacks)
- **Mindspike (Boss):** Lose 10 Focus for that turn per stack. (3 turns,
  3 stacks)

### Damage over time and status spread

- **Rustburn:** 4% max HP per turn; −15% healing per stack. Uncapped, scales
  after 10. (3 turns)
- **Fleshrot:** 3% current HP damage per stack at start of turn. (3 turns,
  5 stacks)
- **Scorched:** 5% HP per turn; on death explodes for 5% max HP to adjacent
  targets, with 50% spread chance. (3 turns, 5 stacks)
- **Viral Bloom:** 3% current HP per turn; 33% chance to spread one stack to
  each adjacent enemy at end of turn. Uncapped, soft cap after 6. (3 turns)
- **Shockrot:** 2% current HP per stack and damages adjacent targets for the
  same amount. (3 turns, 5 stacks)

### Marks and burst amplifiers

- **Echoed Trauma:** Next hit taken deals +30% damage. (Until triggered)
- **Chrono Wound:** After 2 turns, explodes for 6% max HP plus 50% damage taken
  while marked. (2 turns, independent stacks)
- **Time Burn:** Skip turn if a stack is active at start; lose 25% current HP.
  (2 turns)
- **Shellcracked:** +12% damage taken per stack. Uncapped, soft cap after 8.
  (2 turns)
- **Gospel Marked:** +25% damage dealt and +30% damage taken. (2 turns,
  5 stacks)
- **Shattermark:** When the mark expires, the next attack against the target
  deals +60% damage. (3 turns)

### Reactive and reflective

- **Backlash Mark:** Reflect 60% of damage taken back at the attacker.
  (3 turns)
- **Chainshock:** On hit, deal 15% damage to 1 adjacent target. (Reactive)
- **Echoed Pain:** Copy the last instance of damage taken at the end of each
  turn, excluding DoT. (3 turns)
- **Retaliate:** First time hit each turn, reflect 15% damage to all enemies.
  (3 turns)

### Buffs, shields, and regeneration

- **Clarity:** If no damage was taken since last turn, gain 1 Focus. (2 turns)
- **Waking Dream:** On Focus gain, +10% critical chance. (2 turns)
- **Cerebral Lash:** When 2 Focus is spent, next skill gets +15% damage.
  (2 turns)
- **Slow Mend:** Heal 4 HP per turn. (3 turns)
- **Rapid Mend:** Heal 8 instantly, then 2 per turn. (3 turns)
- **Lattice Shell:** −25% AoE/status damage taken; weak to Fire. (3 turns)
- **Iron Ward:** −25% physical damage taken. (2 turns)
- **Divine Ward:** −15% all damage. (3 turns)
- **Solar Veil:** Nullify the first damage instance each turn. (3 turns)
- **Aegis Mark:** First hit each turn reduced by 50%. Uncapped stacks. (3 turns)
- **Stasis Matrix:** Absorb damage equal to stacks. Uncapped. (3 turns)
- **Phase Shift:** Negate next damage instance; consume 1 stack. (3 turns)
- **Resist Barrier:** −20% status-effect application chance. (3 turns)
- **Absorption Field:** Converts 5% incoming damage into healing. (3 turns)

### Curses and miscellaneous

- **Soul Link:** Link 2 targets; share 50% damage. (3 turns)
- **Wound Leech:** Heal 1 HP each time you deal damage equal to 5% of the
  target's max HP. (2 turns)
- **Null Pulse:** Target suffers 100% healing and armor reduction. (1 turn)
- **Fractured:** −5% damage dealt per stack. Uncapped, soft cap after 10.
  (3 turns)

## 14. Tower floor catalog and run map

### Main floors

The Tower has **15 main floors**. A standard run always starts at Floor 1 and
ends at Floor 15, with three selected floors in between. Full Climb traverses
all 15 sequentially.

| Floor | Name | Former attraction | Post-Collapse identity |
|---|---|---|---|
| 1 | Rotting Resort | Elite wellness retreat, spas, infinity pools, holo-paradise | Collapsed decadence; chrome cultists; comfort turns to unease |
| 2 | Jurassic Spa | Prehistoric luxury playground and chrome hot springs | Primal fear and fight-or-flight stress test |
| 3 | Submerged Coral Pavilion | Luxury aquarium with glowing engineered reefs and manta rays | Whispering, subconscious manipulation, drowning isolation |
| 4 | Bioluminescent Abyss | Safe-pod deep trench tour among engineered glowing creatures | Dominance tested under fear and pressure |
| 5 | Crystal Menagerie / The Glass Zoo | Living crystal beasts that sing in the light; dining among them | Beasts shriek and fracture; awe weaponized into terror |
| 6 | Aurora Dome / Cathedral of Light | Mood-responsive auroras, gravity-warped cavern, weddings and coronations | Hallucinations and instability; hesitation is dangerous |
| 7 | Apex Hunt / Predator Cathedral | Elite safari hunting chrome chimeras | The player becomes prey in an adaptation gauntlet |
| 8 | Neon Carnival / Amusement Eternal | Endless neon rides, chrome clowns, floating casinos | Violent rides, retina-burning lights, murderous entertainment AI |
| 9 | Gravity Gardens / Vertical Eden | Inverted gardens, rotating platforms, memory-flavored fruit | Unstable gravity, strangling chrome roots, madness-inducing fruit |
| 10 | Starlight Observatory / Luxury Among the Stars | Projected alien skies and personalized constellations | Whispering impossible stars, bent gravity, fractured time perception |
| 11 | Memory Theatre / Hall of Personal Dreams | Immersive recreation of guests' perfect memories | Nightmarish trauma loops; AI harvests emotional responses; screens may show prior deaths as background imagery |
| 12 | Chrome Bazaar / Market of All Worlds | Simulated city offering every imaginable good | Impossible wares demand a piece of the buyer |
| 13 | Leviathan Spa / Ocean in the Sky | Floating ocean and chrome leviathan-towed spas above the clouds | Capsized spas, hunting leviathans, drowning storms |
| 14 | Infernal Opera / Stage of Immortality | Gods perform in an opera house where sound reshapes architecture | Voices induce madness; the floor reshapes to broken songs |
| 15 | Skybridge Olympus / Pantheon's Summit | Chrome-marble Olympus above the clouds, thrones and winged beasts | Final test of will, grace, and fear |

Floor names and sequence above follow the latest main-floor list. Earlier notes
gave different floor assignments for some influences (for example Apex Hunt
and the Aurora Dome); preserve those as legacy concepts until the encounter
roster is reconciled.

### Secret floors

- **Tethys' Secret Floor — The Life-Forge Vault (Sub-Level):** Hidden living
  machinery, biochrome wombs, pulsing roots, and flesh/nanite incubators.
  Tethys built it in a desperate attempt to save her dying child. Lullabies and
  maternal instructions remain in its walls. Paranormals originated here as
  grief-born accidents and half-miracles. The elite once called rebirth in the
  Forge a great honor, though none returned unchanged. Tethys can spawn
  Paranormals endlessly.
- **Moon Floor (Floor 16 — Off the Map):** Decayed simulated lunar landscape
  with a false Earth, once a luxury “walk on the moon” attraction; now a
  sterile graveyard haunted by chrome-suited astronauts and collapsed gravity
  wells. Uranus' unreachable body is associated with this floor, half illusion
  and half truth.
- **Tartarus — Gaia's Prison Floor (buried below all):** Vast sealed biome where
  Gaia is imprisoned, with molten chrome chains rooted into her body and
  violent gravity/time/mass distortions. Rumored to require breaking the
  Tower's heartline at three points to access. Pluto guards/jails Gaia; Pluto
  can be fought before entering her cage, and returning after freeing Gaia
  should encounter a stronger, enraged Pluto.
- **Vulcan's Ironworks Prison:** Secret floor where Vulcan is a shackled smith
  laboring in a forge that is also his prison. Every five turns, his
  **Overheat Cycle** unleashes a forge blast; slag cards can become usable
  molten weapons for one turn if timed correctly. After Vulcan is defeated and
  freed, he can appear in future runs as a rare vendor offering exclusive
  Divine augments.

### Per-floor encounter content targets

These are content-production goals, not a guarantee that every template
appears in one run:

- 8–10 standard combat encounter templates.
- 3–4 elite/mini-boss encounters, including up to one flagged elite.
- 3 boss options: one Pantheon boss and two non-Pantheon bosses tied to floor
  theme/lore/influence.
- 2–3 special/gimmick/environmental fights.
- 4 random combat variants (for example low gravity, status auras, weather, or
  corrupted terrain).
- 2 event/lore combat encounters.
- Approximately **22–24 encounter templates per floor** overall.
- Hidden interactions per floor may increase from 2 to **2–5**.

Modular encounter variants and modifiers should create replay variety without
requiring every combination to be a bespoke encounter.

### Node composition and rewards

- **Elite nodes** act as mini-bosses, grant higher Nanite rewards, and increase
  chances for Echoes and Rare augments.
- **Random Event nodes** can resolve into rests, vendors, elites, lore, boons,
  traps, or branching decisions; they are the map's wildcard node.
- **Vendor nodes** use the Nanite economy and can sell augments, Echoes of
  Elysium, healing, and tuning. Vulcan and special vendors can also appear in
  random events.
- **Rest nodes** provide HP recovery (clamped to current max HP), augment
  tuning, and pre-boss preparation.
- **Boss node** is always at each floor's end and selects from that floor's
  boss pool (Pantheon or non-Pantheon depending on RNG and run state).
- Bosses may require a run-specific interaction/event, a permanent unlock
  earned by triggering an interaction in a prior run, or lore progression;
  document the access condition for each boss.
- Boss selection is made during floor generation and shown on the map. Define
  how the boss pool/map preview is updated when a qualifying interaction
  happens after that selection.
- Standard nodes include combat, elite, random event, vendor, rest, and boss.
  Removal shops are an additional possible node type from earlier notes.
- Nanites/Nanite rewards are the run's vendor economy; this coexists with the
  no-between-run-currency rule.

### Boss timing event: Hera — The Crown

- Hera's cult remnants persist in the Rotting Resort, but her power is
  authority/ritual rather than a fixed floor.
- The proposed event has a **20–30%** chance after the penultimate boss of the
  fourth selected floor; exact trigger timing remains provisional.
- When triggered, Hera replaces that floor's selected boss. Show Hera in the
  floor's boss slot on the map; this is not an additional double-boss fight.
- Hera demands the player prove their worth. Reconcile the provisional trigger
  timing with the standard rule that the selected floor boss is visible when
  the map is generated.

## 15. Floor selection and difficulty scaling

### Standard five-floor path

- Slot 1 is always **Floor 1 — Rotting Resort**.
- Slots 2–4 choose from weighted pools, with per-slot maximums of Floors 12,
  13, and 14 respectively.
- Slot 5 is always **Floor 15 — Skybridge Olympus**.
- Once a floor is selected, all lower-numbered floors are pruned from future
  selection, so the path only ascends.
- If an RNG result exceeds the slot cap, reroll or clamp it.
- The sample path `1 → 9 → 12 → 14 → 15` demonstrates an escalating run.
- Full Climb is `[1, 2, 3, ..., 15]`; it bypasses random selection, elevator
  caps, and pruning.

### Weighted floor selection (latest supplied pseudocode)

For each random slot, filter the available floor pool by the slot's maximum and
weight each eligible floor by its tier:

| Slot | Max floor | High weight (6 entries) | Medium weight (3 entries) | Low weight (1 entry) |
|---|---:|---|---|---|
| 2 | 12 | 2–5 | 6–10 | 11–12 |
| 3 | 13 | 6–10 | 11–12 | 13 |
| 4 | 14 | 11–13 | 6–10 (if unused) | 14 |

```text
generateRunPath():
    path = [1]
    available = [2, 3, ..., 14]
    for slot in [2, 3, 4]:
        floor = selectFloor(slot, available)
        path.append(floor)
        available = [f for f in available if f > floor]
    path.append(15)
    return path

selectFloor(slot, available):
    config = slotConfig(slot)
    valid = [f for f in available if f <= config.maxFloor]
    weightedPool = []
    for floor in valid:
        repeat floor 6 times if floor in config.high
        repeat floor 3 times if floor in config.medium
        repeat floor 1 time if floor in config.low
    return randomChoice(weightedPool)
```

In the original pruning pseudocode, pruning assigns a filtered list back to
`availableFloors`; implementations must return or mutate that list so the
pruning actually persists. A selection slot with no valid floors needs an
explicit fallback/retry rule.

### Hybrid difficulty scale

Design principle: difficulty considers both a floor's absolute number and the
slot position at which it appears. Full Climb uses the natural floor-number
curve without slot scaling.

```text
calculateFloorDifficulty(floorNumber, slotPosition, isFullClimb):
    baseScale = 1.00 + (floorNumber - 1) * 0.05

    if isFullClimb:
        positionScale = 1.0
    else:
        positionScale = {
            2: 1.0,
            3: 1.2,
            4: 1.4
        }.get(slotPosition, 1.0)

    return (baseScale * 0.7) + (positionScale * 0.3)
```

Base floor examples: Floor 1 = **1.00×**, Floor 8 = **1.35×**, Floor 15 =
**1.70×**. In Standard mode, slot position gives late-run challenge even when
a lower-numbered floor is selected late; a high-numbered floor appearing early
still gets meaningful base scaling without overwhelming the run. In Full
Climb, `effectiveScale = baseScale`.

**Example:** Floor 7 in Slot 4:

- `baseScale = 1 + (7 - 1) * 0.05 = 1.30`
- `positionScale = 1.40`
- `effectiveScale = (1.30 * 0.7) + (1.40 * 0.3) = 1.33`

### Applying difficulty to floor data

After floor and slot selection, calculate and store `effectiveScale` in the
generated floor data so combat AI, rewards, and UI previews can all use the
same value. Bake scaled values into that floor's encounters before play:

```text
applyDifficultyScalingToFloor(floorData, floorNumber, slotPosition, isFullClimb):
    scale = calculateFloorDifficulty(floorNumber, slotPosition, isFullClimb)

    for enemy in floorData.enemies:
        enemy.hp *= scale
        enemy.damage *= scale
        enemy.statusPotency *= scale

    for boss in floorData.bosses:
        boss.hp *= scale
        boss.damage *= scale
        boss.statusPotency *= scale
        boss.phaseThresholds = boss.phaseThresholds.map(x => x * scale)

    floorData.naniteReward *= 0.9 + scale * 0.1
    floorData.dropRarityWeight += (scale - 1.0) * 0.5
    floorData.effectiveScale = scale
    return floorData
```

The broader scaling notes also propose scaling enemy/boss HP, damage, status
durations/intensities, Nanite rewards, rarity weights, boss phase
thresholds and scripted mechanics. Encounter tags can add a multiplier on top
(example Elite tag = 1.2× effectiveScale); per-floor modifiers and hard-mode
mutators can also adjust the result.

Optional higher-tier behavior scaling may activate at combined scale
thresholds (example `scale > 2.5`): more status application, more reactive AI
and trap setup, and Overdrive-like abilities for elites/mini-bosses. Optional
status tuning can apply different floor-based multipliers to specific status
types instead of scaling all status potency uniformly.

### Floor generation sequence

1. Select the floor for the run slot using the weighted pool, cap, and pruning.
2. Calculate `effectiveScale` from floor number and run slot (or base scale in
   Full Climb).
3. Pull the floor template and apply scale to enemies, bosses, status values,
   phase thresholds, rewards, and drop weighting.
4. Generate the node graph and assign scaled encounter templates.
5. Select the boss from the floor's boss pool and show it on the map.
6. Play through encounters using the generated/baked values; secret floors may
   branch downward.
7. Mark the floor complete and repeat until Floor 15 is reached.

### Older difficulty curves retained as alternate tuning proposals

Earlier notes supplied hand-tuned multiplier bands (Full Climb: Floor 1–3 HP
1.00–1.25×, rising to Floor 15 HP 2.50×/damage 2.00×; Standard: Slot 1 1.00×,
Slot 2 HP 1.10–1.35×, Slot 3 HP 1.35–1.75×, Slot 4 HP 1.75–2.25×, final floor
2.50×). These conflict numerically with the later compact hybrid formula, whose
Floor 15 base scale is 1.70×. Treat the banded curves as earlier balance
proposals, not as additional multipliers to stack on top of the hybrid formula.

Likewise, an alternate enemy formula was proposed:
`Scale = (1 + (F * alpha)) * (1 + (S * beta))`, where `F` is floor number,
`S` is slot order, and alpha/beta were suggested around 0.04–0.06 and
0.10–0.12. This is a separate alternative to the blended 70/30 model, not an
approved extra layer.

### Loot rarity curves

Rarity tiers: Common, Uncommon, Rare, Divine. Values are percentages in the
loot/vendor/chest tables.

**Take the Stairs / full 15-floor climb baseline:**

| Floor | Common | Uncommon | Rare | Divine |
|---:|---:|---:|---:|---:|
| 1 | 70% | 25% | 5% | 0% |
| 2 | 65% | 25% | 8% | 2% |
| 3 | 60% | 27% | 10% | 3% |
| 4 | 55% | 28% | 13% | 4% |
| 5 | 50% | 30% | 15% | 5% |
| 6 | 45% | 30% | 18% | 7% |
| 7 | 40% | 30% | 20% | 10% |
| 8 | 35% | 30% | 22% | 13% |
| 9 | 30% | 30% | 25% | 15% |
| 10 | 25% | 30% | 27% | 18% |
| 11 | 20% | 25% | 30% | 25% |
| 12 | 15% | 25% | 30% | 30% |
| 13 | 10% | 20% | 35% | 35% |
| 14 | 5% | 15% | 35% | 45% |
| 15 | 0% | 10% | 30% | 60% |

**Standard five-floor run, by run slot:**

| Slot | Floor selection | Common | Uncommon | Rare | Divine |
|---:|---|---:|---:|---:|---:|
| 1 | Floor 1, fixed | 70% | 25% | 5% | 0% |
| 2 | Weighted Floors 2–12 | 55% | 30% | 12% | 3% |
| 3 | Weighted Floors 6–13 | 35% | 30% | 25% | 10% |
| 4 | Weighted Floors 11–14 | 15% | 25% | 30% | 30% |
| 5 | Floor 15, fixed | 0% | 10% | 30% | 60% |

Special loot rules proposed:

- Secret vendors ignore floor weights and skew Rare/Divine.
- Boss rewards receive +15% Divine weighting over floor baseline.
- Elites/mini-bosses receive +10% Rare weighting over baseline.
- Chests follow floor weights with +5% Rare and +5% Divine in Standard mode.
- Higher Standard slots (3–5) have more Divine vendor stock.
- Secret floors retain full-run rarity values regardless of when accessed.

These are weighting adjustments; define normalization and whether bonuses are
percentage-point additions or relative multipliers when implementing.

## 16. Floor themes, Pantheon influence, and encounter primers

Older encounter primers and floor influence notes are preserved here because
several of their floor numbers differ from the latest main-floor catalog.
Resolve the mapping before treating these as final assignments.

### Previously proposed floor encounter primers

- **Rotting Resort:** Hera cult remnants. Chrome Attendants heal/buff;
  Obedience Wretches stack debuffs; Bellhops are slow bruisers. Minibosses:
  Herald of the Crown and Rust Concierge. Eerie hospitality; teaches
  buff/debuff layering.
- **Jurassic Spa:** Mars' genetic war-code. Spa Raptors inflict fast Bleed;
  Thermal Behemoths use AoE breath; Chrome Attendants recur. Miniboss:
  War-Engineered Apex. High tempo and prioritization.
- **Submerged Coral Pavilion:** Neptune. Abyssal Divers stack DoTs; Leviathan
  Drones tank/shield; Aquatic Surgeons debuff/heal. Miniboss: Chrome Leviathan
  Fragment with rotating shields. Slow suffocation; control and sustain.
- **Bioluminescent Abyss:** Phantom of Uranus. Sky-Light Projections use
  temporal effects; Aurora Wisps evade and apply Echoed Trauma; Hollow Divers
  warp turn order. Miniboss: Broken Sky Echo with Time Burn/turn warp.
- **Crystal Menagerie:** Venus' Shattered Bloom Echo. Chrome-Petal Beasts are
  glass cannons; Shimmer Golems protect; Venus Mimics are traps. Miniboss:
  Shattered Bloom with hallucination/burst.
- **Aurora Dome:** Gaia's whispers. Aurora Lurkers ambush; Lightbound Statues
  buff if ignored; Whispered Choirs heal/confuse. Miniboss: Yggdrasil Core,
  root-control fight. Punishes stalling.
- **Chrome Bazaar:** Mixed/Vega residue. Chrome Traders are unpredictable;
  Organ Vendors debuff; Augment Hounds leap at Focus. Miniboss: The Broker,
  who steals actions/Focus/augments. Economic combat.
- **Neon Carnival:** Vega AI corruption. Chrome Clowns burst/apply random
  debuffs; Ride Golems use AoE on death; Light Eaters drain Focus. Miniboss:
  Ringmaster Construct with cyclical “acts.”
- **Gravity Gardens:** Altus, Thousand-Handed Atlas hybrid. Gravity Sprites
  manipulate turn order; Rootbound Sentinels tank; Chrome Fruitbearers
  buff/heal. Miniboss: Altus' Fragment with appendage phases.
- **Starlight Observatory / Upper Cathedral:** Gaia's Tartarus roots.
  Chrome Pilgrims are buff/debuff hybrids; Rooted Guardians scale over time;
  Whispered Statues apply psychic DoTs. Miniboss: Yggdrasil Echo. Attrition
  and escalating pressure.
- **Memory Theater:** Pluto's debts. Debt Wraiths reduce healing/tax HP;
  Chrome Debtors buff on resource use; Bureaucrats steal Focus. Miniboss:
  Pluto Echo with resource taxes.
- **Apex Hunt:** Mars and Diana. Engineered Predators swarm/crit; Chrome Apex
  Beasts are elite/phase enemies; Trap Weavers create hazards. Minibosses:
  Mars Echo and Diana.
- **Chrome Foundry:** Vulcan. Molten Drones AoE on death; Forgemasters buff
  armor; Heat Vents act as hazards/enemies. Miniboss: Vulcan Fragment forges
  augments mid-fight.
- **Infernal Opera:** Apollo. Choir Constructs rotate buffs/debuffs; Stage
  Hands manipulate the field; Spectral Audience create hazards. Miniboss:
  Apollo with Crescendo/rhythm phases.
- **Skybridge Olympus:** Kronos and Jupiter finale; no regular enemies, though
  optional herald encounters may appear.

### Pantheon influence and boss mechanic concepts

- **Pluto — The Broken Oath:** Wanders Tartarus to jail Gaia; fought before her
  cage. Returning after Gaia is freed should find Pluto enraged and stronger.
  Appearance: armor and bone shards bound with black chrome sinew.
- **Hera — The Crown:** Can replace a selected floor boss through the
  event described above; her cult remnants haunt the Rotting Resort.
- **Neptune:** A silent, chrome-drowned first-generation Titan may appear in or
  influence the Submerged Coral Pavilion.
- **Phantom of Uranus:** First-generation apparition associated with the
  Bioluminescent Abyss; more silhouette than physical being.
- **Venus — Echo of the Shattered Bloom:** Associated with Floor 5 in an older
  assignment; withered chrome/petal construct, broken seductive voice,
  hallucinations of beauty concealing rot.
- **Hyperion — Echo of the Dying Sun:** Older notes associate him with the
  Aurora Dome / Floor 6. Every three turns, **Solar Flare** deals unavoidable
  AoE damage that scales if the player spent too much Focus that round. At
  50% HP, **Burnout** sacrifices his own health to increase damage.
- **Mercury — The Dealer:** Older notes associate him with Chrome Bazaar /
  Floor 7. Every four turns, **Contract of Exchange** offers a sacrifice (HP,
  discard cards, or destroy a relic) for temporary buffs; refusal enrages him.
  At low HP, **Market Crash** randomizes ability costs/effects for two turns.
- **Bacchus — The Revel:** Older notes associate him with Neon Carnival / Floor
  8. **Drunken Momentum** swings attack/defense each round; **Mad Revelry**
  summons partygoers that buff him if ignored or explode if killed; after six
  turns he enters a one-turn vulnerable **Hangover**.
- **Altus-Hekaton — The Bearing of Hands:** Titan fractured into many chrome
  arms, holding up the Tower. Gravity Gardens concept: grabs/binds/flings
  challengers as debris.
- **Mars — The Fang:** Apex Hunt arena; fauna carry his warfire, culminating in
  a chrome-organic apex monstrosity.
- **Diana — The Pale Huntress:** **Ambush** every four turns: vanish, spawn
  traps, then return with a guaranteed critical strike. **Hunter's Mark**
  focuses bonus attacks on a marked target until broken by a defensive action
  or surviving a defined number of turns.
- **Apollo — The Radiant Liar:** Older notes associate him with Infernal Opera
  / Floor 14. Every three turns, **Crescendo Cycle** escalates to a scripted
  finisher. **Light & Sound Illusions** alter actions/cards, mixing false notes
  that punish with hidden buffs. **Spotlight Hexes** amplify damage against
  one marked target.
- **Kronos and Jupiter:** True presences confront the player on Floor 15;
  final boss options/sequence depend on run state.

## 17. World history: Vega, Chrome Rot, and Paranormals

### Pre-Collapse society and Vega Corp

- The setting begins as a corporate-ruled cyberpunk society where wealth
  concentrates and the poor are ground down.
- Vega Corp was one of the Big Five megacorporations, rivaling the most
  powerful corps in polish and reach.
- Vega specialized in luxury augmentation: cosmetic, performance, and lifestyle
  modifications marketed to make the wealthy chrome demigods.
- Public identity: **The Heavenly Corporation**, promising paradise and human
  perfection through augmentation and immersive technology.
- The Tower of Vega was a 15-floor vacation destination/showroom, with each
  floor a self-sustaining themed biome and wonder for investors, heads of
  state, celebrities, and elite guests.

### Ascension Project and the Tower's secret purpose

- Behind the luxury surface, Vega's **Chrome Compatibility Program / Ascension
  Project** used Tower experiences as stress tests for augmentation load.
- The real goal was to identify rare humans who could tolerate near-total
  cybernetic replacement without rejection or madness, then create living war
  gods.
- Successful subjects could be inducted into Vega's enforcers or auctioned to
  governments, corporations, and warlords.
- Spas tested stress resistance/biological rejection; VR dreamscapes tested
  psychological load/sanity; combat attractions tested field performance.
- “Guests” were test subjects. Wealthy visitors thought they were pampered;
  poor guests and staff were disposable baselines.
- **Dream Lotteries** offered low-income families a week in paradise as a
  poverty escape, but recruited them for augmentation stress tests. Winners
  rarely returned; those who did were changed.

### The Collapse and post-Collapse Vega

- A global catastrophe combining economic implosion, technological failure,
  and war shattered grids, networks, and supply chains.
- Corporate militaries went rogue; AI blackouts, augmentation malfunctions,
  and resource scarcity turned cities into battlefields.
- Vega's resort became a fortress. Leaders became warlord dynasts, and control
  shifted from contracts/marketing to blood, loyalty, and cults.
- Vega now broadcasts a death game from the Tower, drawing contestants from
  the ruins. The audience is fractured nations, warlords, and cultists.
- Escaping the Tower is called **ascension**; most contestants feed the system.
- Vega sells technology to cultists and broadcasts them as propaganda while
  playing factions against one another.

### Chrome Rot

- Chrome is living biotech built on colonies of programmable nanites that join
  flesh and machine; Vega's “safe and standardized” claim concealed a parasitic
  system.
- Chrome requires continual calibration. Without Vega's proprietary protocols,
  nanites destabilize; higher chrome load increases strain on the nervous
  system.
- Past a threshold, nanites rewrite the nervous system toward chrome, flood the
  brain with machine logic/pain feedback, and erode identity into a glitching
  husk.
- Symptoms progress from tremors, static hallucinations/voices, and phantom
  limbs; to violence, machine-corrupted speech, and reduced empathy; to
  personality collapse and daemon-like behavior.
- Most heavily affected people die or become Chrome Rot husks/cultists.
- A rare few adapt and synchronize with the swarm, becoming stable, more
  machine-than-human **Pantheon**. Vega saw a successful product; cults saw
  gods.
- In short: chrome is a parasitic techno-virus tolerated in small doses; most
  people cannot survive full saturation.

### Paranormals and Tethys

- During the Ascension Project, Vega ran genetic-splice experiments in parallel
  with chrome saturation. Tethys was the public-facing lead/product face.
- These experiments combined DNA and chrome nanites rather than using purely
  mechanical augmentation. Most subjects did not stabilize as Pantheon and
  became unpredictably mutated humans: extra limbs, electrical discharges,
  and warped physiology.
- They were cheaper than Pantheon but too unstable for release. Many escaped
  after the Collapse; generations later they became a quasi-species called
  **Paranormals**, often distrusted, enslaved, or worshipped.
- Some cults call them Tethys' children. Paranormal biotech augments are a
  possible gameplay category.
- Tethys cherished them despite Vega calling them failures. They followed her
  into the Tower and mutated further without calibration; some worship and
  defend her.
- Common Paranormals are weak alone but strong in packs. Unstable ones explode
  in chrome feedback on death and leave DoT hazards. Elder Paranormals are
  failed mini-Pantheon/elite experiments.
- Proposed Tethys boss room: her “children” respawn endlessly unless handled
  strategically; Tethys heals, buffs, and clones enemies. The fight is meant
  to evoke guilt; she begs the player to spare them.

## 18. Pantheon rosters

### First Pantheon (original Titans)

- **Kronos — The Reaper King:** Devourer of gods; absorbed his kin's chrome and
  now rules Vega from the Tower.
- **Gaia — The Mother of Rust:** Captive; her chrome bonded with ecosystems and
  birthed rust-choked techno-cults.
- **Uranus — The Sky Tyrant:** Lost in storms and orbital wreckage; worshipped
  in lightning and feared as a ghost in static.
- **Tethys — The Lifeforge:** Created chrome-organic abominations (Paranormals);
  her children still infest the Tower.
- **Iapetus — The Warborn:** Living war engine with modular weaponry; every
  motion a killing stroke.
- **Hyperion — The Burning Core:** Reactor-god with a fusion furnace capable
  of leveling cities and leaving glassed ruins.
- **Clymene — The Whispering Veil:** Illusion/perception-hack specialist able
  to project false realities into victims' minds.
- **Eurybia — The Iron Queen:** Magnetics and steel; bends weapons and peels
  armor from wearers.
- **Atlas — The Worldbreaker:** Colossal Atlas Frame built to carry city-scale
  chrome infrastructure during sieges; said to be the strongest Titan
  physically.

### Second Pantheon (Kronos' created family)

- **Jupiter — The Prodigal Son:** Doomed heir who believed love could free his
  family; betrayed and drowned in blood. Zeus/liberator myth inverted; death
  disputed, storms whisper his name. Both arms are chrome capacitor conduits
  that hurl plasma at the cost of his life force. Tone: hope turned ash.
- **Juno — The Blood-Drunk:** Betrayer, meant to be queen but devoted to her
  father; loyalty became slaughter. Hera's jealousy becomes fanatic devotion.
  Survived as Kronos' shadow. Spinal crown of neural blades rewrites others'
  loyalty through command codes; her voice is her weapon. Tone: love curdled
  to fanaticism.
- **Neptune — The Leviathan:** Abyss made flesh; drowned mortals and kin.
  Poseidon myth becomes suffocation. Locked in a flooded chamber, singing to
  drowned siblings. Gilled lungs and hydraulic exoskeleton create tidal
  implosions. Tone: hunger without end.
- **Pluto — The Hollow King:** Mourner surrounded by corpses who remembers
  every one. Hades myth as feared and unloved; walks ossuaries naming the dead.
  Necro-harmonic rib core animates chrome husks. Tone: loneliness incarnate.
- **Minerva — The War-Scribe:** Cassandra figure who foresaw doom; warnings
  ignored. Athena's wisdom bound to futility. Her scripts burned and chrome
  dismantled; fragments haunt the Tower. Predictive ocular implants projected
  battle-script futures. Tone: truth unheeded.
- **Mars — The Red Hound:** Loyal son who loved Kronos as a father, not merely
  from fear. Filial devotion made him blind to cruelty and eager to spill
  blood for Kronos. Ares myth recast as a soldier bound by filial love. Tone:
  love made into war.
- **Venus — The Skinwalker:** Beautiful but hollow, seeking affection and
  receiving commands. Aphrodite myth as weaponized beauty. Dissolved into
  mutable nanite flesh. Tone: yearning with no self.
- **Mercury — The Trickster Current:** Messenger of lies, fast but unable to
  escape bindings. Hermes myth as mocked freedom. Became a signal/ghost in
  circuits; kinetic legs create electric arcs and leave static messages.
- **Diana — The Pale Huntress:** Predator who longed for wilderness but was
  made only to kill. Artemis myth as corrupted purity. Stalks the wastes.
  Lunar-silver optics track heat/breath; retractable talons make her a
  relentless hunter.
- **Apollo — The Radiant Liar:** Tragic virtuoso whose genius, beauty, and
  strategy became deceit and isolation. His transmissions could save and ruin
  lives. Apollo's light/music/prophecy myth inverted: oracle as weapon, sun as
  knife.
- **Vulcan — The Forge-Born:** Slave-smith who forged wonders and chains; still
  shackled in the Tower's underworks. Hephaestus as creator enslaved. Furnace
  arms vent slag/sparks and shape chrome mid-battle; forge is also his prison.
  Tone: creation without joy.

## 19. Augment brand visual identities

These are art-direction families for augment design.

### Vega Corp — flagship luxury elegance

- Reference direction: polished cyberpunk luxury fused with Grecian idealism.
- Smooth ceramic-white, pearl, and obsidian; gold filigree follows muscle
  lines; Greek-key joint patterns; soft ivory/cyan/warm-gold glow.
- Philosophy: “You are not replacing yourself — you are perfecting the form.”
- **Aurelian Interface Arm:** Nearly human at rest, subdermal light tracing
  ideal musculature; energy blade unfolds like a marble statue awakening,
  without visible barrels or brutal seams.

### Cultist / black-market brewed

- Reference direction: unstable prototype/body-horror misuse of corporate tech.
- Asymmetrical flesh-metal hybrids with veins, sinew, living textures, and an
  unfinished, changing appearance.
- Philosophy: “The body knows what it wants — let it decide.”
- **Apostate Limb:** Looks human until stressed; bone and muscle rearrange in
  combat; blades, tendrils, or cannons grow through it.

### Corporate Competitor A — Shogun × Grecian

- Discipline, honor, and mythic authority.
- Layered lamellar-like plating, bronze/lacquered black/crimson, Greek crests
  joined with samurai geometry, intentional ritualized exposed joints.
- Philosophy: “Power must be seen to be controlled.”
- **Hoplo-Katana Arm:** Human-like articulated armored arm; forearm blade
  slides along the ulna; deployment clicks, locks, and posture matter.

### Corporate Competitor B — heavy metal / industrial

- Brutalist excess; aggression as fashion.
- Raw alloys, spikes, vents, exposed glow, neon reds/acid greens/inferno orange.
- Philosophy: “If they're staring, you're winning.”
- **Riot Hammer Arm:** Dense overbuilt forearm with violent deployment;
  rotating shotgun barrels and sonic/kinetic shock emitters; always barely
  contained.

### Vulcan-forged

- Godsmith/mythic craft: dark forged metal, molten amber/lava-gold veins,
  hammered imperfect surfaces that feel ancient and eternal.
- Philosophy: “It was made, not grown — and it will outlast you.”
- **Anvil Arm:** Massive but balanced; internal heat vents and impact
  amplification, with no flourish or elegance.

### Tethys augments

- Eldritch/organic-metal body horror; glossy surfaces, bone-white, oil-black,
  sickly silver, heart-like pulsing nodes.
- Philosophy: “Why should the body stop evolving?”
- **Abyssal Limb:** Symbiotic arm that reshapes tissue into blades, cannons, or
  tendrils; may move before the player does.

### Human-compatible technology — EA-Class

- External augmentation uses nanites while keeping them outside the user's
  body. Intended for survivors, dissenters, laborers, and anyone seeking
  benefits without surrendering bodily autonomy.
- EA-Class tech and augments both use nanites; the defining difference is the
  boundary: EA nanites are encapsulated, contained, purpose-locked, and
  replaceable. They live in weapon housings, armor, smart fabric, power cells,
  and tool cartridges, never the bloodstream. If they fail, the item fails,
  not the user.
- These are equipment-slot upgrades, not bodily replacements, but may occupy
  an augment slot for balance/parity.
- **Gravlock Shotgun:** Industrial firearm with contained nanite colonies that
  reconfigure the choke, adjust recoil damping, and heal barrel microfractures.

## 20. Design conflicts and decisions to revisit

This list captures source conflicts. Player resolutions and the current
working decisions are recorded in §31; those decisions supersede the
corresponding unresolved wording below.

1. **Overdrive unlock math:** Resolved in §31: unlock at 60% cumulative
   augment/system softcap, not at a current-HP threshold. Every full +3
   percentage points adds +12% Overdrive damage and +7 percentage points of
   misfire, linearly and currently uncapped.
2. **Augment slots:** Resolved in §31: seven fixed slots (Head, Torso,
   left/right Arm, left/right Leg, Core) plus three extra slots.
3. **Boss augment rarity:** Resolved in §31: boss augments may be Divine when
   the loot roll allows.
4. **Run length:** A standard run is five floors (1, three weighted selections,
    15); Full Climb is 15 floors. The earlier “15–25 unique floor designs”
    estimate is superseded by a current catalog of 15 main floors plus secret
    floors, unless future content expands it.
5. **Floor naming/influence:** Resolved in §31: the latest floor catalog wins;
    remap or archive older primers, including mismatched Floor 6/7 assignments.
6. **Difficulty scale:** Resolved in §31: use the blended 70/30 formula; do not
    stack the older HP/damage bands or multiplicative alpha/beta alternate.
7. **Currency:** Resolved in §31: Credits and Nanites are synonyms; Nanites
   is the player-facing name. There is no between-run currency.
8. **Loot adjustment math:** Resolved in §31: add source bonuses as percentage
   points to tier weights, then normalize the final distribution to 100%.
9. **Hera event and boss map:** Resolved in §31: when triggered, Hera replaces
   the selected boss and appears in that boss-map slot; the proposed trigger
   chance/timing remains provisional.
10. **Tuning randomness:** Resolved in §31: tuning is player-chosen; only
    initial drops may be randomly pre-upgraded.
11. **Consumable action points:** Resolved in §31: Focus is the sole action
    resource; normalize Energy, Mana, and AP examples to Focus.
12. **Statuses:** The supplied catalog is described as “OG 50,” but fewer than
    50 named entries have been provided so far; treat it as the current known
    subset rather than assuming missing definitions.
13. **Boss access:** Resolved in §31: bosses may require a run interaction,
    a persistent unlock earned from an earlier interaction, or lore
    progression. Limiting the boss pool during balance testing is a developer
    test setup, not a player-facing progression rule. Per-boss conditions and
    map updates after late interactions still need specification.
14. **Lore truth disclosure:** Resolved in §31: let players infer accuracy
    through collection and Tower changes; do not label entries True/False.
    The old three-perspective structure is not confirmed.
15. **Move-count estimate:** Resolved in §31: each augment has 2–3 regular
    moves plus a separate Overdrive move. Treat the broad total-count estimates
    as planning targets, not a conflicting move-count rule.

## 21. Floor 1 encounter design and enemy roster

### Design goals

- Reflect the Rotting Resort's luxury-decay theme.
- Draw from early Vega propaganda, survivor culture, and Choir murmurs without
  revealing deeper Tower mysteries.
- Mix risk/reward, light lore, minor augments, and resource exchanges.
- Keep early-floor complexity low: normally one or two decision branches and
  short combats.
- Favor readable fights that let players test their basic moves.

### Systemic enemy rules

- Enemies may Block/Guard when scripted, often below a specified 20–50% HP
  threshold.
- Coordinated encounter scripts are stronger than generic stat inflation:
  Bellhop pairs synchronize from Turn 3; Choir/Ritualist/Drone groups coordinate
  target priorities; Attendants heal the lowest-HP swarm unit and avoid wasted
  healing; Mascot + Choir opens with Taunt and teamwide debuff.
- Janitor Swarms gain damage from surviving swarm count, creating a threat if
  ignored.

### Post-patch regular enemies

| Enemy | HP | Damage | Guard | Moves and AI |
|---|---:|---:|---:|---|
| Chrome Bellhop | 24 | 6 | 8 | Single Strike 6 physical; Double Strike 2×4; Guard +8. T1 Single, then alternate Single/Double; focus lowest-HP player. With a Bellhop ally, sync Double on odd turns from T3. |
| Rotting Spa Attendant | 20 | 4 | 7 | Heal lowest-HP ally 8; Gospel Mark: target +25% damage dealt/+30% taken for 2 turns; Mark-Strike: next ally hit on marked player heals 5 (once/turn); Guard +7. T1 heal; then 60% heal/40% mark. Always heal Bellhop at ≤50% HP; at own ≤50%, 25% Guard chance. |
| Mascot Construct | 40 | 5 | 12 | Taunt redirects attacks to Mascot for 1 turn; Haymaker 5; Brace +12. T1 Taunt; then Haymaker/reapply Taunt. At ≤50% HP, 30% Brace chance. |
| Choir Drone | 18 | 4 | 6 | Dissonant Chant applies Fractured (−5% damage dealt, 1 stack/3 turns) to all player targets; Screech 4 sonic; Guard +6. T1 70% Chant/30% Screech; Chant until all are affected, then Screech. Alone at ≤50% HP, 25% Guard chance. |
| Ritualist Cultist | 28 | 6 | 7 | Echoed Trauma (+30% next hit); Time Fracture (delay next action 1 turn); Blood Rite 6 physical; Summon Janitor (12 HP/4 damage); Guard +7. Opens Trauma or Time Fracture if player HP high. Earliest summon T3 if allies alive <2 or player HP ≤60%, otherwise Blood Rite. Every 4th turn may Time Fracture except T1. At ≤50% HP, 20% Guard chance. |
| Janitor Swarm | 15 | 5 (6 if pack active) | — | Zap tech damage. Pack bonus at 3+ living swarm units. Every 4th round, all Swarms use Overload (+25% damage that turn). Always attacks; cannot Guard. |
| Rotborn Patient | 30 | 5 | 8 | Infecting Slash: 5 physical + Fleshrot (3% current HP DoT, 3 turns, up to 5 stacks); Contagion Cough applies one Fleshrot; Guard +8. Alternate Slash/Cough. At ≤50% HP, 35% Guard chance if player has Fleshrot; otherwise prioritize adding it. |
| Maintenance Drone | 24 | 7 tech | 8 | Stormcharged Shot: 7 tech plus adjacent splash of 15% (floor, minimum 1); Guard +8. T1 shot, then Attack/Guard alternate. If Choir Drone present, prefer debuffed targets. |
| Concierge Herald (Mini-Elite) | 58 | 9 | 10 | Gospel Proclamation; Anointed Strike 9 physical (+2 and heal Herald 5 if player marked); Pride Anthem gives allies +1 damage for 2 turns; Guard +10. T1 Proclamation, then Strike/Anthem alternate. At ≤50% HP, 50% Guard chance. Reserve for elite nodes, not hard regular nodes. |
| Echo-Tainted Staff | 32 | 6 | 7 | Time Fracture; Echoed Trauma; Rusted Swipe 6 physical; Panic Guard +7. T1 control; then attack/control alternate. Alone and at ≤40% HP, prefers Panic Guard. |

### Easy solo test variants

These are lower-stat encounter-specific versions; do not overwrite the regular
enemy baseline table.

| Solo | HP / Damage / Block | Script |
|---|---|---|
| Chrome Bellhop | 22 / 5 / 6 | T1 Single; then alternate Single/Double; targets lowest HP. |
| Rotting Spa Attendant | 18 / 4 / 5 | T1 heal lowest ally (self if solo); then 70% Heal/30% Gospel Mark. |
| Mascot Construct | 38 / 4 / 8 | T1 Taunt; then attack/Taunt alternate; below 50% HP, 20% Block chance. |
| Choir Drone | 17 / 3 / 4 | T1 70% Debuff/30% Attack; reapply until all player statuses applied. |
| Ritualist Cultist | 25 / 5 / 5 | T1 Echoed Trauma; then 50% Summon (no effect solo)/50% Attack. |
| Janitor Swarm (single) | 14 / 4 / 4 | Always attacks; Overload every 4 turns (+25%). |
| Rotborn Patient | 28 / 4 + DoT / 6 | Alternate Attack/Fleshrot; below 50% HP, 30% Block chance. |
| Maintenance Drone | 22 / 6 tech / 6 | T1 Stormcharged splash (15%); then Attack/Block alternate. |
| Echo-Tainted Staff | 30 / 5 / 6 | T1 Time Fracture or Echoed Trauma; then Attack/Control alternate; occasional low-HP Block. |

## 22. Floor 1 encounter composition and weighting

Weights in this section are relative to their stated selection layer. Keep
encounter-specific scripts as overrides to the generic enemy AI.

### Easy duos

- **Mascot + Attendant (Wall + Medic):** Mascot Taunts T1; Attendant heals
  Mascot T1 and prioritizes it while Taunting.
- **Mascot + Staff (Tank + Controller):** Taunt plus alternating Staff control
  and attacks.
- **Mascot + single Janitor (Front + Poke):** Taunt while Swarm chips; Swarm
  Overloads T4 if alive.
- **Choir + Attendant (Support Synergy):** Attendant heals/buffs, Choir keeps
  debuffs active.
- **Staff + Attendant (Control + Sustain):** Staff debuffs, Attendant heals.
- **Choir + single Janitor (Buzz + Debuff):** Team debuff plus consistent
  Swarm attack.
- **Staff + Choir (Dual Control):** Both open with debuffs; Staff then attacks,
  Choir prefers un-debuffed players.
- **Ritualist + Attendant (Debuff + Sustain):** Trauma opener and healing;
  Ritualist applies Time Fracture mid-fight.
- **Staff + single Janitor (Control + Poke):** Control lock plus Swarm chip.
- **Mascot + Maintenance Drone (High-Easy / Shield + Shock):** Taunt protects
  the Drone, which uses Stormcharged and alternates Attack/Block.

### Medium composition scripts

- **Bellhop + Bellhop:** Both use Double on odd turns from T3, targeting the
  same lowest-HP player.
- **Bellhop + Maintenance Drone:** Drone attacks T1; Bellhop uses Double T2 to
  align with Drone's next attack T3. Thereafter Drone alternates Attack/Guard,
  Bellhop Single/Double, syncing where possible.
- **Mascot + Choir:** T1 Taunt + Dissonant Chant; Choir maintains Chant,
  Mascot refreshes Taunt and Braces at ≤50% HP.
- **Ritualist + Choir:** T1 Trauma + Chant. Ritualist delays summon to T3 and
  summons only if allies <2 or player HP ≤60%. Choir targets un-debuffed
  players; Ritualist may Time Fracture every fourth turn after T1.
- **Ritualist + Drone + Bellhop:** T1 Trauma, Stormcharged Shot, Single; T2
  Double, Guard, Blood Rite. T3+ conditional summon; Drone attacks and Bellhop
  alternates, syncing Double with Drone attacks when possible.
- **Attendant + Janitor Swarm ×3:** Heal lowest-HP Swarm every other turn;
  avoid buffs at full HP. If player is Gospel-Marked, prioritize Mark-Strike
  setup.
- **Mascot + Rotborn + Choir:** T1 Taunt, Slash, Chant. Mascot Braces on third
  cycle if ≤50%; Rotborn alternates Slash/Cough; Choir maintains Chant before
  Screech.
- **Mascot + Bellhop (Breather):** Taunt stays active; Bellhop alternates
  attacks without sync; Mascot Braces more often from T4 (every third turn).

### Easy band weights (sum to 100 within each subtype)

**Solos:** Chrome Bellhop 14; Attendant 13; Mascot 10; Choir Drone 12;
Ritualist 10; single Janitor 13; Rotborn 9; Maintenance Drone 7; Echo-Tainted
Staff 12.

**Duos:** Mascot+Attendant 14; Mascot+Staff 10; Mascot+single Janitor 10;
Choir+Attendant 12; Staff+Attendant 11; Choir+single Janitor 9; Staff+Choir 9;
Ritualist+Attendant 10; Staff+single Janitor 8; Mascot+Maintenance Drone
(High-Easy) 7. The pool favors readable orientation fights and teachable
support/debuff pairings; Drone and Rotborn solos are slightly suppressed for
chip/attrition.

### Medium pool and target player win rates

| Encounter | Class | Target win rate |
|---|---|---:|
| Bellhop + Ritualist | High-End Medium | 66–70% |
| Mascot + Choir | Standard Medium | 70–74% |
| Rotborn + Attendant | Standard Medium | 63–67% |
| Ritualist + Drone + Bellhop | Standard Medium | 64–68% |
| Janitor Swarm ×3 + Attendant | Standard Medium | 72–76% |
| Mascot + Rotborn + Choir | High-End Medium | 61–65% |
| Bellhop + Maintenance Drone | Standard Medium | 68–72% |
| Ritualist + Choir | Standard Medium | 62–66% |
| Mascot + Bellhop (Breather) | Breather | 80–82% |

Relative multiplier within Medium pool: Standard 1.0×; High-End 0.6×; Breather
0.8×.

### Hard encounter test results

| Encounter | Player win | Enemy win | Avg HP lost | Avg turns |
|---|---:|---:|---:|---:|
| Bellhop + Bellhop (sync Double) | 42% | 58% | 65 | 6 |
| Ritualist + Choir | 40% | 60% | 68 | 7 |
| Ritualist + Maintenance Drone | 38% | 62% | 72 | 6 |
| Maintenance Drone + Bellhop | 44% | 56% | 62 | 6 |
| Mascot + Rotborn + Choir | 41% | 59% | 70 | 8 |
| Ritualist + Rotborn | 45% | 55% | 60 | 7 |
| Janitor Swarm ×3 (no Attendant) | 39% | 61% | 74 | 6 |
| Echo-Tainted Staff + Bellhop | 43% | 57% | 66 | 6 |
| Ritualist + Bellhop + Choir | 36% | 64% | 76 | 8 |
| Mascot + Maintenance Drone | 47% | 53% | 58 | 7 |

Hard scripts emphasize burst + control, coordinated synchronization, or pack
synergy; no blanket enemy stat buffs in the draft. Version 2 further specifies
Bellhop+Ritualist control followed by Bellhop Double from T3; Mascot+Choir
Taunt/debuff attrition; Rotborn+Attendant DoT/sustain (8–9 turns); Ritualist+
Drone+Bellhop synergy; Swarm ×3 + Attendant Overload sustain; Double Bellhop+
Attendant synchronized burst; Choir+Ritualist+Bellhop+Drone quad; and Janitor
Horde ×4 as an AoE check.

### Hard-band mix and category weights (Version 2)

- Hard nodes: proposed map nodes **7–9**; outside-band weights default to 0.
- Mix within Hard: Elite Duos 10%, Trios 60%, Quads 30%.
- Weights below normalize to 100 inside their category slice.

**Elite Duos:** Concierge Herald+Bellhop 40; Herald+Choir 35;
Herald+Ritualist 25.

**Trios:** Ritualist+Choir+Drone 16; Rotborn+Drone+Choir 13;
Mascot+Bellhop+Drone 10; Bellhop+Bellhop+Attendant 12;
Staff+Drone+Bellhop 10; Ritualist+Rotborn+Staff 10;
Mascot+Ritualist+Choir 9; Rotborn+Janitor×2 8;
Bellhop+Bellhop+Drone 12.

**Quads:** Ritualist+Choir+Bellhop+Drone 28;
Ritualist+Janitor×2+Choir 20; Mascot+Rotborn+Bellhop+Choir 18;
Staff+Bellhop+Janitor×2 14; Mascot+Bellhop+Drone+Choir 20.

**Mid-band spillover (nodes 4–6):** 15% global chance, lower-Hard trios only:
Mascot+Bellhop+Drone 30; Staff+Drone+Bellhop 35; Rotborn+Drone+Choir 35.
Spillover elites: Herald+Bellhop 60; Herald+Choir 40. Quads disabled.

### Per-encounter depth weights (verification draft)

Weights are relative per encounter/band; Early = nodes 1–3, Mid = 4–6, Late =
7–9; zero disables that encounter in the band.

| Encounter | Early | Mid | Late |
|---|---:|---:|---:|
| **Easy solos** ||||
| Bellhop | 14 | 3 | 0 |
| Attendant | 13 | 3 | 0 |
| Mascot | 10 | 2 | 0 |
| Choir Drone | 12 | 3 | 0 |
| Ritualist | 10 | 3 | 0 |
| Janitor (single) | 13 | 3 | 0 |
| Rotborn | 9 | 3 | 0 |
| Maintenance Drone | 7 | 2 | 0 |
| Echo-Tainted Staff | 12 | 3 | 0 |
| **Easy duos** ||||
| Mascot + Attendant | 14 | 4 | 1 |
| Mascot + Staff | 10 | 4 | 1 |
| Mascot + Janitor (single) | 10 | 3 | 0 |
| Choir + Attendant | 12 | 4 | 1 |
| Staff + Attendant | 11 | 4 | 1 |
| Choir + Janitor (single) | 9 | 3 | 0 |
| Staff + Choir | 9 | 4 | 1 |
| Ritualist + Attendant | 10 | 4 | 1 |
| Staff + Janitor (single) | 8 | 3 | 0 |
| Mascot + Maintenance Drone | 6 | 5 | 2 |
| **Medium compositions** ||||
| Bellhop + Bellhop | 0 | 8 | 6 |
| Bellhop + Maintenance Drone | 1 | 9 | 7 |
| Mascot + Choir | 2 | 10 | 6 |
| Ritualist + Choir | 2 | 12 | 7 |
| Ritualist + Drone + Bellhop | 0 | 13 | 10 |
| Attendant + Janitor ×3 | 0 | 9 | 8 |
| Mascot + Rotborn + Choir | 0 | 10 | 8 |
| Mascot + Bellhop (Breather) | 3 | 8 | 4 |
| **Hard compositions** ||||
| Bellhop + Ritualist | 0 | 5 | 12 |
| Mascot + Choir | 0 | 4 | 10 |
| Rotborn + Attendant | 0 | 5 | 11 |
| Ritualist + Drone + Bellhop | 0 | 6 | 14 |
| Janitor ×3 + Attendant | 0 | 5 | 11 |
| Mascot + Rotborn + Choir | 0 | 4 | 10 |
| Double Bellhop + Attendant | 0 | 3 | 9 |
| Choir + Ritualist + Bellhop + Drone | 0 | 2 | 12 |
| Janitor Horde ×4 | 0 | 3 | 9 |

### Map-depth class mix (separate proposal)

- **Opening (1–3):** 60% Easy / 30% Medium / 10% Special. Favor solos, basic
  duos, simple trios; exclude hordes and debuff-heavy Choir groups. Example
  breakdown: 40% solos, 40% simple duos, 10% simple trios, 10% special/
  mini-elite.
- **Mid (4–6):** 30% Easy / 50% Medium / 20% Special. Favor synergy trios and
  light four-unit groups. Example: 20% solo/duo, 50% synergy trios, 20% four-
  enemy horde, 10% rare special/elite-lite.
- **Late (7–9):** 10% Easy / 40% Medium / 50% Special. Favor elite-tagged,
  horde, and heavy synergy encounters. Example: 10% breather trios, 40%
  synergy trios/quads, 40% horde/elite-like groups, 10% rare special event.

Class mix, category-slice weights, and per-encounter depth weights are distinct
selection layers; do not combine without specifying normalization order.

## 23. Floor 1 mini-bosses and boss concepts

### Mini-boss relative weights

Normalize by depth before selection; supplied totals are not 100.

| Mini-boss | Difficulty | Early | Mid | Late | Notes |
|---|---|---:|---:|---:|---|
| Chrome Butler | Medium–Hard | 30 | 35 | 40 | Balanced bruiser/support baseline. |
| Mold-Grown Bouncer | Hard | 20 | 30 | 35 | Heavy hits/retaliation; punishes over-blocking. |
| Parasite Choir ×2 | Hard | 15 | 25 | 30 | Debuff pressure; damage scales over time. |
| Chrome Bellhop Swarm | Medium | 35 | 30 | 25 | Fast, spiky early threat; dangerous if ignored. |
| Worship Hall Matron | Hard | 10 | 25 | 35 | Gospel Mark and buff synergy; dangerous in drawn-out fights. |

### Boss behavior prototypes

Move weights are AI selection weights, not boss spawn weights.

**Matron of the Crown:** Gospel Mark (30; opener/priority if player unmarked);
Benediction (25, +15 below 50% HP or while attendants alive); Attendants'
Assist (20, +20 if attendant alive and Benediction active); Royal Strike (15,
+20 if target marked and Benediction active, 30% double-hit). Cycle Gospel →
Benediction → Assist → Strike. Below 25% HP, Gospel and Strike weights become
40 each.

**Choir of Parasites:** Viral Hymn (35; always T1, +10 if player lacks Viral
Bloom); Basic Attack (30 fallback); Rot Chorus (35, +20 with ≥2 drones alive,
+50 on T3 or T6). Cycle Hymn → Attack → Chorus. Each fallen drone gives
survivors +10% damage; solo drone gains +30 Attack weight and double actions.

**The Concierge Revenant:** Mimicry (40; T1 and every 3 turns, hides/deceives
intent UI and applies Echoed Trauma); Veiled Strike (25, +10 while Mimicry
active, 25% Echoed Trauma); Phase Shift (20, +30 below 40% HP or while Mimicry
cooldown pending); Reality Twist (15, +30 if Mimicry active and turn ≥4).
Cycle Mimicry → Veiled → Shift → Twist. Below 30% HP, alternate Veiled/Twist
50/50.

**The Failed Ascendant:** Erratic Flare (35, +15 T1 or above 75% HP; random
debuff/light AoE); Heavy Flare (25, +20 at 50–75% HP, 15% misfire); Rot Surge
(20, +20 at 25–50%, self-damage 5%); Overdrive Spike (20, +25 below 50%, AoE
and misfire). Cycle Erratic → Heavy → Surge → Spike. Below 50%, self-damage
doubles and Overdrive occurs every third turn.

**The Rotting Siren:** Siren's Call (35; always T1, +20 if neither Viral Bloom
nor Echoed Trauma present); Refrain (25, +25 if player debuffed); Harmonic
Lash (20, +30 if player cleared debuffs last turn); Pitch Break (20, +30 if
preview set, +50 on T4/every third cycle). Cycle Call → Refrain → Lash →
Pitch Break. Below 25% HP, Call every 2 turns and Pitch Break every 3.

### Floor 1 boss pool weights

| Boss | Weight |
|---|---:|
| Matron of the Crown | 24 |
| Choir of Parasites | 21 |
| The Concierge Revenant | 20 |
| Chrome-Rot Contestant | 18 |
| Mycelial Host & Nodes | 17 |
| **Total** | **100** |

Chrome-Rot Contestant and Mycelial Host & Nodes are named pool entries without
complete mechanics in the current notes.

## 24. Floor 1 events, vendor, and economy

### Random encounter pool

- **Corporate/Vega:** Welcome Desk; Executive Memo Room; Nanite Dispensary
  Overflow; Executive Recruitment Hologram; Server Cathedral; Vendor —
  Chrome Trader's Alcove.
- **Environmental/infrastructure:** Resort Bathhouse; The Leaking Wall;
  Shifting Corridor; Maintenance Bot.
- **Choir/rust cult:** Choir in the Hall; The Choir's Ashes; Rust Lottery
  Stall; The Chained Choirboy; Rust Graffiti Ritual; The Rustling Tent; The
  Singing Mask; Rust Choir Procession.
- **Survivors/scavengers/caravan:** Wandering Scavver; Broken Caravan Wagon;
  Caravan Storyteller; Wasteland Toll Booth; Chrome Scavver Duel; Chrome
  Peddler.
- **Anomalous/architecture/temporal:** The Mind-Broker; Security Checkpoint;
  Temporal Rift; Echoing Elevator.
- **Special/gamble/later-game links:** Experimental Vending Unit; Scrap
  Apostles; Rusted Wheel of Wagers; Echo of Tomorrow.
- Node outcomes also include Regular Combat, Treasure Chest, Elite Combat.
- Recommended distribution: Regular Combat 40–45%; random events (excluding
  combat/vendor entries) 30–35%; Elite Combat 10%; Treasure Chest 10%; Vendor
  5%. Normalize the ranged values at runtime.

### Chrome Trader's Alcove

**Flavor:** A scavver-merchant squats beneath flickering Vega signage, with
augments dangling like windchimes and a terminal flashing “SPECIAL OFFER.” His
half-metal jaw creaks: “Everything's for sale. Even the parts you didn't know
you could sell.”

| Section | Stock | Count | Pricing | Notes |
|---|---|---:|---|---|
| Top row | Echoes/relics | 2–3 | High | 1 Rare/Uncommon, 1 Common; one may be corruption-tainted (cheap but risky). |
| Middle row | Augments/implants | 2–4 | Medium | Offensive, defensive, utility mix. |
| Bottom row | Consumables/items | 3–4 | Low | Healing, buffs, Nanite injections, improvised tools. |

**Floor 1 prices:** Common consumable 25–50 Nanites; Common augment 75–125
Nanites; Uncommon augment 125–175 Nanites; Rare augment 175–250 Nanites;
Echo 200–300 Nanites; Corrupted relic 100–175 Nanites; removal 50 Nanites
+25 Nanites per prior use.

**Special slots**

- **Augment Removal Terminal:** Pay Nanites to permanently remove one augment
  or a negative Chrome Rot effect; cost starts low and scales with each use
  per run. Flavor: cracked medical chair, “Don't worry. It only hurts if you
  survive.”
- **Special Offer Terminal:** One randomized item of any tier is discounted
  30–50%; it may be a genuine bargain or a glitchy trap (e.g. hidden relic
  corruption). Hologram: “LIMITED DEAL — Ascend Today!”

**Dialogue bank**

- Greetings: “The Tower eats the bold and sells their bones back cheap. You
  buying or selling, shiny?”; “Chrome don't rust if you keep it moving. You
  look like you could use some movement.”; “Ignore the smell. That's just the
  wares… or me. Hard to tell these days.”; “Everything here's got a story.
  None of 'em end pretty.”; “Vega built it. I broke it. Now you get to buy it
  back. Circle of life, yeah?”
- Showing augments/Echoes: “Pulled this off a choir zealot still hummin'. Don't
  ask how.”; “Corporate issue. Fell off the back of a drone. Or the front.
  Hard to say.”; “You put this in your head, it might talk back. Some folks
  like that.”; “This one's rare. Either top shelf or cursed. Sometimes both.”
- Offer terminal: “Terminal's got opinions. Says this one's special. Don't
  keep it waiting.”; “Ah, the ghost in the wires wants to make a deal. Lucky
  you.”; “See that word blinking? SPECIAL. Means 'dangerous' nine times outta
  ten.”; “Price is lower, consequences higher. My kinda bargain.”
- Leaving: “Suit yourself. Someone else'll buy it when you're dead.”; “Come
  back with more nanites… or less blood. Either works.”; “The Tower don't give
  refunds. Neither do I.”; “Walk away if you want. Everything worth having
  gets taken anyway.”

## 25. Floor 1 augment testing catalog

These are archetype/build prototypes rather than final balance. Focus is the
sole action resource; authored Energy, Mana, and AP costs/rewards are normalized
to Focus. Cooldown timing, damage types, and status definitions still need one
canonical ruleset.

### Meatbag archetypes

**Core rule:** Pure Meatbag augments have 0% HP-softcap contribution and do not
unlock or grant Overdrives. Cross-archetype Meatbag augments (such as Meatbag ×
Chrome Titan or Meatbag × Netrunner) may have a nonzero softcap contribution.
Meatpurist-only **Herculean** abilities unlock
when Max HP has increased by a threshold (examples: +20% or +25%). They are
cooldown abilities with no misfire, weaker than true Overdrives. Meatbag power
is lower per augment but grows through cross-augment synergy, consumables,
anti-tech hacks, and HP scaling: “jack of all trades, master of none.”

**Riskrunner — high risk/high reward**

- **Rusted Sidearm (Arm):** Last Shot (Attack, 1 Focus/CD1): 10 damage, or 15
  below 50% HP. Desperate Reload (Defensive, 0/CD3): lose 5 HP, +1 Focus
  next turn. Extra: +10% damage below 50% HP.
- **Jury-Rigged Exosleeve (Torso):** Adrenal Surge (Buff, 1/CD3): lose 5 HP,
  +25% damage for 2 turns. Patchwork Guard (Defensive, 0/CD2): +8 Block.
  Extra: +5 Max HP.
- **Burnout Goggles (Head):** Clarity Under Fire (Buff, 0/CD3): below 50% HP,
  +1 Focus for 2 turns. Bloodshot Glare (Attack, 1/CD2): 6 AoE damage and
  4 self-damage. Extra: +5% crit below 50% HP.
- **Rusted Runner Boots (Leg, Rare):** Blood Rush (Buff, 0/CD3): +2 Focus
  next turn and take 8 damage. Charge Kick (Attack, 1/CD1): 12 damage; below
  50% HP gain 5 Block. Extra: +10% damage below 50% HP.

**Alchemist / Tech Saboteur — consumables, gadget tricks, EMP**

- **Satchel of Tricks (Torso):** Quick Mix (Buff, 1/CD3): double next
  consumable used this turn. Metal Scrambler (Hack, 1/CD2): Hacked enemy takes
  +20% consumable damage this turn. Extra: gain a random consumable entering
  elite combat.
- **Scrap Goggles (Head):** Spot Weakness (Buff, 0/CD3): next consumable
  ignores defenses. Jury-Rig EMP (Hack, 1/CD2): Hacked and −20% damage for
  1 turn. Extra: +1 consumable slot.
- **Gadgeteer's Gloves (Arm):** Tinker (Buff, 0/CD3): gain one random minor
  consumable. Throwing Charge (Attack, 1/CD1): 8 damage, consumes a random
  consumable for +6 damage. Extra: +15% consumable effectiveness.
- **Bomb-Runner Boots (Leg, Rare):** Alchemical Dash (Buff, 1/CD3): consume
  an item for +20% damage for 2 turns. EMP Pulse (Hack, 1/CD3): Hacked all
  enemies; already-Hacked enemies take 10 AoE. Extra: first consumable each
  combat is cast twice.

**Meatpurist — flesh tanking and Max HP**

- **Iron Will Plating (Torso):** Grit Bash (Attack, 1/CD1): 7 damage +4
  Block. Fortify (Defensive, 1/CD2): +12 Block. Extra: +4 Max HP. Herculean
  Unbreakable Stance (2/CD4): +20 Block and cleanse all debuffs.
- **Pulse-Bound Gauntlet (Arm):** Meat Hook (Attack, 1/CD1): 8 damage, heal
  4 if target <50% HP. Guard Breaker (Attack, 1/CD2): 10 damage ignoring
  50% Block. Extra: +3 Max HP. Herculean Crushing Resolve (2/CD4): 15 damage
  and heal 10% Max HP.
- **Juggernaut Greaves (Leg):** Stomp (Attack, 1/CD1): 6 AoE. Brace for
  Impact (Defensive, 0/CD2): +8 Block. Extra: +3 Max HP. Herculean March of
  Flesh (2/CD5): 10 AoE and +10 Block.
- **Meat Crown Implant (Head, Rare):** Battle Focus (Buff, 0/CD3): +25%
  damage for 2 turns. Shout of Defiance (Buff, 1/CD3): all allies +5 Block.
  Extra: +5 Max HP. Herculean Titan's Roar (2/CD5): +20 Block, +25% damage
  for 2 turns, cleanse debuffs.

### Chrome Titan build tests

**Burst build — all-in offense**

- **Neural Impact Driver (Head, Common, softcap 8%):** Power Jab (Attack,
  1/CD0): 7 damage, +4 if target <50% HP. Adrenal Surge (Buff, 1/CD3): next
  attack +25% and +1 temporary Focus. Extra: first attack each turn +2.
  Overdrive Critical Repeater (2/CD6): 18 single-target damage; on crit apply
  Vulnerable for 2 turns.
- **Overclocked Core Plating (Torso, Common, 10%):** Chrome Slam (Attack,
  2/CD2): 12 damage, +5 vs Vulnerable. Core Pulse (Buff, 1/CD3): +20% damage
  for 2 turns. Extra: first time reaching low HP each combat, +1 Focus.
  Overdrive Reactor Burst (3/CD7): 20 AoE, apply 1 Vulnerable to each.
- **High-Pressure Striker (Arm, Uncommon, 12%):** Hydraulic Uppercut (Attack,
  2/CD1): 14 damage; if target <50%, +1 temporary Focus. Vent Steam
  (Defensive Buff, 1/CD3): +10 Block and +10% damage until end of next turn.
  Extra: +1 damage per attack already played this turn. Overdrive Seismic
  Breaker (3/CD6): 24 damage and Stagger (+25% damage taken) for 1 turn.
- **Momentum Stabilizers (Leg, Rare, 15%):** Charge Drive (Attack, 1/CD1):
  8 damage; next attack this turn deals double. Reactive Vault (Defensive,
  1/CD3): +8 Block, +6 more if attacked this turn. Extra: +1 temporary Focus
  for attacking twice in a turn. Overdrive Titan Rush (3/CD7): 30 randomly
  split damage; each kill grants +1 permanent HP this combat.

**Turtle build — Block/retaliation/attrition**

- **Impact Echo Helm (Head, Common, softcap 8%):** Guard Up (Defensive, 1/CD0):
  +10 Block. Sensor Ping (Buff, 1/CD3): +25% Block effectiveness for 2
  turns. Extra: +2 Block on first defensive ability each turn. Overdrive
  Shockwave Wall (3/CD6): +25 Block and deal 10 to all enemies when gained.
- **Reinforced Alloy Plating (Torso, Common, 10%):** Plating Slam (Attack,
  1/CD1): 8 damage +8 Block. Anchor Down (Buff, 2/CD4): +50% Block from all
  sources for 1 turn. Extra: whenever Block gained, reflect 2 damage to all
  attackers. Overdrive Fortress Mode (3/CD8): +35 Block and reflect 50% of
  incoming damage for 2 turns.
- **Counterweight Gauntlets (Arm, Uncommon, 12%):** Parry Strike (Attack,
  1/CD1): 6 damage +6 Block; next attack against you this turn deals −50%.
  Counter Channel (Buff, 2/CD3): for 1 turn gain Block equal to 50% of
  damage taken before Block. Extra: +2 Block when attacking after blocking.
  Overdrive Magnetic Riposte (3/CD7): deal one target twice current Block.
- **Reflective Stabilizers (Leg, Rare, 14%):** Chrome Brace (Defensive,
  1/CD0): +12 Block, +6 if already blocked this turn. Repositioning Slam
  (Attack, 1/CD2): 10 damage +4 Block. Extra: +3 Block each time you hit an
  enemy this turn. Overdrive Retribution Drive (3/CD8): +20 Block and AoE
  damage equal to 50% of total Block gained this turn.

**Overdrive Engine build — cooldown/power cycling**

- **Synapse Booster (Head, Common, softcap 8%):** Reboot Protocol (Buff,
  0/CD5): reduce all current cooldowns by 1. Charge Surge (Buff, 1/CD3): +1
  Focus. Extra: when an Overdrive goes on cooldown, reduce its cooldown by 1.
  Overdrive System Recalibration (2/CD6): reduce non-Overdrive cooldowns by 2
  and gain +1 Focus.
- **Reactor Stabilizer (Torso, Common, 9%):** Internal Overclock (Buff, 1/CD3):
  reduce Overdrive cooldowns by 1, take 4 damage. Thermal Vent (Attack, 1/CD2):
  6 AoE and enemies −20% damage for 1 turn. Extra: first Overdrive each
  combat +20% damage. Overdrive Pulse Cascade (3/CD7): 20 AoE; refresh one
  random ability cooldown per target hit.
- **Flux Gauntlet (Arm, Uncommon, 12%):** Focus Punch (Attack, 2/CD1): 14
  damage and reduce Overdrive cooldown by 1. Venting Channel (Buff, 1/CD3):
  next Overdrive this combat +30% damage. Extra: Overdrive activation grants
  +2 temporary Block. Overdrive Arc Breaker (3/CD6): 22 damage and reset one
  random basic ability cooldown.
- **Kinetic Feedback Actuators (Leg, Rare, 15%):** Drive Link (Buff, 1/CD3):
  reduce all cooldowns by 1 and gain +1 temporary Focus. Power Stomp (Attack,
  2/CD2): 15 damage; next Overdrive cooldown −2. Extra: +1 Focus on Overdrive.
  Overdrive Overdrive Cascade (3/CD7): 20 AoE, reset one random ability, and
  reduce its own cooldown by 2.

### Netrunner archetype tests

**Hackmage — offensive Hack spam**

- **Neural Surge Band (Head, Common, softcap 5%):** Pulse Spike (Hack,
  1/CD0): 5 damage + Hacked. Code Lash (Hack, 2/CD2): 10 damage, +8 if
  already Hacked. Extra: +1 Focus regen when Hacking a Hacked target.
  Overdrive Neural Storm (3/CD4): 15 AoE Hack damage, double against already
  Hacked enemies.
- **Circuit-Stitched Arm (Arm, Common, 7%):** Data Lance (Hack, 1/CD1):
  8 damage + Hacked. Static Spike (Hack, 0/CD2): 4 damage to all Hacked
  enemies. Extra: first Hack each turn costs 0 against Hacked target.
  Overdrive System Cascade (4/CD5): repeat last Hack used this turn on all
  Hacked enemies.
- **Surge Torso Rig (Torso, Uncommon, 8%):** Feedback Burn (Hack, 2/CD2):
  12 damage + Hacked, 4 self-damage. Phase Cutter (Hack, 1/CD1): 6 damage;
  if target Hacked, remove one of your debuffs. Extra: +10% Hack damage vs
  Hacked. Overdrive Chain Pulse (3/CD4): hit random Hacked enemies 5 times
  for 4 each.
- **Hyperlink Boots (Leg, Rare, 10%):** Quick Inject (Hack, 0/CD0): reduce
  another Hack cooldown by 1. Arc Jolt (Hack, 2/CD2): 8 AoE; if enemies are
  Hacked, Stun 1 turn. Extra: first Hack each combat refunds 1 Focus.
  Overdrive Overclock (0/CD6): reset all Hack cooldowns and +50% Hack damage
  this turn.

**Drone Summoner / Support**

- **Basic Drone Hub (Torso, Common, softcap 5%):** Deploy Gun Drone (Hack,
  2/CD2): summon drone attacking for 5 each turn. Ping Command (Hack, 0/CD1):
  all drones attack for half damage immediately. Extra: +1 drone capacity.
  Overdrive Drone Swarm (3/CD4): summon 2 temporary drones for 2 turns; they
  attack immediately.
- **Signal Booster Helm (Head, Common, 7%):** Repair Protocol (Hack, 1/CD2):
  heal self or drone 8. Command Sync (Hack, 1/CD1): drones +4 damage 1 turn.
  Extra: drones +2 damage if you Hacked this turn. Overdrive Core Uplink
  (3/CD5): drones +100% damage and take an extra turn immediately.
- **Auxiliary Arm Array (Arm, Uncommon, 8%):** Deploy Shield Drone (Hack,
  2/CD3): summon drone granting 5 Block per turn. Static Reinforce (Hack,
  1/CD2): all drones +5 HP and refresh their action. Extra: +1 Block whenever
  a drone attacks. Overdrive Drone Fusion (4/CD5): merge drones into a
  super-drone with triple damage and HP.
- **Reinforced Pilot Legs (Leg, Rare, 10%):** Drone Recall (Hack, 0/CD1):
  heal all drones 5. Support Field (Hack, 2/CD3): allies incl. drones +2
  damage and +5 Block for 2 turns. Extra: +1 drone capacity; drones start
  combat at full action. Overdrive Skyfall Protocol (3/CD6): drones
  self-destruct for current HP as AoE, then respawn at half HP.

**Control / debilitation**

- **Static Interference Band (Head, Common, softcap 5%):** Static Field (Hack,
  1/CD2): Hacked all enemies and −20% damage for 1 turn. Weak Pulse (Hack,
  1/CD1): 5 damage + Weakened 2 turns. Extra: Hacked enemies gain 1 less
  Focus for 1 turn. Overdrive Jam Field (3/CD5): Hacked enemies skip their
  next attack.
- **Scramble Torso (Torso, Common, 6%):** System Lag (Hack, 2/CD2): Hacked
  target's abilities delayed 1 turn. Feedback Loop (Hack, 1/CD2): reflect
  next Hack/debuff aimed at you. Extra: first debuffing Hack each turn grants
  2 Block. Overdrive Blackout Surge (4/CD5): Hacked enemies lose next action
  and take 10 damage.
- **Interference Arm (Arm, Uncommon, 8%):** Lock Command (Hack, 2/CD3): Stun
  Hacked enemy 1 turn. Static Chain (Hack, 1/CD2): 4 damage, spread Hacked
  to adjacent targets. Extra: +1 turn to debuffs applied to Hacked enemies.
  Overdrive EMP Burst (3/CD4): 10 AoE Hack damage and Hacked + Weaken all.
- **Pulse Dampener Boots (Leg, Rare, 10%):** Redirect Circuit (Hack, 0/CD2):
  redirect next single-target enemy attack to another Hacked enemy. Neural
  Slow (Hack, 2/CD2): Hacked target and reduce ability triggers by 1 next
  turn. Extra: +1 Focus when disabling/redirecting an action. Overdrive
  Command Override (4/CD6): control one Hacked enemy for 1 turn.

### Netrunner × Chrome Titan hybrids

- **Neural Impulse Jack (Head, Common):** Impulse Hack (Hack, 1/CD2): 6 damage
  + Hacked. Targeting Uplink (Buff, 0/CD3): +15% vs Hacked for 2 turns. Extra:
  first Hacked application/combat grants 1 Focus. Overdrive Synaptic Surge
  (2/CD5): 12 damage to all Hacked enemies and cleanse debuffs.
- **Servo-Link Arm (Arm, Common):** Data Slash (Attack, 1/CD1): 9 damage,
  +5 Block if target Hacked. Surge Pulse (Hack, 1/CD2): Hacked +4 damage.
  Extra: damaging Hacked enemy grants +2 Block. Overdrive Override Strike
  (2/CD5): 20 damage, +10 if target Hacked.
- **Pulse Anchor Torso (Torso, Uncommon):** Reactive Firewall (Defensive/Hack,
  1/CD3): +12 Block; if attacked this turn, Hacked attacker. Reboot Protocol
  (Buff, 1/CD3): cleanse one debuff and +10% damage 2 turns. Extra: blocking a
  Hacked enemy grants 3 Focus. Overdrive Core Pulse (2/CD5): 10 AoE and
  Hacked all enemies.
- **Data-Stabilizer Legs (Legs, Uncommon):** Grounded Kick (Attack, 1/CD1):
  8 damage, +4 AoE splash if target Hacked. Charge Conduit (Buff, 0/CD3):
  +1 Focus if 2+ enemies Hacked. Extra: +10% damage while any enemy Hacked.
  Overdrive Neural Cascade (2/CD5): 8 damage all, Hacked those not already
  affected.
- **Hyper-Conductive Arm (Arm, Rare):** Shock Lance (Attack, 1/CD1): 10
  damage, or 15 vs Hacked. Static Disruptor (Hack, 1/CD2): Hacked and −25%
  damage for 1 turn. Extra: +10% crit vs Hacked. Overdrive Circuit Breaker
  (2/CD5): 25 damage to one Hacked enemy, remove Hacked and heal 10.
- **Neural Exo-Core (Torso, Rare):** Feedback Loop (Hack, 1/CD3): Hacked all
  enemies above 75% HP. Power Redirect (Defensive, 0/CD3): convert 25% of
  current Block to bonus damage for next Hack. Extra: +1 Focus when Hacking
  3+ enemies in one turn. Overdrive Brainstorm Barrage (2/CD6): 8 damage all,
  then repeat once for each Hacked enemy.

### Chrome Titan × Meatbag hybrids

- **Jury-Rigged Exo-Arm (Arm, Common, softcap 5%):** Scrap Bash (Attack,
  1/CD1): 10 damage, +5 if HP <50%. Welded Guard (Defensive, 1/CD2): +12
  Block and 3 self-damage. Extra: dropping below 50% HP grants +10% damage
  for 2 turns. Theme: human grit through improvised Titan strength.
- **Chrome-Plated Shotgun Rig (Torso, Common, 8%):** Scatter Burst (Attack,
  1/CD2): 8 AoE, or 14 if exactly one enemy. Quick Reload (Buff, 0/CD3):
  +1 Focus next turn, lose 5 HP. Extra: Attack kill heals 5. Theme: Titan
  firepower powered by human risk.
- **Chrome Spine Stabilizer (Torso, Uncommon, 5%):** Reflex Clamp (Defensive,
  1/CD3): +15 Block, +10 more if HP ≥75%. Adrenal Surge (Buff, 0/CD4): heal
  10% missing HP and +15% damage 2 turns. Extra: start combat with 5 Block
  per Chrome augment. Theme: stabilize chrome for fragile flesh.
- **Cable-Jack Leg Servos (Legs, Uncommon, 6%):** Spring Kick (Attack,
  1/CD1): 9 damage, +5 Block if HP <50%. Overclock Sprint (Buff, 0/CD3):
  +10% damage 1 turn and draw 1, lose 5 HP. Extra: first self-damage each
  combat grants 1 Focus. Theme: risk-runner mobility.
- **Titan's Last Resort (Arm, Rare, 8%, Overdrive augment):** Emergency
  Plunge (Attack, 0/CD3): lose 10% current HP, deal 20. Blood-Fueled Guard
  (Defensive, 1/CD2): Block equal to 25% missing HP. Overdrive Chrome
  Rupture (2/CD5): 35 AoE, 10 self-damage, +15 if HP <30%. Extra: HP-cost
  ability makes next Attack +5. Theme: desperation.
- **Scavenged Control Harness (Head, Rare, softcap 0%, Herculean augment):**
  Reroute Power (Buff, 0/CD4): choose +15% damage 2 turns or +15 Block,
  costs 5% current HP. Discharge Blast (Attack, 2/CD4): 20 AoE, 10 recoil.
  Herculean Iron Resolve (1/CD5): heal 15% Max HP and +25% damage 2 turns,
  only if Max HP increased ≥20%. Extra: once/combat at ≤25% HP gain +1 Focus
  and +15% damage until turn end.

### Meatbag × Netrunner hybrids

- **Jury-Rigged Signal Jammer (Head, Common, softcap 4%):** Pulse Scramble
  (Hack, 1/CD2): 6 damage + Hacked 2 turns. Manual Override (Buff, 0/CD3):
  +1 Focus next turn, take 5 HP damage. Extra: first Hacked application each
  combat grants 5 Block.
- **Rusted Data Spike (Arm, Common, 5%):** Data Puncture (Hack, 1/CD1):
  8 damage + Hacked 1 turn. Rust Reverb (Attack, 1/CD3): 10 damage, +5 vs
  Hacked. Extra: +10% damage vs Hacked.
- **Scrap Signal Router (Torso, Uncommon, 3%):** Router Surge (Hack, 0/CD4):
  Hacked all enemies 1 turn. Echo Shield (Defensive, 1/CD3): +12 Block, +6
  if any enemy Hacked. Extra: start combat by Hacking a random enemy 1 turn.
- **EMP Slug Launcher (Arm, Uncommon, 6%):** EMP Shot (Hack, 2/CD3): 10 AoE
  and Hacked 1 turn. Capacitor Build-Up (Buff, 0/CD3): +15% Hack damage next
  turn, lose 5 HP. Extra: Hack 3+ enemies in one action to gain +1 Focus
  next turn.
- **Blackout Harness (Torso, Rare, 6%, Overdrive augment):** Flash Overload
  (Hack, 1/CD3): 10 damage + Hacked 2 turns. Feedback Barrier (Defensive,
  1/CD3): +15 Block; below 50% HP heal 5. Overdrive Signal Blackout (2/CD5):
  20 damage all + Hacked 2 turns; already-Hacked enemies take +10. Extra:
  +10% Hack damage below 50% HP.
- **Scrapper's Uplink Coil (Legs, Rare, softcap 0%, Herculean augment):**
  Manual Reboot (Buff, 0/CD4): heal 10% missing HP and +15% Hack damage
  2 turns. Grapple Hack (Hack, 1/CD2): 8 damage; if target Hacked, gain
  1 Focus. Herculean Meat Sync (1/CD5): heal 15% Max HP and +20% Hack
  damage for 3 turns, only if Max HP boosted ≥20%. Extra: at ≤25% HP, +1
  draw at turn start.

### Earlier Chrome Titan / Netrunner prototype augments

These examples were supplied before the themed build sets and remain useful
cross-archetype tests:

- **Targeting HUD (Head, softcap 5%):** Target Lock (0/CD1): Marked for
  2 turns, target takes +15%. Pulse Scan (1/CD2): reveal intent and −1 Focus
  if target Chrome-based. Extra: +5% crit vs Marked. Overdrive Auto-Target
  Cascade (triggered): deal 30% max HP to all Marked enemies, remove Marked.
- **Reinforced Plating (Torso, 12%):** Brace (0/CD2): +25 Block and cleanse
  one debuff. Anchor Pulse (1/CD3): −30% incoming damage 1 turn. Extra: +10%
  base damage reduction. Overdrive Immovable Bastion (triggered): +75 Block
  and debuff immunity 1 turn.
- **Overdrive Core (Torso, 10%):** Chrome Surge (1/CD2): +1 Strength, +1
  Focus, take 5% Max HP damage. Stabilize Systems (0/CD3): remove one
  Corruption and heal 8% HP. Extra: +10% Overdrive charge rate. Overdrive
  System Break (triggered): refresh all cooldowns; +3 Strength and Focus for
  2 turns.
- **Hydraulic Fist (Arm, 8%):** Piston Punch (1/CD0): 12 physical +1
  Vulnerable. Crushing Swing (2/CD2): 22 damage, target −1 Strength. Extra:
  +10% melee damage. Overdrive Titan Smash (triggered): 50 damage, Stun all
  normal enemies 1 turn.
- **Integrated Cannon (Arm, 10%):** Chrome Burst (1/CD1): 16 AoE + Burn 2.
  Piercing Beam (2/CD3): 30 damage, ignores 50% Block. Extra: +15% ranged
  damage. Overdrive Pulse Saturation (triggered): 45 AoE + Burn 4 all.
- **Stabilizer Pistons (Leg, 6%):** Stabilize (0/CD2): +1 Dodge/+10 Block.
  Chrome Sprint (1/CD2): +2 Speed and remove one Slow. Extra: +10% Dodge at
  ≤50% HP. Overdrive Titan Step (triggered): +3 Speed/Dodge and 1 Weak all.
- **Propulsion Boosters (Leg, 6%):** Rocket Dash (1/CD0): 14 damage +
  Knockback. Ignition Jump (1/CD2): +1 Speed, Burn 1 adjacent enemies.
  Extra: immune to Root. Overdrive Jet Barrage (triggered): 30 AoE, Burn 3,
  +2 Speed.
- **Neural Spikejack (Head, Netrunner, softcap 5%):** Mind Jab (Hack, 1/CD0):
  8 psychic and Disorient (−20% accuracy) 1 turn. Ping Sweep (Hack, 1/CD2):
  reveal intent and reduce one random Hack cooldown by 1. Extra: first Hack
  each combat costs 0. Overdrive Brainstorm Surge: 20 psychic split randomly;
  +1 Focus per enemy hit.
- **Ghostlink Visor (Head, Netrunner, 5%):** Ghostlink (Hack, 1/CD1): copy
  last enemy buff to self if applicable. Echo Tap (Hack, 0/CD3): next Hack
  repeats at 50%. Extra: every third Hack refunds 1 Focus. Overdrive Neural
  Cascade: hijack active enemy buffs and redistribute randomly.
- **Ghoststep Circuits (Leg, Netrunner, 5%):** Ghoststep (Utility, 0/CD2):
  +1 Dodge and cleanse one debuff. Signal Shift (Hack, 1/CD3): next Hack
  costs 0 and cooldown −1 on use. Extra: first debuff received/combat is
  cleansed. Overdrive Phase Jump: untargetable 1 turn and +2 Focus.
- **Tracebreak Runners (Leg, Netrunner, 5%):** Burst Step (Utility, 1/CD0):
  +2 Dodge this turn. Tracebreak (Hack, 1/CD2): remove all Lock-On, apply
  Disorient −20% accuracy to one enemy. Extra: cleansing a debuff restores
  1 Focus. Overdrive Firewall Shatter: cleanse self and deal 15 psychic to
  buffed enemies.
- **Splice Injector (Arm, Netrunner, 5%):** Data Lance (Hack, 1/CD0): 10
  psychic +10% Vulnerability 1 turn. Overclock Pulse (Hack, 1/CD2): reduce
  all Hack cooldowns by 1. Extra: applying Vulnerability grants +1 Focus.
  Overdrive Data Storm: 12 psychic AoE, Disorient all, reset Hack cooldowns.
- **Hijack Gauntlet (Arm, Netrunner, 5%):** Hijack Command (Hack, 1/CD1):
  take control of one enemy buff 1 turn. Signal Spike (Attack, 0/CD2): 6
  psychic + Lock-On. Extra: Lock-On makes next Hack against target +25%.
  Overdrive Neural Override: steal all buffs from one enemy and deal 20
  psychic.
- **Ghostgrid Core (Torso, Netrunner, 8%):** Firewall Surge (Hack, 1/CD1):
  barrier equal to 20% Max HP for 1 turn. Data Sync (Hack, 1/CD3): duplicate
  last Hack used this combat. Extra: first Hack/combat applies Lock-On.
  Overdrive System Purge: cleanse all debuffs on self/allies and deal 25
  psychic to all enemies.

## 26. Floor 1 Echoes and consumables

### General Echo test pool

- **Echo of Steady Pulse (Common):** First 0-cost ability each turn grants
  +5 Block.
- **Echo of Salvage Instinct (Common):** Gain 50 Nanites every third time
  entering a non-regular combat encounter.
- **Echo of the First Dawn (Uncommon):** Combat start: heal 3 HP and gain
  1 Focus. Double-edged: if no damage taken in the fight, lose 1 HP after it.
- **Echo of Blood and Brass (Common, Meatbag-skewed):** Heal 5% Max HP every
  third consumable use; supports consumable/alchemy builds.
- **Echo of Improvised Genius (Uncommon, Meatbag-skewed):** Every fourth
  Attack or Hack against a Hacked enemy deals +10 damage or heals 5 HP (coin
  flip).
- **Echo of Stubborn Flesh (Rare, Meatbag-skewed):** Finish combat below 50%
  HP to gain +3 Max HP, once/fight.
- **Echo of Lingering Code (Common, Netrunner-skewed):** Hacked lasts +1 turn.
- **Echo of the Whisper Net (Uncommon, Netrunner-skewed):** Applying Hacked
  to 3+ enemies in one action grants 1 Focus.
- **Echo of Pulse Lag (Rare, Netrunner-skewed):** First Hack each turn deals
  5 damage to all enemies. Double-edged: gain 1 Corruption every fourth
  trigger.
- **Echo of Chrome Memory (Common, Chrome Titan-skewed):** Gain +4 Block
  whenever activating Overdrive.
- **Echo of Overheat Sparks (Uncommon, Chrome Titan-skewed):** First attack
  each turn +20% damage; if it misses or is redirected, take 2 self-damage.
- **Echo of Steel's Hunger (Rare, Chrome Titan-skewed):** Below 50% HP, gain
  1 Focus at turn start.
- **Echo of the Fractured Choir (Rare, Hybrid/Wildcard):** Using a Hack and a
  non-Hack ability in the same turn grants 1 Focus next turn.

**Floor 1 Echo rarity weighting:** Common 60%, Uncommon 30%, Rare 10%.
Expected general pool size noted for Floor 1 is 15. Floor-unique Echo sources
below are specific drop/event paths in addition to the general pool.

### Floor-unique Echo prototypes

- **Echo of Rusted Glory (Unique Boss, Concierge Revenant):** Defeat an elite
  or boss to heal 10% missing HP and gain 1 Focus. Double-edged: ending a
  fight at full HP grants 1 Corruption. Choir theme: “glory in suffering.”
- **Echo of the Forgotten Directive (Unique Mini-Boss, Parasite Choir):**
  First Hack each turn costs 1 less; every third trigger in one fight creates
  a random self-debuff “glitch.”
- **Echo of the Fleshmonger (Unique Event, Chained Choirboy follow-up or rare
  loot-body event):** Healing above max HP grants temporary HP equal to 50%
  of overheal.
- **Echo of the Shattered Gate (Unique Encounter, random encounter + combat
  event):** At combat start, first enemy to target player has 33% chance to
  become Hacked. Hook: **Fractured Hallway** offers Touch the Rift (gain Echo,
  take HP hit), Study (small lore), or Leave.
- **Echo of Overdrive's Shadow (Unique Boss, Chrome-Rotted Challenger):**
  Entering Overdrive triggers the Overdrive ability twice; Overdrive cooldowns
  increase by 1 turn.

### Consumables (Floor 1 testing pool)

| Rarity | Name | Archetype | Effect |
|---|---|---|---|
| Common | Nanite Injection Vial | Neutral | Heal 15% Max HP; remove 1 random debuff. |
| Common | Rust Grenade | Meatbag | Deal 12 to all; Hacked Chrome enemies for 1 turn. |
| Common | Stabilizing Brew | Neutral | Remove 1 debuff and gain +10 Block. |
| Common | Overcharge Capsule | Chrome Titan | Reduce all active ability cooldowns by 1; take 4 self-damage. |
| Common | Data Spike | Netrunner | Hack one enemy for 8 damage and apply Hacked. |
| Uncommon | Improvised Adrenaline | Meatbag | Gain +2 Focus now; take 5 damage at end of turn. |
| Uncommon | Nanite Cloud Dispersal | Neutral | Apply Hacked to all; each target has 25% chance to resist. |
| Uncommon | Shock Lattice Emitter | Chrome Titan/Netrunner | Deal 15 to one enemy, or double if target is Hacked. |
| Uncommon | Jury-Rigged Med Patch | Meatbag | Heal 25% Max HP; gain 1 Corruption. |
| Rare | Chrome Overclock Injector | Chrome Titan | Reset Overdrive cooldown; gain 1 temporary Corruption. |
| Rare | Ghostwave Beacon | Netrunner | Summon Drone Ally for 3 turns; deals 8 to random enemy at each turn end. |
| Rare | Alchemical Singularity | Meatbag | Refresh consumables used this combat once; single-use; gain 1 random debuff. |

**Floor 1 consumable rarity weights:** Common 60%, Uncommon 30%, Rare 10%.

## 27. Floor 1 integration cautions

1. Encounter-specific easy stats differ from the post-patch regular enemy
   baselines; preserve them as separate data rather than overwriting enemies.
2. The same compositions occur in multiple difficulty bands with different
   scripts/weights. Store encounter overrides.
3. Per-encounter depth weights, class-mix percentages, Hard category weights,
   mini-boss weights, and loot rarity percentages have different normalization
   scopes.
4. Mini-boss relative weights total 110 (Early), 145 (Mid), and 165 (Late);
   normalize by depth or revise the authored numbers.
5. Boss attachment drafts provide kits for all five boss-pool entries, but
   earlier boss AI-weight summaries conflict with their later fixed-turn and
   phase scripts; keep versions distinct and choose the authoritative design.
6. Earlier “OG 50” status note contains fewer than 50 named effects; treat
   those provided as the current known subset.
7. Boss and augment prototypes reference mechanics needing canonical
   definitions: Gospel Mark, Hacked, Vulnerable, Stagger, Disorient, Root,
   Dodge, Speed, Strength, Corruption, Focus gain timing, drone actions, intent
   previews, and what “low HP” means.
8. **Action resource and currency:** Resolved in §31: Focus is the sole action
   resource; Credits and Nanites are synonyms, with Nanites player-facing.
9. Define when cooldowns tick, how cooldown 0 works, and how triggered
   Overdrives interact with the Overdrive unlock and misfire rules.
10. Prototype augments are test examples, not a finalized catalog or balance
    commitment.

## 28. Floor 1 detailed mini-boss and boss drafts

The following kits come from attached Floor 1 design notes. Multiple versions
exist; keep them as separate balance iterations rather than merging their
numbers. Attack abbreviations such as ST (single-target), true damage, stacks,
and triggers follow the supplied drafts.

### Mini-boss kits

**Chrome Butler — tuned solo draft**

- HP 120; starts at 0 Block.
- Rustbrand Slash: 16 ST; 40% chance to apply Rustburn (4 true damage at end
  of turn for 3 turns, stacks).
- Tray Slam: 7 ST plus 2 splash to adjacent targets.
- Metallic Poise: +18 Block. If hit while Block remains, reflect 25% of
  blocked damage as true damage during that player turn.
- Serve & Guard: give 12 Block to an ally below 50% HP; if alone/no eligible
  ally, gain Crown's Favor (next Tray Slam +50%).
- Cycle Slash → Poise → Slam → Serve. Below 50% HP, 25% chance to insert extra
  Poise. If player ends two turns consecutively with ≥7 Block, advance Poise
  one turn earlier.
- Base-kit outcome estimate: 28–35% player win, 7–9 turns. Early Poise and
  reflect punish blind attacks; Rustburn pressures block-spam.

**Mold-Grown Bouncer — tuned solo draft**

- HP 130.
- Loom telegraphs Hook; next Hook +50% and gains a Block-break bonus.
- Pulverizing Hook: 18 ST (27 if Loomed); if it breaks player Block, apply
  Fleshrot (3% current HP at turn start for 3 turns, stacks).
- Hardened Plating: +16 Block (older version uses +18).
- Berserk Veins: below 50% HP, permanently +2 damage and Retaliate 15% for
  2 turns; another version triggers below 60%, grants 15% Retaliate and +25%
  damage for one turn.
- Spore Backlash: each separate hit taken in one player turn has 20% chance to
  add Fleshrot, maximum 2 per turn.
- Loop Loom → Hook → Plating. If hit for 25+ in a single turn, Plating next;
  if player blocks ≥2 turns in a row, accelerate Loom → Hook; while under 50%
  HP and Retaliate is active, prioritize Hook.
- Base-kit outcome estimate: 22–30% win, 6–8 turns. Loom creates a defend/
  attack decision and Spore Backlash punishes multi-hit attacks.

**Parasite Choir ×2 — tuned pair draft**

- HP 70 each.
- Choir A: Piercing Note 6 ST; Discord Hymn applies Echoed Trauma; Echo Screen
  grants 10 Block and a 25% chance for Thin Veil (reflect 20% of first hit
  this turn).
- Choir B: Piercing Note 6 ST; Parasite Chant 5 ST with 40% Rustburn chance
  (4 true damage at end of turn for 3 turns); same Echo Screen.
- Harmonic Surge: when one Choir remains, it gains +2 damage and uses Echo
  Screen less. Earlier iteration adds a T3 Harmonic Overload finisher:
  Choir A applies Trauma, then both Notes deal +2 each if both live.
- A opens Trauma and maintains it; B opens Chant and reapplies every third
  action/turn. Target lowest HP; if Trauma is active, prioritize damage.
  Choir A Screens every third turn or below 50%; B Screens below 50%.
- Base-kit outcome estimate: 25–33% win, 7–10 turns; pressure from Trauma
  windows and Rustburn.

**Chrome Bellhop Swarm ×3 — tuned horde draft**

- HP 30–32 each; no Block. Swarm Jab: 4 ST.
- Every second enemy turn, all living Bellhops use Coordinated Strike, each
  gaining +2 damage that swing.
- Bodyguard Redirect: each Bellhop redirects the first one or two single-
  target hits (varies by draft) to a random living Bellhop; does not affect AoE.
- Pressure Lines: if 3 alive, each Jab +1 damage. Tip Jar: when one dies,
  survivors permanently gain +2 damage.
- Loop group Jab → Coordinated Strike. If player blocks ≥2 turns consecutively,
  trigger an immediate Coordinated Strike. If only one remains, it Jabs each
  turn, +1 damage per missing ally (max +2).
- Base-kit outcome estimate: 20–30% win, 5–7 turns; target priority and
  clearing numbers before the coordinated spike are key.

**Worship Hall Matron — solo and pair variants**

- Solo draft: HP 115, Sanctify +14 Block. Gospel Brand applies Gospel Marked
  (player deals +25% and takes +30%, 2 turns). Benediction Lash: 10 ST and
  heals Matron for 25% damage dealt if player marked. Litany of Pain: 6 AoE.
  Vox of the Crown: each turn player ends debuffed, Matron +1 damage (max +6;
  lose 2 stacks if Matron takes 20+ damage in a turn). Opens Brand; while
  player marked, Lash; otherwise Sanctify below 50% HP or reapply Brand.
  Litany every fourth turn. Estimate: 30–38% win, 6–8 turns.
- Pair draft: Matron HP 150, Attendant HP 60. Matron Gospel Lash 6 ST +
  Gospel Marked; Hymn of the Faithful grants Sanctified Strike (heal 3 on hit
  vs marked target, 2 turns); Sanctified Guard +18 Block. Attendant Servile
  Strike 4; Assist gives Matron's next attack +2 (non-stacking, CD3).
  Matron cycles Lash → Guard → Hymn; Attendant Assists every third turn or
  after Mark.

**Concierge Herald — optional mini-elite**

- HP 55; Opening Edict applies Gospel Mark; Bulwark grants 12 Block and +2
  ally damage for 1 turn; Sermon Lash 9 ST, +3 and extends Mark by 1 turn
  (max 3) if target is marked; Cantor's Call grants 10 Block to an ally below
  50%, otherwise uses Lash.
- T1 Edict, T2 Bulwark, then Lash/Bulwark; alone, uses Lash more often (2:1).
- Separate from the regular-enemy Herald test profile; use only if including
  the optional fifth mini-elite.

**Choir Fleshmonger — special mini-boss**

- Rust Choir mutated faction. HP 210, approximately 15% above other Floor 1
  mini-bosses. Starts with Hymnal Resonance/Hymn.
- Hymn: if it took damage in a round, heals 5 at its turn end and gains Rust
  Insight (+10% damage/stack, max 3).
- Choir Connection: first time player falls below 50% HP, applies Hacked and
  Rustrot 2 (Rustrot is DoT; exact canonical rules TBD).
- Four-turn cycle:
  1. **Chant of Opening:** +10 Block, +1 Rust Insight; 25% chance summon
     Choir Husk (25 HP).
  2. **Hymn of Rending:** 18 damage, apply Rustrot (4/turn for 2 turns) and
     Hacked if absent; if already Hacked, apply Weaken 1 turn.
  3. **Embrace of Flesh:** 10 damage to player and allied summons; heal equal
     to total damage; if heals ≥15, +1 Rust Insight.
  4. **Rust Revelation:** 24 damage, +50% if player below 50% HP; +10 Block
     and restore Hymnal Resonance if dispelled.
- Choir Husk: 25 HP, 8 damage Rustbite Lunge (+4 vs Hacked); tethered to boss,
  per-turn heals boss 4 while it lives. Chant of Echoes heals boss 5 and gives
  +1 Rust Insight (max 3), while Husk loses 3 HP. Husks ignore player buffs/
  debuffs and perish at end of turn when Fleshmonger dies.

### Boss kits — later detailed draft

**Matron of the Crown (HP 240)**

- Royal Decree applies Gospel Mark (player deals +25% / takes +30%, 2 turns).
- Coronation Lash: 3 hits (6/6/8); final hit +6 if target marked.
- Royal Aegis: +18 Block; while Block remains, each hit reflects 4 true damage.
- Summon Acolytes: spawn one 40-HP Crown Acolyte at 70% and again at 40% HP.
  Acolyte deals 5, can heal 6 (Devotion Heal), or grant Queen 10 Block
  (Shield the Queen).
- T1 Decree, T2 Aegis, T3 Lash, then loop. Reapply Mark if it falls off.
  Enrage ≤20%: Lash becomes four hits (6/6/8/10); Aegis reflect +2 true/hit.
- This is a later alternative to the earlier five-move AI-weight draft in
  §23; its Benediction/Assist loop is not identical.

**Choir of Parasites — Conductor + two Nodes**

- Conductor HP 160; two Parasite Nodes HP 80 each. All must be defeated.
- Conductor: Dissonant Edict applies Echoed Trauma; Parasite Wave 10 AoE (+5
  to player if Trauma active); Baton Guard +12 Block and Nodes +6; Cacophony
  (CD3) deals 2×8 AoE and applies Rustburn if either hit lands.
- Each Node: Piercing Note 6 ST; Parasite Chant 5 ST +40% Rustburn; Echo
  Screen +10 Block and first-hit 20% true reflect.
- T1 Conductor Edict, Nodes Screen/Chant 50/50. Conductor alternates Wave and
  Guard, Cacophony every fourth action. One Node's death gives survivor
  Harmonic Surge (+2 damage, less Screen); both dead makes Conductor use Wave
  every turn until Cacophony ready.
- Different from the earlier three-drone HP60 / Viral Hymn rotation draft in
  §23.

**The Concierge Revenant (HP 260)**

- Adds: two Chrome Bellhops (28 HP, 5 damage), each respawns once at 50% boss
  HP.
- Check-In, Please: 10 ST and steal up to 6 player Block before damage.
  Room Charge: 8 ST +2% current HP true damage. Front-Desk Bulwark: +12 Block;
  if struck that round, apply Echoed Trauma to attacker for 1 turn. Bell
  Summon creates one Bellhop.
- T1 Bulwark, T2 Check-In, T3 Room Charge, loop. At ≤50%, if both adds dead,
  summon immediately. If player Blocked last turn, prefer Room Charge. Enrage
  ≤20%: Check-In steals up to 10 Block; Room Charge true component becomes
  3% current HP.
- Alternative to the earlier Mimicry / Veiled Strike / Phase Shift / Reality
  Twist draft in §23.

**Chrome-Rotted Challenger (HP 200)**

- Spasm Guard grants 10 Block and reflects 3 true damage per hit that turn.
- Flurry: 4×4 ST; if any hit breaks Block, apply Fleshrot (3% current HP,
  3 turns). Haymaker 14 ST (+6 vs Fleshrot). Violent Whiplash (CD3): 2×9 ST,
  +3 each if target has any DoT.
- Alternate Flurry → Guard → Haymaker; use Whiplash when available. If player
  ended last turn with Block >0, prefer Flurry. At ≤50%, Flurry becomes 5×4;
  at ≤20%, use Haymaker + Whiplash back-to-back if ready, otherwise Haymaker.

**Mycelial Host (HP 195)**

- Base damage 11; Fungal Carapace +16 Block and 20% status resistance 1 turn.
- Starts with one Mycelial Node. Spore Bloom every 2 turns: if fewer than two
  Nodes, spawn one (max 2); otherwise apply Viral Bloom 1 to player.
- Infectious Slam: 11 ST + Viral Bloom (3% current HP; 33% spread chance per
  tick if adjacent allies exist). Absorb Growth consumes all Nodes, heals 12
  per Node and +4 damage per Node for 2 turns. Node: 20 HP/6 damage; if two
  exist, synchronous attacks each +50%. On Node death, 50% Host +6 Block,
  50% Host +2 damage for 2 turns.
- T1 Slam, T2 Carapace. Thereafter if 2 Nodes, Absorb; otherwise Slam →
  Carapace and Absorb if ≥1 Node and Host ≤70% HP or if 2 Nodes. At ≤33% HP
  with no Block, 50% Carapace chance. Turn 9 anti-stall: Absorb if any Node.

## 29. Floor 1 event blueprints from attached notes

These are choice/event implementation seeds. Most exact resource amounts,
check thresholds, and flag outcomes remain to be designed.

- **Welcome Desk (Vega, resource/risk, false-lore hooks 7-1/7-2):** Flickering
  concierge and three terminals. Access Guest Terminal costs currency for a
  random Echo, augment, or healing, with 10% minor security-drone fight chance.
  Hack Maintenance Terminal for map info/buff on success or shock damage on
  failure; Ignore is safe.
- **Resort Bathhouse (environment/Vega biotech, false-lore 9-1/10-1):** Bathe
  to heal/remove debuff but gain temporary Corruption/Chrome Rot; Analyze for
  lore and possible Nanite-Infused Water; Leave.
- **Choir in the Hall (Rust Choir, optional combat, false-lore 13-2):** Listen
  for minor Corruption or next-combat Rust Insight; interrupt to fight weak
  acolytes; back away safely but risk delayed ambush.
- **Relief Kiosk (Vega trade/buff/trap, false-lore 8-1/8-2):** Pay currency
  for random positive augment plus hidden Chrome Rot; tamper via skill check
  for consumables/currency or shock trap; decline.
- **Wandering Scavver (survivor trade/combat, false-lore 8-2):** Trade for
  random consumables/augments/small Echoes; attack for cart loot and slight
  Corruption; ignore.
- **The Leaking Wall (hazard/puzzle, infrastructure lore):** Stabilize via
  check for resource/relic or explosion/HP loss/debuff; harvest Nanites for
  consumable/buff with Corruption risk; move on.
- **Mind-Broker (social/risk):** Offer relics for a backstory memory, Focus,
  or ability upgrade; refusal makes him vanish. Questions about Kronos/
  Pantheon may reveal cryptic neural-rewriting/Choir lore.
- **Security Checkpoint (tactical/social):** Bluff or solve a logic/hack
  challenge for clean passage and loot; alternatively fight coordinated
  security drones.
- **The Choir's Ashes (investigation/optional combat):** Scavengers loot
  relics while Choir converts remain beneath ash. Approach quietly, parley, or
  risk a three-way fight whose setup depends on choice.
- **Rust Lottery Stall (gamble):** Pay resources or Focus to “Spin for a
  Dream”; receive buffs/relics or Glitches/debuffs; some outcomes summon
  mini-boss/Choir ambush.
- **Chrome Peddler (shop-like risk):** Buy augment for currency plus
  Corruption; accept a random free positive/negative sample with surprise-
  combat chance; or refuse.
- **The Chained Choirboy (psychological/lore):** Listen for minor HP/Focus
  damage and lore fragment/minor Echo; free to fight malfunctioning Choir
  remnants for Echo/consumable; silence for small currency or temporary buff.
  Interacting in any way except Ignore can unlock the later Fleshmonger's
  Hymn event.
- **Experimental Vending Unit (gamble/hazard):** Insert currency for random
  consumable/small Echo (20% malfunction: minor fight/HP loss); hack for
  high-tier consumable/Rare augment or turret; smash for modest reward plus
  negative status.
- **Scrap Apostles (combat/faction):** Fight scavenger-fanatics fused to a
  generator; win may grant Echo, consumables, or augment. Ignore, or disable
  generator for large reward at HP/special-resource cost.
- **Executive Memo Room (lore/risk):** Download data for Focus damage and
  powerful lore Echo/blueprint relic; decode for map/buff or elite security
  drone; leave.
- **Nanite Dispensary Overflow (resource/risk):** Collect gel for healing/
  buff plus Corruption; repair for two consumables or turret; walk away.
- **Executive Recruitment Hologram (psychological/trade):** Sign contract for
  permanent HP or Focus loss and Rare augment/relic; forge signature for loot
  or elite; decline.
- **Server Cathedral (puzzle/lore/buff):** Sync to rhythmic server pulse for
  buff/map info or mental damage; rip core for currency/consumable plus
  Corruption/combat; ignore.
- **Rust Graffiti Ritual:** Read aloud for Corruption and buff/Choir Echo;
  deface to remove debuff but increase Choir hostility; ignore.
- **The Rustling Tent:** Eavesdrop for lore/consumable; enter to fight
  acolytes for Echo/currency; sneak past.
- **The Singing Mask:** Wear for Rare relic with strong buff and attached
  Corruption; destroy to remove debuff but lose random consumable; leave.
- **Rust Choir Procession:** Join for temporary Corruption plus buff/Echo;
  disrupt by check for currency or fight; hide.
- **Broken Caravan Wagon:** Help by check for consumables/currency or HP loss;
  rob for moderate combat/good loot; move on.
- **Caravan Storyteller:** Listen at Focus/time cost for lore Echo/minor buff;
  pay currency for consumable/Echo; leave.
- **Wasteland Toll Booth:** Pay currency, negotiate with check, or refuse and
  fight for loot.
- **Chrome Scavver Duel:** Fight a mini-elite for solid reward, buy them off
  for currency/minor loot, or retreat.
- **Shifting Corridor:** Follow echoes via check for lore/buff or HP loss;
  force through for damage plus consumable; wait for safe passage or
  Corruption.
- **Temporal Rift:** Study for lore/buff at Focus cost; reach in for relic/
  boon plus Corruption/debuff; avoid.
- **Echoing Elevator:** Ride for map/currency with malfunction HP risk; break
  open for consumables and Corruption; leave.
- **Maintenance Bot:** Help complete task via puzzle/check for reward or minor
  combat; destroy for currency/Corruption; ignore.
- **Hollow Climber:** Salvage implants for Rare augment/relic with 40%
  reanimation mini-elite chance; careful extraction check safely rewards or
  awakens a weakened enemy; leave undisturbed.
- **Rusted Wheel of Wagers:** Pay currency/Focus to gamble for Rare augment/
  relic, temporary buff, debuff/Corruption, or Choir fight. Inspect for odds/
  trap disabling/currency; walk away.
- **Rust Gambler:** Wager an item/consumable for exceptional relic/augment,
  equal-value trade, loss plus Corruption, or betrayal fight using the item.
  Cheating check can fail into combat; refuse.
- **Echo of Tomorrow:** Reach into future-floor vision for key/lore unlocking
  later event, shortcut, secret shop, bonus encounter, or alternate boss
  intro, at HP/Corruption cost; stabilize for currency/buff or anomaly fight;
  step back.
- **Fractured Hallway:** Touch Rift: lose 10% Max HP as true damage and gain
  Echo of the Shattered Gate. Study: success grants +1 Focus and +3 Block at
  start of next two combats; failure −1 Focus in next two fights. Leave.
- **The Fleshmonger's Hymn:** Later same-floor event if player interacted with
  Chained Choirboy (listened, freed, or silenced). Approach: permanently lose
  10% Max HP and gain Echo of the Fleshmonger; Sever Connection: fight Choir
  Fleshmonger, win Echo plus currency/consumables; back away increases Choir
  hostility for the floor.

Additional attached event notes use early lore-book identifiers called
“False Lore”; reconcile these with the still-undecided True/False Lore
framework before content authoring. Do not assume a three-perspective schema.

## 30. Playable Floor 1 vertical slice (Godot prototype)

The workspace now boots to a generated map for the active Floor 1. Only the
current floor is generated; later floors are not pre-generated. This is a test
implementation of the design, not a resolution of the open questions or a
claim that the full catalog is implemented.

### Run path and rewards

- Floor 1 uses a six-row branching graph: Luxury Checkpoint start; two
  crossroads choices; three depth choices; two late-route choices; a guaranteed
  Rest node; then the selected boss. The generator selects among predefined
  path templates, connections only advance to the next row, and only connected
  nodes can be entered. The map is drawn bottom-to-top to show the climb, and
  random encounter nodes display `?` instead of revealing their event name.
  Routes contain Combat, Elite, Event, and Shop nodes before the Rest and Boss;
  no two Rest nodes may be adjacent.
- Floor 1 node rows and boss selection are generated once when entering that
  floor. The graph generator is isolated in `scripts/floor_map_generator.gd`;
  future floors should be generated only when they become active.
- Boss selection uses the §23 pool weights. Each boss has a playable intent
  loop; the Matron, Parasite Choir, Concierge Revenant, Chrome-Rotted
  Challenger, and Mycelial Host use the later kits as a starting point.
- Each victory opens a reward-container screen with a Nanite payout, a
  Nanite Vial offering three random augment choices (claim one), and sometimes
  a consumable. Choosing an augment and claiming the container awards all its
  contents. Slice payouts are 25 Nanites for regular combat, 50 for elites, and
  100 for the boss; consumable drop chances are 35%, 60%, and 100% respectively.
  These are prototype values, not canonical economy balance. Augments equip
  immediately in their named slot and replace an existing augment in that
  slot. Consumables use the Floor 1 60/30/10 Common/Uncommon/Rare weights.
  Consumables can be used once per player turn without Focus.
- At Rest, heal 30% of Max HP or tune one equipped, untuned augment. Tuning
  raises each positive active-ability power by 20% (at least +1) for the
  current run. The slice uses this explicit implementation value because the
  source material specifies a Tune choice but not its numeric effect.
- Run points convert to Metal XP on victory or defeat and are saved in
  `user://profile.cfg`. No run currency or equipment persists between runs.
- The art is procedural pixel-style geometry; no final sprites or animation
  assets are included.
- Open the project in Godot and press F5 to play. Choose connected nodes on the
  map. In combat, click an enemy card to target it, click action/augment/item
  buttons to act, and click End Turn to resolve forecast intents. Claim each
  reward container before continuing; at Rest, choose Rest or tune an untuned
  augment before returning to the map.
- Run the automated traversal smoke test with
  `godot --headless --path . --script res://tests/floor_one_smoke.gd`.
- Combat content is stored as nested GDScript Dictionary containers: player
  actions, augment abilities, and consumables contain effect arrays. The effect
  executor dispatches to focused damage, stat, status, and utility handlers;
  action, consumable, passive, condition, and content-validation logic are
  separate modules. Enemy intent selection and execution are also split into
  dedicated handlers. Enemy intent patterns are currently code-authored by
  enemy type, so fully editable enemy-AI data remains future work.
- The combat menu is grouped into Abilities, Consumables, Hacks, and
  Overdrive/Herculean categories, with each category showing its own action
  submenu. Enemy healing is restricted to living targets; zero-HP corpses remain
  available for future resurrection effects but ordinary healing cannot revive
  them. Nanites are run-local and reset at the start of a new run.
- Inventory is a run-local container showing equipped and unequipped augments,
  carried consumables, and Echoes. It shows current/max HP, the equipped
  softcap's Max HP cost, Max HP bonuses, and Overdrive/Herculean unlock status.
  Replaced augments are retained in unequipped inventory. Reward augment and
  ability hover text describes effects and the item currently equipped in the
  corresponding slot.
- Clarity Under Fire grants one Focus immediately and one at the next turn
  start when the player is below 50% HP. Meat Hook checks the target's HP before
  its damage resolves and heals its caster by 4 only when that target began the
  ability below 50% HP. Herculean abilities are data-driven and require the
  authored Max HP increase threshold; they remain visible but disabled while
  locked. The Blackout Harness provides a data-driven Overdrive ability, gated
  by the 60% cumulative softcap rule.
- Run the content/effect architecture smoke test with
  `godot --headless --path . --script res://tests/combat_architecture_smoke.gd`.

### Implemented combat baseline and deliberate prototype rules

- Start with 100 HP, 3/3 Focus, Punch (5 damage, 1 Focus), Block (7 Block,
  1 Focus), a temporary Scrap Hack action (3 damage and Hacked, 1 Focus), a
  Nanite Injection Vial, and the Jury-Rigged Exo-Arm.
- Focus refreshes to 3 at each turn start; temporary Focus can exceed that
  cap. Enemy intents are previewed before End Turn and resolve in list order.
- Augment actives use their authored Focus costs and cooldowns. Cooldowns tick
  down at the start of the player's next turn. All currently implemented
  effects are explicitly represented in the Floor 1 test data.
- The Meatbag-friendly Chrome Overclock Injector prototype resets active
  ability cooldowns because this slice has no Overdrive-equipped augment; this
  is a temporary stand-in for its OD-only source effect.
- The base Hack move is not defined in the design source; Scrap Hack's
  provisional damage/duration are local slice values, not canonical balance.
- This starting build follows the Meatbag rule and does not begin with an
  Overdrive ability. The Blackout Harness Overdrive is available only after
  reaching 60% equipped softcap; at that point the softcap also imposes its
  corresponding Max HP cost. Full Overdrive misfire and softcap-based damage
  scaling remain future work.
- The current Floor 1 test pool and four implemented limb slots cannot reach
  either the 60% Overdrive threshold or the +20% Max HP Herculean threshold
  through normal play. The unlock checks are implemented and testable, but
  additional augment/slot progression is required to make those abilities
  obtainable in a run.
- Damage reduction, Hacked duration, debuffs, and selected boss moves use
  simplified rules where the bible has no canonical timing/stack definition.
  Treat these as testable scaffolding and reconcile them before wider content
  production.
- The slice includes a first-pass branching Floor 1 map, simple event choices,
  and a basic Nanite trader. It excludes later-floor generation, the full
  augment/Echo catalog, the complete seven-slot-plus-three-extra loadout, and
  the full status catalog.

## 31. Design decisions from conflict-review quiz

These are the player's current working decisions. They supersede conflicting
options elsewhere in the reference; unresolved details are listed separately.

### Confirmed direction

- **Run modes:** Standard runs have five floors: Floor 1, three weighted
  selections, and Floor 15. Full Climb visits all 15 floors.
- **Floor mapping:** The latest floor catalog is canonical; remap or archive
  older floor primers.
- **Difficulty:** Use the 70/30 floor-number/run-slot blend as the base formula;
  do not stack the older banded or alpha/beta curves.
- **Overdrive:** Unlock at 60% cumulative augment/system softcap, not at a
  current-HP threshold. Each full +3 percentage points adds +12% Overdrive
  damage and +7 percentage points of misfire; scaling is linear and currently
  uncapped.
- **Slots:** Seven fixed slots (Head, Torso, left/right Arm, left/right Leg,
  Core) plus three extra slots; 10 total at run start.
- **Loot bonuses:** Add rarity bonuses as percentage points, then normalize
  each final reward distribution to 100%.
- **Hera:** When triggered, Hera replaces the selected boss for that floor and
  appears in its boss-map slot; the proposed trigger chance/timing remains
  provisional.
- **Boss augment rarity:** Boss augments may be Divine when the loot roll
  allows.
- **Tuning:** Players choose which augment to tune. Random pre-upgrades may
  apply to initial drops only, not the Tune choice.
- **Action resource:** Focus is the sole action resource. Normalize authored
  Energy, Mana, and AP examples to Focus.
- **Currency:** Credits and Nanites are synonyms; use **Nanites** as the
  player-facing name and treat Credits as an older synonym. No between-run
  currency is added.
- **Status catalog:** Treat the supplied list as partial; define missing
  effects and select one canonical rule per status before implementation.
- **Lore collection:** Items collected across runs unlock lore entries. Some
  entries are verified True Lore; most may be inaccurate False Lore due to
  narrator bias. Completing True Lore sets adds variation to the Tower.
  Let players infer which entries are accurate through collection and Tower
  changes; do not label entries True/False. The previous three-perspective
  framework is not confirmed as the collection structure.
- **Move scope:** Each augment has 2–3 regular moves plus a separate Overdrive
  move.
- **Meatbag softcap:** Pure Meatbag augments contribute 0% softcap; some
  cross-archetype Meatbag augments (including Meatbag × Chrome Titan or
  Meatbag × Netrunner) may contribute a softcap percentage.
- **Boss roster:** Retain the five weighted pool entries. Treat
  Chrome-Rotted Challenger as the Chrome-Rot Contestant and Mycelial Host as
  Mycelial Host & Nodes. Keep Failed Ascendant and Rotting Siren as alternate
  concepts, not current pool entries.
- **Mini-boss roster:** Keep the five weighted mini-bosses. Concierge Herald
  is an optional elite; Choir Fleshmonger remains event-gated.
- **Boss access and testing:** Bosses may be gated by an interaction/event
  within a run, a permanent unlock earned from an earlier interaction, or lore
  progression. Define the condition per boss. Temporarily restricting the
  boss pool (even to one boss) for repeated balance testing is a developer
  test setup, not player-facing progression.
- **Workspace status:** §11 now describes the playable Godot prototype rather
  than the original starter project.

### Remaining implementation detail

- Specify individual boss access conditions and how an interaction that
  occurs after floor generation updates the selected boss and map preview.
- Confirm the proposed Hera trigger chance/timing in §15.
