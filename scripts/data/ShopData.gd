extends Node

## ShopData - 商店数据定义
## 定义所有商店的商品、价格、库存配置

# ==================== 商店类型 ====================
enum ShopType {
	GENERAL,      # 杂货店
	BLACKSMITH,   # 铁匠铺
	MAGIC,        # 魔法店
	COMBAT,       # 战斗用品店
	SEASONAL      # 季节限定店
}

# ==================== 商店配置 ====================
const SHOPS := {
	"town_general": {
		"name": "人里杂货店",
		"type": ShopType.GENERAL,
		"owner": "雾雨店主",
		"description": "村民们日常生活的好帮手",
		"items": [
			{"id": "seed_tomato", "price": 50, "stock": 99},
			{"id": "seed_wheat", "price": 30, "stock": 99},
			{"id": "seed_pumpkin", "price": 80, "stock": 50},
			{"id": "seed_carrot", "price": 40, "stock": 99},
			{"id": "fertilizer", "price": 100, "stock": 20},
			{"id": "watering_can", "price": 500, "stock": 5},
		],
		"buy_rate": 0.5,  # 收购价为原价的50%
		"open_hours": {"start": 6, "end": 20},  # 营业时间
	},

	"town_blacksmith": {
		"name": "铁匠铺",
		"type": ShopType.BLACKSMITH,
		"owner": "铁匠",
		"description": "打造和强化武器装备",
		"items": [
			{"id": "sword_basic", "price": 1000, "stock": 3},
			{"id": "sword_steel", "price": 2500, "stock": 2},
			{"id": "armor_leather", "price": 800, "stock": 5},
			{"id": "armor_iron", "price": 2000, "stock": 3},
			{"id": "pickaxe", "price": 600, "stock": 5},
			{"id": "hoe_iron", "price": 400, "stock": 5},
		],
		"buy_rate": 0.4,
		"open_hours": {"start": 8, "end": 18},
	},

	"nitori_combat": {
		"name": "河城商店",
		"type": ShopType.COMBAT,
		"owner": "河城荷取",
		"description": "河童科技，品质保证！",
		"items": [
			{"id": "bomb_small", "price": 200, "stock": 10},
			{"id": "bomb_large", "price": 500, "stock": 5},
			{"id": "health_potion", "price": 150, "stock": 20},
			{"id": "mana_potion", "price": 200, "stock": 15},
			{"id": "shield_temp", "price": 300, "stock": 8},
			{"id": "speed_boost", "price": 250, "stock": 10},
		],
		"buy_rate": 0.6,
		"open_hours": {"start": 10, "end": 22},
	},

	"magic_shop": {
		"name": "魔法店",
		"type": ShopType.MAGIC,
		"owner": "帕秋莉",
		"description": "各种魔法道具和符卡材料",
		"items": [
			{"id": "spell_card_basic", "price": 500, "stock": 10},
			{"id": "magic_crystal", "price": 1000, "stock": 5},
			{"id": "elemental_orb_fire", "price": 800, "stock": 3},
			{"id": "elemental_orb_water", "price": 800, "stock": 3},
			{"id": "scroll_teleport", "price": 1500, "stock": 2},
		],
		"buy_rate": 0.3,
		"open_hours": {"start": 12, "end": 24},  # 夜猫子营业
	},
}

# ==================== 季节限定商品 ====================
const SEASONAL_ITEMS := {
	"spring": [
		{"id": "seed_cherry", "price": 200, "stock": 10},
		{"id": "flower_bouquet", "price": 150, "stock": 20},
	],
	"summer": [
		{"id": "seed_watermelon", "price": 120, "stock": 15},
		{"id": "firework", "price": 80, "stock": 50},
	],
	"autumn": [
		{"id": "seed_mushroom", "price": 100, "stock": 20},
		{"id": "maple_leaf", "price": 50, "stock": 99},
	],
	"winter": [
		{"id": "hot_drink", "price": 60, "stock": 30},
		{"id": "warm_coat", "price": 800, "stock": 5},
	],
}

# ==================== 节日限定商品 ====================
const FESTIVAL_ITEMS := {
	"new_year": [
		{"id": "lucky_charm", "price": 500, "stock": 10},
		{"id": "mochi", "price": 100, "stock": 50},
	],
	"flower_festival": [
		{"id": "sakura_branch", "price": 300, "stock": 20},
	],
	"tanabata": [
		{"id": "wish_paper", "price": 50, "stock": 99},
	],
	"moon_festival": [
		{"id": "moon_cake", "price": 150, "stock": 30},
	],
}

# ==================== 公开方法 ====================

## 获取商店配置
func get_shop(shop_id: String) -> Dictionary:
	return SHOPS.get(shop_id, {})

## 检查商店是否存在
func has_shop(shop_id: String) -> bool:
	return SHOPS.has(shop_id)

## 获取所有商店ID
func get_all_shop_ids() -> Array:
	return SHOPS.keys()

## 获取商店商品列表
func get_shop_items(shop_id: String) -> Array:
	var shop = get_shop(shop_id)
	if shop.is_empty():
		return []
	return shop.get("items", [])

## 获取季节限定商品
func get_seasonal_items(season: String) -> Array:
	return SEASONAL_ITEMS.get(season, [])

## 获取节日限定商品
func get_festival_items(festival_id: String) -> Array:
	return FESTIVAL_ITEMS.get(festival_id, [])

## 检查商店是否营业
func is_shop_open(shop_id: String, current_hour: int) -> bool:
	var shop = get_shop(shop_id)
	if shop.is_empty():
		return false

	var hours = shop.get("open_hours", {"start": 0, "end": 24})
	var start = hours.get("start", 0)
	var end = hours.get("end", 24)

	# 处理跨夜营业
	if end < start:
		return current_hour >= start or current_hour < end
	else:
		return current_hour >= start and current_hour < end

## 获取商品价格
func get_item_price(shop_id: String, item_id: String) -> int:
	var items = get_shop_items(shop_id)
	for item in items:
		if item.get("id") == item_id:
			return item.get("price", 0)
	return 0

## 获取收购倍率
func get_buy_rate(shop_id: String) -> float:
	var shop = get_shop(shop_id)
	return shop.get("buy_rate", 0.5)
