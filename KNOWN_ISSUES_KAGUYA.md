# Kaguya Boss Mechanism Issues (2025-12-19)

## Status: Resolved

## Previous Issues
1.  **Movement**: Kaguya continued to move towards the player instead of remaining static/teleporting.
2.  **Attacks**: Kaguya was not firing her specific bullet hell patterns.

## Root Cause Analysis
1.  **Incorrect Initialization Path**: `EnemySpawner.gd` was calling the generic `setup()` method for bosses instead of the specialized `setup_as_boss()` method. This bypassed critical initialization steps such as:
    *   Setting `enemy_type` explicitly to `BOSS`.
    *   Resetting `current_attack_index`.
    *   Emitting `boss_spawned` signals for UI.
    *   Initializing the `boss_attack_timer`.

2.  **Fragile Property Access**: In `Enemy.gd`, the check `if "boss_type" in enemy_data` was failing on the `BossConfig` class instance, causing the static movement logic to be skipped even if the data was present.

## Applied Fixes (2025-12-19)
1.  **EnemySpawner.gd**: Updated `spawn_boss` to check for and call `boss.setup_as_boss(boss_config)`.
2.  **Enemy.gd**: Updated `_physics_process` to use a robust property check:
    ```gdscript
    if enemy_data.get("boss_type") != null: ...
    ```

## Verification
- Kaguya should now spawn with the correct Boss initialization.
- She should remain static (with teleportation) due to the fixed logic in `_physics_process`.
- She should cycle through her attack patterns ("impossible_bullet_hell", "time_stop") as `setup_as_boss` now correctly prepares the attack state.