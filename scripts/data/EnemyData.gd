extends Node
class_name EnemyData

# EnemyData - 敌人配置数据

# 敌人配置类
class EnemyConfig:
	var enemy_type: int  # GameConstants.EnemyType
	var enemy_name: String
	var hp: float
	var damage: float
	var speed: float
	var exp: int
	var color: Color
	var radius: float
	var mass: float  # 质量（影响击退抗性）
	var scale: float # 视觉缩放

	# 特殊行为
	var can_shoot: bool = false
	var shoot_interval: float = 2.0
	var can_jump: bool = false
	var jump_interval: float = 1.0
	var drops_chest: bool = false  # 是否掉落宝箱（精英怪专属）
	var is_elite: bool = false     # 是否是精英怪

	func _init(t: int, n: String, h: float, d: float, s: float, e: int, c: Color, r: float, m: float = 10.0, sc: float = 0.025):
		enemy_type = t
		enemy_name = n
		hp = h
		damage = d
		speed = s
		exp = e
		color = c
		radius = r
		mass = m
		scale = sc

# Boss配置类
class BossConfig extends EnemyConfig:
	var boss_type: int  # GameConstants.BossType
	var boss_title: String
	var attack_patterns: Array = []  # 攻击模式列表

	func _init(bt: int, n: String, title: String, h: float, d: float, s: float, e: int, c: Color, r: float, m: float = 50.0, sc: float = 0.05):
		super._init(GameConstants.EnemyType.BOSS, n, h, d, s, e, c, r, m, sc)
		boss_type = bt
		boss_title = title

# 波次配置类
class WaveConfig:
	var time: float           # 开始时间（秒）
	var interval: float       # 生成间隔（秒）
	var enemy_type: String    # 敌人类型
	var hp: float
	var damage: float
	var speed: float
	var exp: int
	var color: Color

	func _init(t: float, iv: float, et: String, h: float, d: float, s: float, e: int, c: Color):
		time = t
		interval = iv
		enemy_type = et
		hp = h
		damage = d
		speed = s
		exp = e
		color = c

# 所有敌人数据
static var ENEMIES = {}
static var BOSSES = {}
static var WAVES = []

