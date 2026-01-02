extends CanvasLayer

# UIManager - 全局UI管理器
# 负责在所有场景之上显示HUD和菜单

var game_ui_instance: CanvasLayer = null
var current_ui_path: String = "res://GameUI.tscn"

func _ready():
	# 设置层级最高，确保覆盖在所有场景之上
	layer = 100
	
	# 监听场景切换，自动加载或卸载UI
	# 但目前为了简单，我们手动控制或默认加载
	pass

func show_game_ui():
	"""显示游戏主UI (HUD)"""
	if not game_ui_instance:
		var scene = load(current_ui_path)
		if scene:
			game_ui_instance = scene.instantiate()
			add_child(game_ui_instance)
			print("[UIManager] GameUI 加载成功")
		else:
			print("[UIManager] 错误: 无法加载 GameUI.tscn")
			return
	
	game_ui_instance.visible = true

func hide_game_ui():
	"""隐藏游戏主UI"""
	if game_ui_instance:
		game_ui_instance.visible = false

func toggle_game_ui(show: bool):
	if show:
		show_game_ui()
	else:
		hide_game_ui()

func set_ui_minimal(enabled: bool):
	"""设置UI是否为简洁模式"""
	if not game_ui_instance:
		show_game_ui()
	
	if game_ui_instance and game_ui_instance.has_method("set_minimal_mode"):
		game_ui_instance.set_minimal_mode(enabled)
