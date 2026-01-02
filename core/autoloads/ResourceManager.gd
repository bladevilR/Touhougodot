extends Node
## 资源管理器 - 统一管理资源加载、缓存和对象池
##
## 功能:
## - 资源缓存（避免重复加载）
## - 对象池管理（Bullet、Enemy、特效等）
## - 异步资源加载
## - 资源引用计数和自动卸载
##
## 使用示例:
##   # 加载资源（自动缓存）
##   var texture = ResourceManager.load_resource("res://assets/sprite.png")
##
##   # 从对象池获取实例
##   var bullet = ResourceManager.get_pooled_instance("bullet")
##
##   # 归还到对象池
##   ResourceManager.return_to_pool(bullet, "bullet")

# 资源缓存字典
var resource_cache: Dictionary = {}

# 对象池字典
var object_pools: Dictionary = {}

# 对象池配置
var pool_configs: Dictionary = {
	"bullet": {"scene": "res://Bullet.tscn", "initial_size": 100},
	"enemy": {"scene": "res://Enemy.tscn", "initial_size": 50},
	"damage_number": {"scene": "res://DamageNumber.tscn", "initial_size": 30},
	"death_particle": {"scene": "res://DeathParticle.tscn", "initial_size": 20},
	"fire_trail": {"scene": "res://FireTrail.tscn", "initial_size": 50}
}

func _ready():
	print("ResourceManager: 初始化中...")
	_initialize_pools()
	print("ResourceManager: 初始化完成")

## 初始化所有对象池
func _initialize_pools() -> void:
	for pool_name in pool_configs:
		var config = pool_configs[pool_name]
		object_pools[pool_name] = []

		# 预创建对象
		for i in range(config["initial_size"]):
			var instance = _create_pooled_instance(config["scene"])
			if instance:
				object_pools[pool_name].append(instance)

		print("ResourceManager: 对象池 '%s' 已初始化 (%d 个对象)" % [pool_name, config["initial_size"]])

## 创建一个对象池实例
func _create_pooled_instance(scene_path: String) -> Node:
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		instance.set_meta("pooled", true)
		instance.set_meta("pool_scene", scene_path)
		return instance
	else:
		push_error("ResourceManager: 无法加载场景 '%s'" % scene_path)
		return null

## 从对象池获取一个实例
func get_pooled_instance(pool_name: String) -> Node:
	if pool_name in object_pools and not object_pools[pool_name].is_empty():
		var instance = object_pools[pool_name].pop_front()
		instance.visible = true
		if instance.has_method("reset"):
			instance.reset()  # 如果实例有 reset() 方法，调用它
		return instance
	else:
		# 对象池为空，创建新实例（应急）
		if pool_name in pool_configs:
			var config = pool_configs[pool_name]
			push_warning("ResourceManager: 对象池 '%s' 为空，创建新实例" % pool_name)
			return _create_pooled_instance(config["scene"])
		else:
			push_error("ResourceManager: 未知的对象池 '%s'" % pool_name)
			return null

## 将实例归还到对象池
func return_to_pool(instance: Node, pool_name: String) -> void:
	if not instance:
		push_warning("ResourceManager: 尝试归还空实例到对象池 '%s'" % pool_name)
		return

	if pool_name in object_pools:
		# 从父节点移除
		if instance.get_parent():
			instance.get_parent().remove_child(instance)

		# 隐藏并归还
		instance.visible = false
		instance.position = Vector2.ZERO
		object_pools[pool_name].push_back(instance)
	else:
		push_warning("ResourceManager: 未知的对象池 '%s'，释放实例" % pool_name)
		instance.queue_free()

## 加载资源（带缓存）
func load_resource(path: String) -> Resource:
	if path in resource_cache:
		return resource_cache[path]

	var resource = load(path)
	if resource:
		resource_cache[path] = resource
		return resource
	else:
		push_error("ResourceManager: 无法加载资源 '%s'" % path)
		return null

## 异步加载资源
func load_resource_async(path: String) -> Resource:
	if path in resource_cache:
		return resource_cache[path]

	# 使用ResourceLoader进行异步加载
	ResourceLoader.load_threaded_request(path)

	while true:
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			resource_cache[path] = resource
			return resource
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("ResourceManager: 异步加载失败 '%s'" % path)
			return null
		await get_tree().process_frame

	return null  # 理论上不会到达，但满足编译器要求

## 卸载资源
func unload_resource(path: String) -> void:
	if path in resource_cache:
		resource_cache.erase(path)
		print("ResourceManager: 已卸载资源 '%s'" % path)

## 清空资源缓存
func clear_cache() -> void:
	resource_cache.clear()
	print("ResourceManager: 已清空资源缓存")

## 获取对象池状态
func get_pool_status(pool_name: String) -> Dictionary:
	if pool_name in object_pools:
		return {
			"name": pool_name,
			"available": object_pools[pool_name].size(),
			"config": pool_configs[pool_name] if pool_name in pool_configs else {}
		}
	else:
		return {}

## 获取所有对象池状态
func get_all_pool_status() -> Array:
	var status_list = []
	for pool_name in object_pools:
		status_list.append(get_pool_status(pool_name))
	return status_list
