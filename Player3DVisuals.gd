extends Node3D

@onready var body = $body_Rigged
var animation_player: AnimationPlayer = null

# Animation names mapping
var anim_map = {
	"Idle": ["Standing Idle", "Standing Idel", "Idle", "stand", "mixamo.com"], 
	"Run": ["Standard Run", "Fast Run", "Run", "run", "Walk"]
}

const RUNNING_PATH = "res://assets/characters/Standard Run.fbx"

func _ready():
	# Apply Toon Shading
	_apply_toon_shading(body)

	# Find the internal AnimationPlayer inside the instanced scene
	animation_player = _find_animation_player(body)
	
	if animation_player:
		# Dynamically load Standard Run if not present
		_add_external_animation(RUNNING_PATH, "Standard Run")
		
		var all_anims = animation_player.get_animation_list()
		# Set loop mode for ALL animations
		for anim_name in all_anims:
			var anim = animation_player.get_animation(anim_name)
			anim.loop_mode = Animation.LOOP_LINEAR
		
		play_animation("Idle")

func _add_external_animation(path: String, target_name: String):
	var resource = load(path)
	if not resource: return
	
	var anim: Animation = null
	if resource is PackedScene:
		var instance = resource.instantiate()
		var p = _find_animation_player(instance)
		if p and p.get_animation_list().size() > 0:
			var name = p.get_animation_list()[0]
			for n in p.get_animation_list():
				if "mixamo" in n.to_lower():
					name = n
					break
			anim = p.get_animation(name).duplicate()
		instance.free()
	elif resource is AnimationLibrary:
		var list = resource.get_animation_list()
		if list.size() > 0:
			anim = resource.get_animation(list[0]).duplicate()
	
	if anim:
		var lib: AnimationLibrary
		if animation_player.has_animation_library(""):
			lib = animation_player.get_animation_library("")
		else:
			lib = AnimationLibrary.new()
			animation_player.add_animation_library("", lib)
		
		var unique_name = target_name + "_loaded"
		if not lib.has_animation(unique_name):
			lib.add_animation(unique_name, anim)

func _apply_toon_shading(node: Node):
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var mat = mesh.surface_get_material(i)
				if not mat:
					mat = node.get_active_material(i)
				
				if mat and mat is StandardMaterial3D:
					# Anime Style: Toon Shading (Volume)
					mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
					mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
					mat.albedo_color = Color(1, 1, 1, 1)
					mat.roughness = 1.0
					mat.emission_enabled = false
					
					# Create Outline Pass
					var outline_mat = StandardMaterial3D.new()
					outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
					outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					outline_mat.albedo_color = Color(0.15, 0.1, 0.1, 1)
					outline_mat.grow = true
					outline_mat.grow_amount = 0.0008 
					mat.next_pass = outline_mat
					
	for child in node.get_children():
		_apply_toon_shading(child)

func _process(_delta):
	pass

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func play_animation(state_name: String):
	if not animation_player: return
	
	var target_anim = ""
	var available_anims = animation_player.get_animation_list()
	
	if state_name in anim_map:
		for candidate in anim_map[state_name]:
			for real_anim_name in available_anims:
				if candidate.to_lower() in real_anim_name.to_lower() and "mixamo" in real_anim_name.to_lower():
					target_anim = real_anim_name
					break
			if target_anim != "": break
			
			for real_anim_name in available_anims:
				if candidate.to_lower() in real_anim_name.to_lower():
					target_anim = real_anim_name
					break
			if target_anim != "": break
	
	if target_anim != "":
		if animation_player.current_animation != target_anim or not animation_player.is_playing():
			if not animation_player.active: animation_player.active = true
			animation_player.play(target_anim, 0.2)
	else:
		if animation_player.has_animation(state_name):
			if animation_player.current_animation != state_name or not animation_player.is_playing():
				animation_player.play(state_name)

func set_orientation(direction: Vector2):
	if direction.length() > 0.1:
		var angle = atan2(direction.x, direction.y)
		rotation.y = angle
