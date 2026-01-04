extends Node

## ItemData - 物品数据库
## 定义所有物品的属性、效果、描述等

# 物品数据库
var items: Dictionary = {}

func _ready():
	initialize()

func initialize() -> void:
	_define_consumables()
	_define_equipment()
	_define_materials()
	print("[ItemData] 物品数据库初始化完成，共 %d 种物品" % items.size())

## 定义消耗品
func _define_consumables() -> void:
	# 回复药品
	items["health_potion_small"] = {
		"id": "health_potion_small",
		"name": "小型治疗药",
		"description": "恢复 50 HP",
		"type": "consumable",
		"max_stack": 99,
		"icon": "res://assets/items/health_potion_small.png",
		"effects": {
			"heal_hp": 50
		},
		"price": 50
	}

	items["health_potion_medium"] = {
		"id": "health_potion_medium",
		"name": "中型治疗药",
		"description": "恢复 150 HP",
		"type": "consumable",
		"max_stack": 99,
		"icon": "res://assets/items/health_potion_medium.png",
		"effects": {
			"heal_hp": 150
		},
		"price": 150
	}

	items["health_potion_large"] = {
		"id": "health_potion_large",
		"name": "大型治疗药",
		"description": "恢复 500 HP",
		"type": "consumable",
		"max_stack": 99,
		"icon": "res://assets/items/health_potion_large.png",
		"effects": {
			"heal_hp": 500
		},
		"price": 500
	}

	# 食物（符文工房风格）
	items["rice_ball"] = {
		"id": "rice_ball",
		"name": "饭团",
		"description": "简单的饭团，恢复少量HP",
		"type": "consumable",
		"max_stack": 99,
		"icon": "res://assets/items/rice_ball.png",
		"effects": {
			"heal_hp": 30
		},
		"price": 20
	}

	items["grilled_fish"] = {
		"id": "grilled_fish",
		"name": "烤鱼",
		"description": "香喷喷的烤鱼，恢复中量HP",
		"type": "consumable",
		"max_stack": 99,
		"icon": "res://assets/items/grilled_fish.png",
		"effects": {
			"heal_hp": 80
		},
		"price": 100
	}

## 定义装备
func _define_equipment() -> void:
	# 武器（虽然战斗系统用WeaponData，但这里定义装备物品）
	items["wooden_sword"] = {
		"id": "wooden_sword",
		"name": "木剑",
		"description": "普通的木剑",
		"type": "equipment",
		"slot": "weapon",
		"max_stack": 1,
		"icon": "res://assets/items/wooden_sword.png",
		"stats": {
			"attack": 10
		},
		"price": 100
	}

	# 护甲
	items["cloth_armor"] = {
		"id": "cloth_armor",
		"name": "布甲",
		"description": "简单的布制护甲",
		"type": "equipment",
		"slot": "armor",
		"max_stack": 1,
		"icon": "res://assets/items/cloth_armor.png",
		"stats": {
			"defense": 5,
			"max_hp": 20
		},
		"price": 150
	}

	# 饰品
	items["speed_amulet"] = {
		"id": "speed_amulet",
		"name": "疾风护符",
		"description": "增加移动速度",
		"type": "equipment",
		"slot": "accessory",
		"max_stack": 1,
		"icon": "res://assets/items/speed_amulet.png",
		"stats": {
			"speed": 50
		},
		"price": 200
	}

## 定义材料
func _define_materials() -> void:
	items["bamboo"] = {
		"id": "bamboo",
		"name": "竹子",
		"description": "可用于建造和制作的竹子",
		"type": "material",
		"max_stack": 99,
		"icon": "res://assets/items/bamboo.png",
		"price": 10
	}

	items["iron_ore"] = {
		"id": "iron_ore",
		"name": "铁矿石",
		"description": "可用于锻造的铁矿石",
		"type": "material",
		"max_stack": 99,
		"icon": "res://assets/items/iron_ore.png",
		"price": 50
	}

	items["magic_crystal"] = {
		"id": "magic_crystal",
		"name": "魔法水晶",
		"description": "蕴含魔力的水晶",
		"type": "material",
		"max_stack": 99,
		"icon": "res://assets/items/magic_crystal.png",
		"price": 100
	}

## 查询方法
func has_item(item_id: String) -> bool:
	return items.has(item_id)

func get_item(item_id: String) -> Dictionary:
	if not items.has(item_id):
		push_error("[ItemData] 物品不存在: %s" % item_id)
		return {}
	return items[item_id]

func get_item_name(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("name", "未知物品")

func get_item_description(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("description", "")

func get_item_icon(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("icon", "")

func get_all_items() -> Dictionary:
	return items.duplicate()

func get_items_by_type(item_type: String) -> Array[String]:
	var result: Array[String] = []
	for item_id in items:
		if items[item_id].get("type") == item_type:
			result.append(item_id)
	return result
