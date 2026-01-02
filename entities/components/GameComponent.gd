extends Node
## 游戏组件基类 - 所有组件的基类
##
## 职责:
## - 定义统一的组件接口
## - 管理组件的启用/禁用状态
## - 提供生命周期回调方法
##
## 使用说明:
##   所有自定义组件都应继承此基类
##   重写 _on_entity_ready() 和 _on_entity_process(delta) 方法

class_name GameComponent

# 组件所属的实体（通常是Player或Enemy）
var entity: Node2D = null

# 组件是否启用
var enabled: bool = true

## 实体准备完成时调用
## 子类应重写此方法进行初始化
func _on_entity_ready() -> void:
	pass

## 每帧处理时调用
## 子类应重写此方法进行更新逻辑
## @param delta: 帧时间间隔
func _on_entity_process(delta: float) -> void:
	pass

## 物理帧处理时调用
## 子类可选择重写此方法进行物理更新
## @param delta: 物理帧时间间隔
func _on_entity_physics_process(delta: float) -> void:
	pass

## 启用组件
func enable() -> void:
	enabled = true

## 禁用组件
func disable() -> void:
	enabled = false

## 切换组件启用状态
func toggle() -> void:
	enabled = not enabled

## 获取组件类型名称（用于调试）
func get_component_type() -> String:
	return get_script().resource_path.get_file().get_basename()

## 清理组件资源
## 子类应重写此方法清理自己的资源
func cleanup() -> void:
	pass
