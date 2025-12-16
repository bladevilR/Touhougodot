extends Control

# LoadingScreen.gd - 加载界面
# 播放视频并异步加载游戏场景

@onready var video_player = $VideoStreamPlayer
@onready var progress_bar = $ProgressBar
@onready var status_label = $StatusLabel

var target_scene_path = "res://world.tscn"
var loading_status = 0
var progress = []
var visual_progress: float = 0.0

func _ready():
	# 简化视频播放器布局，避免拉伸问题
	if video_player:
		# 尝试加载视频
		var video_path = "res://assets/1.ogv"
		if not ResourceLoader.exists(video_path):
			video_path = "res://assets/wait.mp4"

		if ResourceLoader.exists(video_path):
			print("LoadingScreen: 找到视频文件 ", video_path)
			var video_stream = load(video_path)
			video_player.stream = video_stream

			# 保持原始尺寸，不拉伸
			video_player.expand = false

			# 缩放到合适大小
			video_player.scale = Vector2(0.35, 0.35)

			# 定位到右下角
			video_player.position = Vector2(
				get_viewport_rect().size.x - 600,
				get_viewport_rect().size.y - 400
			)

			video_player.play()
			# 循环播放
			video_player.finished.connect(func():
				if video_player and is_instance_valid(video_player):
					video_player.play()
			)
		else:
			print("LoadingScreen: 找不到 1.ogv 或 wait.mp4")

	# 开始异步加载
	ResourceLoader.load_threaded_request(target_scene_path)
	print("LoadingScreen: 开始加载 ", target_scene_path)

func _process(delta):
	# 获取加载状态
	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	var real_progress = 0.0
	if progress.size() > 0:
		real_progress = progress[0]

	# 检查加载是否完成
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		# 加载完成，立即跳到100%，避免卡顿
		visual_progress = 1.0
		_on_load_complete()
		return
	elif loading_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("LoadingScreen: 加载失败！")
		status_label.text = "加载失败！请重启游戏。"
		set_process(false)
		return

	# 平滑插值：让显示进度快速追赶真实进度
	if visual_progress < real_progress:
		visual_progress = move_toward(visual_progress, real_progress, delta * 1.5) # 加快追赶速度

	# 假进度：如果卡住了，也稍微动一点点，安抚玩家
	if visual_progress < 0.95:  # 只在95%之前才假进度
		visual_progress += delta * 0.08 # 稍微加快假进度

	# 限制范围
	visual_progress = clamp(visual_progress, 0.0, 0.99) # 限制在99%，等待真实加载完成

	# 更新UI
	if progress_bar:
		progress_bar.value = visual_progress * 100
		status_label.text = "Loading... %d%%" % int(visual_progress * 100)

func _on_load_complete():
	print("LoadingScreen: 加载完成")
	set_process(false)
	
	# 获取加载的资源
	var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	# 稍微延迟一下，让玩家看完至少几秒视频（可选）
	# await get_tree().create_timer(1.0).timeout
	
	# 切换场景
	get_tree().change_scene_to_packed(new_scene)