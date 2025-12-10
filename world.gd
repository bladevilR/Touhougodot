extends Node2D

# World - 主场景管理

func _ready():
	# 初始化游戏系统
	initialize_game()

	# 发送游戏开始信号
	SignalBus.game_started.emit()

func initialize_game():
	# 初始化所有游戏数据
	print("开始初始化游戏数据...")
	CharacterData.initialize()
	print("- 角色数据加载完成（6个角色）")
	WeaponData.initialize()
	print("- 武器数据加载完成（17个武器 + 54个升级选项）")
	EnemyData.initialize()
	print("- 敌人数据加载完成（4种敌人 + 3个Boss + 10波次）")
	ElementData.initialize()
	print("- 元素数据加载完成（6个元素 + 5个反应）")
	BondData.initialize()
	print("- 羁绊角色加载完成（6个支援角色）")
	print("✅ 游戏数据初始化完成！")