static func initialize():
	# Clear existing data to prevent accumulation on restart
	ENEMIES.clear()
	BOSSES.clear()
	WAVES.clear()

	# ==================== 普通敌人 ====================

	# 小妖精 - 稀有射击怪 (原基础敌人)
	var fairy = EnemyConfig.new(
		GameConstants.EnemyType.FAIRY,
		"向日葵妖精",
		60.0,   # HP 稍高
		15.0,   # 伤害
		1.0,    # 速度 降低 1.5 -> 1.0
		8,      # 经验 较高
		Color.WHITE,  # [修复] 恢复原色
		10.0,   # 半径
		8.0     # 质量
	)
	fairy.can_shoot = true
	fairy.shoot_interval = 2.5
	ENEMIES[GameConstants.EnemyType.FAIRY] = fairy

	# 幽灵 - 中等敌人
	var ghost = EnemyConfig.new(
		GameConstants.EnemyType.GHOST,
		"幽灵",
		80.0,
		15.0,
		1.0,    # 速度 降低 1.5 -> 1.0
		5,
		Color("#9b59b6"),  # 紫色
		10.0,   # 半径 - 缩小到人的一半大小
		8.0     # 质量 - 轻盈
	)
	ENEMIES[GameConstants.EnemyType.GHOST] = ghost

	# 毛玉 - 基础杂兵 (原跳跃敌人)
	var kedama = EnemyConfig.new(
		GameConstants.EnemyType.KEDAMA,
		"毛玉",
		30.0,   # HP 较低
		8.0,    # 伤害 较低
		1.5,    # 速度 降低 2.2 -> 1.5 (只会冲撞)
		2,      # 经验 低
		Color("#ffffff"),  # 白色
		12.0,    # 半径 [修复] 稍微变大
		5.0,     # 质量 轻
		0.035    # [修复] 缩放微调 (原0.04, 现调整为0.035)
	)
	kedama.can_jump = true
	kedama.jump_interval = 0.8
	ENEMIES[GameConstants.EnemyType.KEDAMA] = kedama

	# 精灵 - 远程射击敌人 (保留为高级远程)
	var elf = EnemyConfig.new(
		GameConstants.EnemyType.ELF,
		"精灵",
		70.0,
		12.0,
		1.5,    # 速度 降低 2.2 -> 1.5
		10,
		Color("#2ecc71"),  # 绿色
		9.0,    # 半径
		6.0     # 质量
	)
	elf.can_shoot = true
	elf.shoot_interval = 2.0
	ENEMIES[GameConstants.EnemyType.ELF] = elf

	# 精英怪 - 大体积、慢速、高血量
	var elite = EnemyConfig.new(
		GameConstants.EnemyType.ELITE,
		"精英怪",
		500.0,   # HP - 普通怪的5-10倍
		30.0,    # 伤害 - 较高
		0.5,     # 速度 降低 0.8 -> 0.5 - 慢速
		50,      # 经验 - 大量经验
		Color("#ff6600"),  # 橙色（醒目）
		25.0,    # 半径 - 大体积（约普通怪3倍）
		50.0,    # 质量 - 很重，难以击退
		0.06     # 缩放 - 视觉上更大
	)
	elite.can_jump = false  # 精英怪不跳跃，稳重
	elite.drops_chest = true   # 精英怪掉落宝箱
	elite.is_elite = true      # 标记为精英怪
	ENEMIES[GameConstants.EnemyType.ELITE] = elite

	# ==================== Boss ====================

	# Boss 1: 琪露诺
	var cirno = BossConfig.new(
		GameConstants.BossType.CIRNO,
		"琪露诺",
		"湖上的冰精",
		3000.0,  # HP
		25.0,    # 伤害
		1.5,     # 速度
		500,     # 经验
		Color("#00ffff"),  # 青色
		25.0,    # 半径 - Boss稍大但也缩小
		30.0     # 质量 - Boss级别抗击退
	)
	cirno.attack_patterns = ["ice_spread", "freeze_circle"]
	BOSSES[GameConstants.BossType.CIRNO] = cirno

	# Boss 2: 妖梦
	var youmu = BossConfig.new(
		GameConstants.BossType.YOUMU,
		"魂魄妖梦",
		"半灵的庭师",
		4000.0,
		30.0,
		2.0,
		800,
		Color("#e0e0e0"),  # 银白色
		25.0,    # 半径 - Boss稍大但也缩小
		40.0     # 质量 - 更重的Boss
	)
	youmu.attack_patterns = ["sword_dash", "spirit_split"]
	BOSSES[GameConstants.BossType.YOUMU] = youmu

	# Boss 3: 辉夜
	var kaguya = BossConfig.new(
		GameConstants.BossType.KAGUYA,
		"蓬莱山辉夜",
		"永远和须臾的罪人",
		5000.0,
		35.0,
		1.2,
		1200,
		Color("#ffd700"),  # 金色
		25.0,    # 半径 - Boss稍大但也缩小
		50.0     # 质量 - 最重的Boss
	)
	kaguya.attack_patterns = ["impossible_bullet_hell", "time_stop"]
	BOSSES[GameConstants.BossType.KAGUYA] = kaguya

	# ==================== 波次系统 ====================
	# 完整的10波敌人配置（基于原项目的WAVES）

	# Wave 1: 毛玉 - 每3秒生成，持续整局
	WAVES.append(WaveConfig.new(
		0.0,          # 开始时间
		4.0,          # [修复] 间隔增加到4秒（减少数量）
		"kedama",
		20.0,         # HP
		5.0,          # 伤害
		1.0,          # 速度（降低到1.0，更慢）
		3,            # 经验
		Color("#a8e6cf")  # 浅绿色
	))

	# Wave 2: 精灵 - 每6秒生成，从30秒后开始
	WAVES.append(WaveConfig.new(
		30.0,         # 30秒后开始
		6.0,          # 每6秒生成（进一步放慢）
		"elf",
		40.0,
		6.0,
		2.0,
		8,
		Color("#87ceeb")  # 天蓝色
	))

	# Wave 3: 毛玉强化 - 1分钟后，每2秒生成
	WAVES.append(WaveConfig.new(
		60.0,         # 1分钟后
		3.0,          # [修复] 间隔增加到3秒（减少数量）
		"kedama",
		60.0,
		8.0,
		2.0,
		5,
		Color("#3b7a57")  # 深绿色
	))

	# Wave 4: 精灵强化 - 3分钟后，每1.5秒生成
	WAVES.append(WaveConfig.new(
		180.0,        # 3分钟后
		1.5,          # 每1.5秒生成（进一步放慢）
		"elf",
		120.0,
		10.0,
		2.5,
		12,
		Color("#4682b4")  # 钢蓝色
	))

	# Wave 5: Boss 1 - 琪露诺（5分钟）
	WAVES.append(WaveConfig.new(
		300.0,        # 5分钟
		5.0,          # 每5秒生成一次（单次）
		"boss1",
		800.0,        # HP
		20.0,
		2.0,
		300,
		Color("#4dd2ff")  # 亮青色
	))

	# Wave 6: 精灵高级 - 6分钟后，每1.2秒生成
	WAVES.append(WaveConfig.new(
		360.0,        # 6分钟后
		1.2,          # 每1.2秒生成（进一步放慢）
		"elf",
		200.0,
		15.0,
		3.0,
		20,
		Color("#4682b4")
	))

	# Wave 7: 幽灵 - 10分钟后，每1秒生成
	WAVES.append(WaveConfig.new(
		600.0,        # 10分钟后
		1.0,          # 每1秒生成（进一步放慢）
		"ghost",
		400.0,
		20.0,
		3.5,
		35,
		Color("#2c3e50")  # 深灰色
	))

	# Wave 8: Boss 2 - 魂魄妖梦（15分钟）
	WAVES.append(WaveConfig.new(
		900.0,        # 15分钟
		15.0,         # 每15秒生成一次（单次）
		"boss2",
		1500.0,
		30.0,
		2.5,
		800,
		Color("#90ee90")  # 浅绿色
	))

	# Wave 9: 幽灵强化 - 16分钟后，每0.8秒生成
	WAVES.append(WaveConfig.new(
		960.0,        # 16分钟后
		0.8,          # 每0.8秒生成（进一步放慢）
		"ghost",
		600.0,
		25.0,
		4.0,
		50,
		Color("#34495e")  # 更深灰色
	))

	# Wave 10: Boss 3 - 蓬莱山辉夜（30分钟）
	WAVES.append(WaveConfig.new(
		1800.0,       # 30分钟
		30.0,         # 每30秒生成一次（单次）
		"boss3",
		3000.0,
		40.0,
		2.0,
		1500,
		Color("#ff69b4")  # 粉红色
	))

