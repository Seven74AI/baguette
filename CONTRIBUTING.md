# Contributing to BAGUETTE

Welcome soldier. This document defines the coding conventions for the BAGUETTE project — an FPS rogue-like set in Paris 2087 where you defend the last bakery in France. Follow these rules or face the gluten-free horde.

---

## 1. GDScript Style Guide

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Classes / Nodes | PascalCase | `PlayerMovement`, `EnemyAI` |
| Functions | snake_case | `get_health()`, `apply_damage()` |
| Variables | snake_case | `current_speed`, `target_position` |
| Constants | CONSTANT_CASE | `MAX_ENEMIES`, `DEFAULT_SEED` |
| Private members | `_underscore` prefix | `_internal_state`, `_cooldown_timer` |
| Signals | snake_case, past tense | `health_depleted`, `weapon_fired` |
| Enums | PascalCase | `enum WeaponType { BAGUETTE, CROISSANT, PAIN_CHOCOLAT }` |

### Code Layout

- Indentation: **1 tab** (Godot default).
- Max line length: **120 characters**.
- One statement per line.
- Blank line between top-level functions and class declarations.
- Group members in this order: signals → enums → constants → exported vars → public vars → private vars → onready vars → built-in callbacks → public methods → private methods.

### Comments

- Document _why_, not _what_. The code tells _what_.
- Use `##` for doc comments that appear in the Godot editor.
- Use `#` for implementation notes and inline comments.

```gdscript
## Applies damage to this entity, triggering hit reactions and death if health reaches zero.
## [param amount] Raw damage before resistance calculation.
func apply_damage(amount: float) -> void:
    # Mitigation is calculated per damage type — see design doc §4.2
    var mitigated := amount * _damage_resistance
    _health -= mitigated
```

### Typing

- Always annotate function parameters and return types.
- Use static types on variables when the type is not obvious from initialization.

```gdscript
func get_health() -> float:
    return _health

var speed: float = 300.0  # Type is obvious from literal, annotation optional
var enemy_list: Array[Enemy] = []  # Type not obvious, annotation required
```

---

## 2. File Structure Rules

### One Class Per File

Every `.gd` file contains exactly one class. The file name matches the class name in PascalCase.

| File | Class |
|------|-------|
| `player_movement.gd` | `PlayerMovement` |
| `health_component.gd` | `HealthComponent` |
| `weapon_manager.gd` | `WeaponManager` |

### Scene and Script Co-location

A scene (`.tscn`) and its primary script (`.gd`) live in the same directory.

```
scenes/player/
├── player.tscn
├── player.gd
├── player_movement.gd
└── player_camera.gd
```

### Tests Mirror Source Structure

Tests live under `tests/` and mirror the source layout one-to-one.

```
scripts/components/health_component.gd
tests/unit/components/test_health_component.gd

scripts/systems/weapon_manager.gd
tests/unit/systems/test_weapon_manager.gd

scripts/enemies/enemy_spawner.gd
tests/integration/enemies/test_enemy_spawner.gd
```

Test files are prefixed with `test_`.

---

## 3. TDD Requirement

**All gameplay code must be test-driven.** No exceptions.

### Red-Green-Refactor Cycle

1. **RED** — Write a failing GUT test that describes the behavior you want.
2. **GREEN** — Write the minimum code to make the test pass. No more.
3. **REFACTOR** — Clean up with all tests green. Remove duplication, improve names.

### Pre-Commit Gate

- Full GUT suite must pass: `godot4 --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests`
- Godot headless validation must pass: `godot4 --headless --quit 2>&1` (exit 0, zero errors)
- Tests added in the same commit as the implementation — never commit untested code.

### Test Conventions

- One test file per source file.
- Descriptive test names using `should_` prefix: `test_should_clamp_health_to_max()`.
- Given/When/Then structure inside each test.

```gdscript
func test_should_not_heal_above_max() -> void:
    # Given
    var hp: HealthComponent = auto_free(HealthComponent.new())
    hp.max_health = 100.0
    hp.current_health = 90.0

    # When
    hp.heal(30.0)

    # Then
    assert_eq(hp.current_health, 100.0, "health clamped to max")
```

---

## 4. Git Workflow

### Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, deployable. Never pushed directly. |
| `feature/phase-X-task-name` | Feature work branched from `main`. |

Branch naming: `feature/phase-0-5-coding-conventions`, `feature/phase-1-player-movement`, etc.

### Commits

- **Language:** English.
- **Tense:** Present imperative (`Add health regen`, not `Added` or `Adds`).
- **Scope:** One logical change per commit.
- **Format:** `<action> <area>: <summary>`

Examples:
```
Add health_component: clamp healing to max_health
Fix player_movement: air control not applied on slopes
Refactor weapon_manager: extract fire logic to WeaponBase
```

