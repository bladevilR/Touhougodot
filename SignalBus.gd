extends Node

# SignalBus - 全局信号总线
# 这是整个游戏的"电话局"，所有节点只跟它说话，不互相找

# --- 战斗相关信号 ---
@warning_ignore("unused_signal")  # Signal is emitted from other classes (HealthComponent, Player, etc.)
signal player_health_changed(current_hp, max_hp)
@warning_ignore("unused_signal")
signal player_died()
@warning_ignore("unused_signal")
signal player_leveled_up(new_level: int)
@warning_ignore("unused_signal")
signal player_dashed()
@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node2D, xp_value: int, position: Vector2) # 怪物死了，通知掉落系统和经验系统
@warning_ignore("unused_signal")
signal xp_gained(current_xp, max_xp, level)
@warning_ignore("unused_signal")
signal xp_pickup(xp_value) # 拾取经验球

# --- 系统相关信号 ---
@warning_ignore("unused_signal")
signal game_started()
@warning_ignore("unused_signal")
signal game_paused()
@warning_ignore("unused_signal")
signal game_resumed()
@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal level_up(new_level)
@warning_ignore("unused_signal")
signal scene_changed(scene_name: String)

# --- 武器相关信号 ---
@warning_ignore("unused_signal")
signal weapon_added(weapon_id) # 获得新武器
@warning_ignore("unused_signal")
signal weapon_upgraded(weapon_id) # 武器升级

# --- UI相关信号 ---
@warning_ignore("unused_signal")
signal show_level_up_screen(upgrade_choices: Array)
@warning_ignore("unused_signal")
signal boss_spawned(boss_name: String, boss_hp: float, boss_max_hp: float)
@warning_ignore("unused_signal")
signal boss_health_changed(boss_hp: float, boss_max_hp: float)
@warning_ignore("unused_signal")
signal boss_defeated()
@warning_ignore("unused_signal")
signal damage_dealt(damage_amount: float, position: Vector2, is_critical: bool, weapon_id: String)

# --- 视觉反馈信号 ---
@warning_ignore("unused_signal")
signal screen_shake(duration: float, intensity: float)  # 屏幕震动 (随机)
@warning_ignore("unused_signal")
signal directional_shake(direction: Vector2, force: float, duration: float) # 定向震动 (猛烈偏移)
@warning_ignore("unused_signal")
signal screen_flash(color: Color, duration: float) # 屏幕闪光 (受击泛红)
@warning_ignore("unused_signal")
signal spawn_death_particles(position: Vector2, color: Color, count: int)  # 死亡粒子

# --- 技能效果信号 ---
@warning_ignore("unused_signal")
signal time_stopped(duration: float)  # 时停开始
@warning_ignore("unused_signal")
signal time_resumed()  # 时停结束
@warning_ignore("unused_signal")
signal attack_speed_modifier_changed(modifier: float)  # 攻速修正变化

# --- 商店相关信号 ---
@warning_ignore("unused_signal")
signal coins_changed(current_coins: int)  # 金币变化
@warning_ignore("unused_signal")
signal shop_opened()  # 商店打开
@warning_ignore("unused_signal")
signal shop_closed()  # 商店关闭
@warning_ignore("unused_signal")
signal item_purchased(item_id: String)  # 购买物品
@warning_ignore("unused_signal")
signal shop_available()  # 商店可用（波次间隙）

# --- 掉落物信号 ---
@warning_ignore("unused_signal")
signal treasure_chest_spawn(position: Vector2)  # 精英怪掉落宝箱
@warning_ignore("unused_signal")
signal element_enchant_spawn(position: Vector2, element_type: int)  # 元素附魔道具生成

# --- 元素附魔信号 ---
@warning_ignore("unused_signal")
signal element_enchant_applied(element_type: int, duration: float)  # 元素附魔应用
@warning_ignore("unused_signal")
signal element_enchant_expired()  # 元素附魔过期

# --- 房间/波次系统信号 ---
@warning_ignore("unused_signal")
signal room_entered(room_type: int, room_index: int)  # 进入房间
@warning_ignore("unused_signal")
signal room_cleared()  # 房间清理完成
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)  # 波次开始
@warning_ignore("unused_signal")
signal all_waves_completed()  # 所有波次完成
@warning_ignore("unused_signal")
signal spawn_wave(enemy_count: int, room_index: int)  # 生成一波敌人
@warning_ignore("unused_signal")
signal spawn_boss(room_index: int)  # 生成BOSS
@warning_ignore("unused_signal")
signal wave_info_updated(current_wave: int, total_waves: int)  # 波次信息更新
@warning_ignore("unused_signal")
signal room_info_updated(room_type: String, room_index: int)  # 房间信息更新
@warning_ignore("unused_signal")
signal boss_dialogue(boss_name: String, dialogue: String)  # Boss对话

# --- 货币系统信号 ---
@warning_ignore("unused_signal")
signal tenryu_changed(current_tenryu: int)  # 転流（杀敌数）变化

# --- 设置系统信号 ---
@warning_ignore("unused_signal")
signal settings_changed()  # 设置改变
@warning_ignore("unused_signal")
signal pause_menu_toggled(is_paused: bool)  # 暂停菜单切换

# --- 新增 RPG 系统信号 ---
@warning_ignore("unused_signal")
signal inventory_opened()  # 背包打开
@warning_ignore("unused_signal")
signal inventory_closed()  # 背包关闭
@warning_ignore("unused_signal")
signal quest_log_opened()  # 任务日志打开
@warning_ignore("unused_signal")
signal quest_log_closed()  # 任务日志关闭
@warning_ignore("unused_signal")
signal npc_interaction_started(npc_id: String)  # NPC 交互开始
@warning_ignore("unused_signal")
signal npc_interaction_ended()  # NPC 交互结束
@warning_ignore("unused_signal")
signal dialogue_line_displayed(npc_name: String, text: String)  # 对话显示
