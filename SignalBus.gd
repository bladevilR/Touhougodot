extends Node

# SignalBus - 全局信号总线
# 这是整个游戏的"电话局"，所有节点只跟它说话，不互相找

# --- 全局状态变量 ---
var selected_character_id: int = 0  # 当前选择的角色ID

# --- 战斗相关信号 ---
@warning_ignore("unused_signal")  # Signal is emitted from other classes (HealthComponent, Player, etc.)
signal player_health_changed(current_hp, max_hp)
signal player_died()
signal enemy_killed(xp_value, position) # 怪物死了，通知掉落系统和经验系统
signal xp_gained(current_xp, max_xp, level)
signal xp_pickup(xp_value) # 拾取经验球

# --- 系统相关信号 ---
signal game_started()
signal game_over()
signal level_up(new_level)

# --- 武器相关信号 ---
signal weapon_added(weapon_id) # 获得新武器
signal weapon_upgraded(weapon_id) # 武器升级

# --- UI相关信号 ---
signal character_selected(character_id: int)
signal bond_selected(bond_id: String)
signal start_game_requested()
signal show_level_up_screen(upgrade_choices: Array)
signal upgrade_selected(upgrade_choice)
signal boss_spawned(boss_name: String, boss_hp: float, boss_max_hp: float)
signal boss_health_changed(boss_hp: float, boss_max_hp: float)
signal boss_defeated()
signal damage_dealt(damage_amount: float, position: Vector2, is_critical: bool, weapon_id: String)

# --- 视觉反馈信号 ---
signal screen_shake(duration: float, intensity: float)  # 屏幕震动 (随机)
signal directional_shake(direction: Vector2, force: float, duration: float) # 定向震动 (猛烈偏移)
signal screen_flash(color: Color, duration: float) # 屏幕闪光 (受击泛红)
signal spawn_death_particles(position: Vector2, color: Color, count: int)  # 死亡粒子

# --- 技能效果信号 ---
signal time_stopped(duration: float)  # 时停开始
signal time_resumed()  # 时停结束
signal attack_speed_modifier_changed(modifier: float)  # 攻速修正变化

# --- 商店相关信号 ---
signal coins_changed(current_coins: int)  # 金币变化
signal shop_opened()  # 商店打开
signal shop_closed()  # 商店关闭
signal item_purchased(item_id: String)  # 购买物品
signal shop_available()  # 商店可用（波次间隙）

# --- 掉落物信号 ---
signal treasure_chest_spawn(position: Vector2)  # 精英怪掉落宝箱
signal element_enchant_spawn(position: Vector2, element_type: int)  # 元素附魔道具生成

# --- 元素附魔信号 ---
signal element_enchant_applied(element_type: int, duration: float)  # 元素附魔应用
signal element_enchant_expired()  # 元素附魔过期

# --- 房间/波次系统信号 ---
signal spawn_wave(enemy_count: int, room_index: int)  # 生成一波敌人
signal spawn_boss(room_index: int)  # 生成BOSS
signal room_cleared()  # 房间清理完成
signal wave_info_updated(current_wave: int, total_waves: int)  # 波次信息更新
signal room_info_updated(room_type: String, room_index: int)  # 房间信息更新
signal boss_dialogue(boss_name: String, dialogue: String)  # Boss对话

# --- 货币系统信号 ---
signal tenryu_changed(current_tenryu: int)  # 転流（杀敌数）变化

# --- 设置系统信号 ---
signal settings_changed()  # 设置改变
signal pause_menu_toggled(is_paused: bool)  # 暂停菜单切换