### Pull Request Workflow

1. Create a feature branch from `main`.
2. Implement with TDD — tests pass, Godot validates clean.
3. Push to `Seven74AI/baguette` (origin).
4. Open a PR targeting `main`.
5. Request review. Address all feedback.
6. Squash-merge into `main` after approval.

**No direct pushes to `main`.** The branch protection is enforced.

### Remote

The canonical remote is `origin` pointing to `https://github.com/Seven74AI/baguette.git`.

```bash
git remote -v
# origin  https://github.com/Seven74AI/baguette.git (fetch)
# origin  https://github.com/Seven74AI/baguette.git (push)
```

---

## 5. Godot Validation

### Pre-Commit Checklist

Both checks must pass before any commit:

**Check 1 — Headless validation (parse + import errors)**
```bash
/usr/local/bin/godot4 --headless --quit 2>&1
```
Must exit 0 with **zero** `ERROR:` or `SCRIPT ERROR:` lines in output.

**Check 2 — GUT test suite**
```bash
/usr/local/bin/godot4 --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests
```
All tests must pass. Zero failures, zero errors.

### CI

CI runs on every PR to `main`. It executes both checks. A failing CI blocks merge.

---

## 6. Architecture Mandate

### Composition Over Inheritance

BAGUETTE uses **component-based architecture**. Nodes are assembled from small, reusable components rather than extended through deep class hierarchies.

### Component Pattern

```gdscript
# ✅ DO — Composition
extends CharacterBody3D

@onready var health: HealthComponent = $HealthComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var attack: AttackComponent = $AttackComponent
@onready var loot: LootDropComponent = $LootDropComponent
```

### Forbidden Inheritance Pyramids

```gdscript
# ❌ DON'T — Deep inheritance
# Enemy → RangedEnemy → HitscanRangedEnemy → TouristeZombie
# This becomes unmaintainable after 3 levels.
```

Prefer components over inherited behavior. A `FlyingBehavior` component on an `Enemy` is better than a `FlyingEnemy` subclass.

### Autoloads

Autoloads are reserved for **true singletons** — systems where more than one instance would break the game:

| Autoload | Purpose |
|----------|---------|
| `GameState` | Current game mode, round number, persistent stats |
| `AudioManager` | Music and SFX playback, volume control |
| `WeaponRegistry` | Weapon data lookup by ID |

Autoloads must not hold transient scene state. Scene-local state belongs to the scene's root node or a local manager.

### Signal Communication

Components communicate via **signals**, not direct method calls across scene boundaries.

```gdscript
# ✅ DO — Signal
health.health_depleted.connect(_on_enemy_died)

# ❌ DON'T — Direct cross-scene call
get_node("/root/Level/UI/ScoreLabel").update_score(100)
```

---

## 7. Asset Naming Conventions

### Weapons

```
weapon_baguette_pistol.tscn
weapon_baguette_rifle.tscn
weapon_croissant_shotgun.tscn
weapon_pain_chocolat_launcher.tscn
weapon_four_sacre.tscn         # Ultimate weapon
```

### Enemies

```
enemy_tourist_zombie.tscn
enemy_le_touriste_rage.tscn
enemy_hipster_sans_gluten.tscn
enemy_critique_gastronomique.tscn
enemy_pigeon_mutant.tscn
boss_food_truck.tscn
```

### Levels

```
level_zone1_street_bsp.tscn
level_zone1_comptoir_bsp.tscn
level_zone1_farine_bsp.tscn
level_boss_foodtruck_arena.tscn
level_hub_boulangerie.tscn
```

### UI

```
ui_hud.tscn
ui_pause_menu.tscn
ui_weapon_select.tscn
ui_game_over.tscn
ui_main_menu.tscn
```

### General Pattern

`<category>_<specific_name>.tscn`

- Lowercase.
- Underscores between words.
- No abbreviations unless universally understood (`ui`, `hud`, `sfx`, `vfx`).
- Scene and its script share the same base name: `player.tscn` / `player.gd`.

### Resources

```
weapon_baguette_pistol.tres
enemy_tourist_zombie.tres
modifier_double_damage.tres
loot_croissant_heal.tres
recipe_baguette_tradition.tres
```

---

## Quick Reference

```bash
# Before committing
godot4 --headless --quit 2>&1                          # Must exit 0, zero errors
godot4 --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests  # All tests pass

# Branch and commit
git checkout -b feature/phase-X-task-name
git add -A
git commit -m "Add area: brief description"
git push origin feature/phase-X-task-name
```

---

*Dernière boulangerie de France. Dernière chance pour le pain. Écris du code propre ou meurs en essayant.*
