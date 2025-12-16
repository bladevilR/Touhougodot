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
	# 优化视频播放器布局
	if video_player:
		video_player.expand = false # 禁止拉伸，保持原始比例
		# 缩放视频（假设原视频较大，缩放到0.4倍）
		var scale_factor = 0.4
		video_player.scale = Vector2(scale_factor, scale_factor)
		
		# 尝试加载视频以获取尺寸
		var video_path = "res://assets/1.ogv"
		if not ResourceLoader.exists(video_path):
			video_path = "res://assets/wait.mp4"
			
		if ResourceLoader.exists(video_path):
			print("LoadingScreen: 找到视频文件 ", video_path)
			var video_stream = load(video_path)
			video_player.stream = video_stream
			
			# 重置尺寸，让它自然撑开，避免黑边
			video_player.size = Vector2.ZERO
			video_player.custom_minimum_size = Vector2.ZERO
			
			# 简单的右下角定位逻辑（基于大致估算）
			# 注意：由于expand=false，size可能不准确，这里我们根据 scale 估算一个偏移
			video_player.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			video_player.position = Vector2(get_viewport_rect().size.x - 700, get_viewport_rect().size.y - 500)
			
			video_player.play()
			# 循环播放
			video_player.finished.connect(func(): video_player.play())
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
		
	# 平滑插值：让显示进度慢慢追赶真实进度
	if visual_progress < real_progress:
		visual_progress = move_toward(visual_progress, real_progress, delta * 0.5) # 追赶速度
	
	# 假进度：如果卡住了，也稍微动一点点，安抚玩家
	if visual_progress < 0.9:
		visual_progress += delta * 0.05 # 极慢自增
		
	# 限制范围
	if visual_progress > 1.0: visual_progress = 1.0
	
	# 更新UI
	if progress_bar:
		progress_bar.value = visual_progress * 100
		status_label.text = "Loading... %d%%" % int(visual_progress * 100)

	# 检查加载是否完成
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		# 只有当视觉进度也跑满了才切换，或者如果加载极快，直接跳过
		if visual_progress >= 0.99:
			_on_load_complete()
		else:
			# 加速追赶
			visual_progress = move_toward(visual_progress, 1.0, delta * 2.0)
			
	elif loading_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("LoadingScreen: 加载失败！")
		status_label.text = "加载失败！请重启游戏。"
		set_process(false)

func _on_load_complete():
	print("LoadingScreen: 加载完成")
	set_process(false)
	
	# 获取加载的资源
	var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	# 稍微延迟一下，让玩家看完至少几秒视频（可选）
	# await get_tree().create_timer(1.0).timeout
	
	# 切换场景
	get_tree().change_scene_to_packed(new_scene)