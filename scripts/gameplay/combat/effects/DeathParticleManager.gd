extends Node2D

# DeathParticleManager - 管理敌人死亡粒子效果
# 原项目实现：GameCanvas.tsx line 546-603 (pixi-particles)

# 预加载粒子场景
var particle_scene = preload("res://DeathParticle.tscn")

# 粒子对象池（性能优化）
var particle_pool: Array = []
const MAX_PARTICLES: int = 100

func _ready():
	# 监听粒子生成信号
	SignalBus.spawn_death_particles.connect(_on_spawn_death_particles)

func _on_spawn_death_particles(pos: Vector2, color: Color, count: int):
	"""生成死亡粒子效果
	pos: 生成位置
	color: 粒子颜色
	count: 粒子数量
	"""
	for i in range(count):
		var particle = _get_particle_from_pool()
		if not particle:
			continue

		# 设置粒子属性
		particle.global_position = pos
		particle.modulate = color

		# 随机速度和方向
		var angle = randf() * TAU
		var speed = randf_range(200.0, 400.0)
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		# 启动粒子
		particle.start_particle(velocity, randf_range(0.3, 0.8))

func _get_particle_from_pool() -> Node2D:
	"""从对象池获取粒子"""
	# 查找未激活的粒子
	for particle in particle_pool:
		if is_instance_valid(particle) and not particle.is_active:
			return particle

	# 对象池已满，跳过
	if particle_pool.size() >= MAX_PARTICLES:
		return null

	# 创建新粒子
	var particle = particle_scene.instantiate()
	add_child(particle)
	particle_pool.append(particle)
	return particle
