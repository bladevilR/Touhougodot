extends Node

# SignalBus - 全局信号总线
# 这是整个游戏的"电话局"，所有节点只跟它说话，不互相找

# --- 全局变量 ---
# 当前选中的角色ID（固定为妹红，但保留变量以兼容现有代码）
var selected_character_id: int = 1  # 1 = GameConstants.CharacterId.MOKOU

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
signal character_selected(character_id: int)  # 角色选择（固定妹红，但保留信号）
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
@warning_ignore("unused_signal")
signal show_notification(message: String, color: Color)  # 显示通知消息（采集、拾取等）
@warning_ignore("unused_signal")
signal item_harvested(item_id: String, amount: int)  # 物品被采集

# --- 羁绊系统信号 ---
@warning_ignore("unused_signal")
signal bond_selected(bond_id: String)  # 选择羁绊角色

# --- 时间系统信号 ---
@warning_ignore("unused_signal")
signal time_tick(total_minutes: int)  # 每游戏分钟触发
@warning_ignore("unused_signal")
signal hour_changed(hour: int)  # 整点触发
@warning_ignore("unused_signal")
signal time_of_day_changed(period: int)  # 时段变化 (黎明/上午/中午/下午/黄昏/夜晚/深夜)
@warning_ignore("unused_signal")
signal day_changed(day: int)  # 日期变化（TimeManager触发）

# --- 日历系统信号 ---
@warning_ignore("unused_signal")
signal day_started(day: int, weekday: String, season: String)  # 新的一天开始（完整信息）
@warning_ignore("unused_signal")
signal week_changed(week: int)  # 周变化
@warning_ignore("unused_signal")
signal season_changed(old_season: String, new_season: String)  # 季节变化
@warning_ignore("unused_signal")
signal year_changed(year: int)  # 年变化
@warning_ignore("unused_signal")
signal festival_started(festival_id: String)  # 节日开始

# --- 任务系统扩展信号 ---
@warning_ignore("unused_signal")
signal daily_quests_reset()  # 每日任务重置

# --- 商店系统扩展信号 ---
@warning_ignore("unused_signal")
signal shop_stock_refreshed(shop_id: String)  # 商店库存刷新
@warning_ignore("unused_signal")
signal item_sold(item_id: String, amount: int, price: int)  # 出售物品
