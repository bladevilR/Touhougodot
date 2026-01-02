extends Node
## 服务定位器 - 统一管理全局服务的注册和获取
## 替代 get_tree().get_nodes_in_group() 的低效查询方式
##
## 使用示例:
##   # 注册服务
##   ServiceLocator.register_service("map_system", map_system)
##
##   # 获取服务
##   var map_system = ServiceLocator.get_service("map_system")

# 服务存储字典
var _services: Dictionary = {}

## 注册一个全局服务
func register_service(service_name: String, service: Node) -> void:
	if service_name in _services:
		push_warning("ServiceLocator: 服务 '%s' 已存在，将被覆盖" % service_name)
	_services[service_name] = service
	print("ServiceLocator: 已注册服务 '%s'" % service_name)

## 获取一个已注册的服务
## 如果服务不存在，返回 null
func get_service(service_name: String) -> Node:
	if service_name in _services:
		return _services[service_name]
	else:
		push_warning("ServiceLocator: 服务 '%s' 未找到" % service_name)
		return null

## 检查服务是否已注册
func has_service(service_name: String) -> bool:
	return service_name in _services

## 注销一个服务
func unregister_service(service_name: String) -> void:
	if service_name in _services:
		_services.erase(service_name)
		print("ServiceLocator: 已注销服务 '%s'" % service_name)
	else:
		push_warning("ServiceLocator: 尝试注销不存在的服务 '%s'" % service_name)

## 清空所有服务（通常在场景切换时使用）
func clear_all_services() -> void:
	_services.clear()
	print("ServiceLocator: 已清空所有服务")

## 获取所有已注册的服务名称列表
func get_service_names() -> Array:
	return _services.keys()
