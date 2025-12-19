# Kaguya Boss Mechanism Issues (2025-12-19)

## Status: Unresolved

Despite recent attempts to fix the Kaguya Boss behavior in `Enemy.gd`, the following issues persist:

1.  **Movement**: Kaguya continues to move towards the player instead of remaining static/teleporting.
    *   *Attempted Fix*: Added checks for `enemy_name == "boss3"`, `boss_title == "蓬莱山辉夜"`, and `boss_type == KAGUYA` in `_physics_process` to force `is_static_boss = true` and `current_speed = 0.0`.
    *   *Suspected Cause*: The `enemy_data` passed during the Wave Spawning process (from `WaveConfig`) might be a simplified object/dictionary that doesn't strictly match the expected properties, or the `enemy_type` is not correctly set to `BOSS` (2) during the specific wave instantiation.

2.  **Attacks**: Kaguya is not firing her specific bullet hell patterns.
    *   *Attempted Fix*: Added robust property access for `attack_patterns` (using `.get()`) and a fallback injection of `["impossible_bullet_hell", "time_stop"]` if the pattern list is empty and the enemy is identified as Kaguya.
    *   *Suspected Cause*: Similar to movement, if the identity check fails, the fallback doesn't trigger. Alternatively, the timer logic in `_process_boss_attacks` might be getting reset or blocked by other states.

## Next Steps for Debugging
- Log the exact content of `enemy_data` and `enemy_type` when Kaguya spawns.
- Verify how `WaveManager` or `EnemySpawner` constructs the Kaguya entity vs how `RoomManager` spawns her (Room 10 vs Time-based wave).
