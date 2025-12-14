extends Node

# GameConstants - 游戏常量配置

# 画面尺寸
const CANVAS_WIDTH = 1920
const CANVAS_HEIGHT = 1080
const MAP_WIDTH = 2400  # 九宫格设计：中心1600x1000战斗区 + 四周400px竹林墙
const MAP_HEIGHT = 1800
const FPS = 60
const GAME_SPEED = 2.0  # 2x游戏速度
const GRASS_TILE_SIZE = 256

# 角色ID枚举
enum CharacterId {
	REIMU,    # 博丽灵梦
	MOKOU,    # 藤原妹红
	MARISA,   # 雾雨魔理沙
	SAKUYA,   # 十六夜咲夜
	YUMA,     # 饕餮尤魔
	KOISHI    # 古明地恋
}

# 敌人类型枚举
enum EnemyType {
	FAIRY,    # 小妖精
	GHOST,    # 幽灵
	KEDAMA,   # 毛玉（跳跃）
	ELF,      # 精灵（远程射击）
	ELITE,    # 精英怪（大体积、高血量、掉宝箱）
	BOSS      # Boss
}

# Boss类型枚举
enum BossType {
	CIRNO,    # 琪露诺
	YOUMU,    # 妖梦
	KAGUYA    # 辉夜
}

# 元素类型枚举
enum ElementType {
	FIRE,      # 火
	ICE,       # 冰
	POISON,    # 毒
	OIL,       # 油
	LIGHTNING, # 雷
	GRAVITY    # 引力
}

# 武器类型枚举
enum WeaponType {
	PROJECTILE, # 弹幕
	AURA,       # 光环
	ORBITAL,    # 环绕
	LASER,      # 激光
	DASH,       # 冲刺
	SPECIAL,    # 特殊
	PASSIVE,    # 被动
	MELEE       # 近战（点击触发）
}
