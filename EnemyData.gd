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

	# 特殊行为
	var can_shoot: bool = false
	var shoot_interval: float = 2.0
	var can_jump: bool = false
	var jump_interval: float = 1.0

	func _init(t: int, n: String, h: float, d: float, s: float, e: int, c: Color, r: float, m: float = 10.0):
		enemy_type = t
		enemy_name = n
		hp = h
		damage = d
		speed = s
		exp = e
		color = c
		radius = r
		mass = m

# Boss配置类
class BossConfig extends EnemyConfig:
	var boss_type: int  # GameConstants.BossType
	var boss_title: String
	var attack_patterns: Array = []  # 攻击模式列表

	func _init(bt: int, n: String, title: String, h: float, d: float, s: float, e: int, c: Color, r: float, m: float = 50.0):
		super._init(GameConstants.EnemyType.BOSS, n, h, d, s, e, c, r, m)
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
	# ==================== 普通敌人 ====================

	# 小妖精 - 基础敌人
	var fairy = EnemyConfig.new(
		GameConstants.EnemyType.FAIRY,
		"小妖精",
		50.0,   # HP
		10.0,   # 伤害
		2.0,    # 速度
		3,      # 经验
		Color("#ff69b4"),  # 粉色
		20.0,   # 半径
		5.0     # 质量 - 很轻，容易被击退
	)
	ENEMIES[GameConstants.EnemyType.FAIRY] = fairy

	# 幽灵 - 中等敌人
	var ghost = EnemyConfig.new(
		GameConstants.EnemyType.GHOST,
		"幽灵",
		80.0,
		15.0,
		1.5,
		5,
		Color("#9b59b6"),  # 紫色
		25.0,
		8.0     # 质量 - 轻盈
	)
	ENEMIES[GameConstants.EnemyType.GHOST] = ghost

	# 史莱姆 - 跳跃敌人
	var slime = EnemyConfig.new(
		GameConstants.EnemyType.SLIME,
		"史莱姆",
		100.0,
		20.0,
		1.8,
		8,
		Color("#3498db"),  # 蓝色
		30.0,
		15.0    # 质量 - 较重
	)
	slime.can_jump = true
	slime.jump_interval = 1.0
	ENEMIES[GameConstants.EnemyType.SLIME] = slime

	# 精灵 - 远程射击敌人
	var elf = EnemyConfig.new(
		GameConstants.EnemyType.ELF,
		"精灵",
		70.0,
		12.0,
		2.2,
		10,
		Color("#2ecc71"),  # 绿色
		22.0,
		6.0     # 质量 - 很轻
	)
	elf.can_shoot = true
	elf.shoot_interval = 2.0
	ENEMIES[GameConstants.EnemyType.ELF] = elf

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
		60.0,    # 半径
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
		60.0,
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
		60.0,
		50.0     # 质量 - 最重的Boss
	)
	kaguya.attack_patterns = ["impossible_bullet_hell", "time_stop"]
	BOSSES[GameConstants.BossType.KAGUYA] = kaguya

	# ==================== 波次系统 ====================
	# 完整的10波敌人配置（基于原项目的WAVES）

	# Wave 1: 史莱姆 - 每2秒生成，持续整局
	WAVES.append(WaveConfig.new(
		0.0,          # 开始时间
		2.0,          # 每2秒生成（调整为2秒，原来1秒太快）
		"slime",
		20.0,         # HP
		5.0,          # 伤害
		1.5,          # 速度
		3,            # 经验
		Color("#a8e6cf")  # 浅绿色
	))

	# Wave 2: 精灵 - 每5秒生成，从30秒后开始（原来从0秒开始太快）
	WAVES.append(WaveConfig.new(
		30.0,         # 30秒后开始
		5.0,          # 每5秒生成
		"elf",
		40.0,
		6.0,
		2.0,
		8,
		Color("#87ceeb")  # 天蓝色
	))

	# Wave 3: 史莱姆强化 - 1分钟后，每1.5秒生成
	WAVES.append(WaveConfig.new(
		60.0,         # 1分钟后
		1.5,          # 每1.5秒生成（原来0.75太快）
		"slime",
		60.0,
		8.0,
		2.0,
		5,
		Color("#3b7a57")  # 深绿色
	))

	# Wave 4: 精灵强化 - 3分钟后，每1秒生成
	WAVES.append(WaveConfig.new(
		180.0,        # 3分钟后
		1.0,          # 每1秒生成（原来0.5太快）
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

	# Wave 6: 精灵高级 - 6分钟后，每0.8秒生成
	WAVES.append(WaveConfig.new(
		360.0,        # 6分钟后
		0.8,          # 每0.8秒生成（原来0.25太快）
		"elf",
		200.0,
		15.0,
		3.0,
		20,
		Color("#4682b4")
	))

	# Wave 7: 幽灵 - 10分钟后，每0.5秒生成
	WAVES.append(WaveConfig.new(
		600.0,        # 10分钟后
		0.5,          # 每0.5秒生成（原来0.17太快）
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

	# Wave 9: 幽灵强化 - 16分钟后，每0.4秒生成
	WAVES.append(WaveConfig.new(
		960.0,        # 16分钟后
		0.4,          # 每0.4秒生成（原来0.13太快）
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
		return ENEMIES[GameConstants.EnemyType.SLIME]
	elif wave <= 20:
		return ENEMIES[GameConstants.EnemyType.ELF]
	else:
		# 混合生成
		var types = [
			GameConstants.EnemyType.FAIRY,
			GameConstants.EnemyType.GHOST,
			GameConstants.EnemyType.SLIME,
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