# 根据当前波次获取敌人配置
static func get_enemy_for_wave(wave: int) -> EnemyConfig:
	# 简单的波次难度递增
	if wave <= 5:
		return ENEMIES[GameConstants.EnemyType.FAIRY]
	elif wave <= 10:
		return ENEMIES[GameConstants.EnemyType.GHOST]
	elif wave <= 15:
		return ENEMIES[GameConstants.EnemyType.KEDAMA]
	elif wave <= 20:
		return ENEMIES[GameConstants.EnemyType.ELF]
	else:
		# 混合生成
		var types = [
			GameConstants.EnemyType.FAIRY,
			GameConstants.EnemyType.GHOST,
			GameConstants.EnemyType.KEDAMA,
			GameConstants.EnemyType.ELF
		]
		return ENEMIES[types[randi() % types.size()]]

# 根据时间判断是否生成Boss
static func should_spawn_boss(time: float) -> BossConfig:
	if time >= 300.0 and time < 301.0:  # 5分钟 - 琪露诺
		return BOSSES[GameConstants.BossType.CIRNO]
	elif time >= 600.0 and time < 601.0:  # 10分钟 - 妖梦
		return BOSSES[GameConstants.BossType.YOUMU]
	elif time >= 900.0 and time < 901.0:  # 15分钟 - 辉夜
		return BOSSES[GameConstants.BossType.KAGUYA]
	return null

static func get_random_enemy_for_time(time: float) -> EnemyConfig:
	"""根据时间获取随机敌人配置 (毛玉为主)"""
	var rand = randf()
	
	# 早期 (0-2分钟)
	if time < 120.0:
		if rand < 0.9: return ENEMIES[GameConstants.EnemyType.KEDAMA] # 90% 毛玉
		else: return ENEMIES[GameConstants.EnemyType.FAIRY] # 10% 妖精
		
	# 中期 (2-5分钟)
	if time < 300.0:
		if rand < 0.8: return ENEMIES[GameConstants.EnemyType.KEDAMA]
		else: return ENEMIES[GameConstants.EnemyType.FAIRY] # 20%
		
	# 后期
	if rand < 0.7: return ENEMIES[GameConstants.EnemyType.KEDAMA]
	else: return ENEMIES[GameConstants.EnemyType.FAIRY]