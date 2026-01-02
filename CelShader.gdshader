shader_type spatial;
render_mode unshaded; // 手动计算光照以实现卡通效果

uniform sampler2D albedo_texture : source_color;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width = 2.0;

void vertex() {
	// 简单的顶点膨胀描边 (在背面剔除Pass中绘制，这里仅作为基础Pass)
	// Godot 的 Next Pass 描边更适合，这里先做基础色
}

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb;
}

// 注意：Godot 4 的标准卡通渲染通常需要两个 Pass：
// 1. 描边 Pass (Cull Front, Vertex Expand)
// 2. 着色 Pass (Diffuse Toon)
// 为了简单且不破坏原有材质的属性，我们将使用 StandardMaterial3D 的 Next Pass 功能来实现描边，
// 并调整 Diffuse Mode 为 Toon。
