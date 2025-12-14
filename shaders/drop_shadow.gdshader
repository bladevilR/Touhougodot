shader_type canvas_item;

// ==================== 2.5D Drop Shadow Shader ====================
// 高质量投射阴影 - 适合俯视角游戏
// 性能优异，效果接近《空洞骑士》

// 阴影参数
uniform vec2 shadow_offset = vec2(12.0, 8.0);  // 阴影偏移（右下方，模拟午后阳光）
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);  // 阴影颜色
uniform float shadow_softness = 3.0;  // 阴影柔和度
uniform float shadow_scale = 0.6;  // 阴影Y轴缩放（扁平化）

// 柔光参数
uniform bool enable_glow = true;  // 是否启用光晕
uniform float glow_intensity = 0.15;  // 发光强度
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);  // 暖色光晕
uniform float glow_radius = 8.0;  // 光晕半径

// 简化的高斯模糊（3x3）
vec4 blur_texture(sampler2D tex, vec2 uv, vec2 pixel_size, float radius) {
	vec4 result = vec4(0.0);
	float total_weight = 0.0;

	// 3x3采样核心
	for (float x = -1.0; x <= 1.0; x += 1.0) {
		for (float y = -1.0; y <= 1.0; y += 1.0) {
			vec2 offset = vec2(x, y) * radius * pixel_size;
			float weight = 1.0 - (abs(x) + abs(y)) * 0.25;
			result += texture(tex, uv + offset) * weight;
			total_weight += weight;
		}
	}

	return result / total_weight;
}

void fragment() {
	// 原始颜色
	vec4 original = texture(TEXTURE, UV);

	// 计算阴影UV（带倾斜和偏移）
	vec2 shadow_uv = UV;
	// Y轴缩放（让影子扁平化，模拟投射在地面）
	shadow_uv.y = (shadow_uv.y - 0.5) * shadow_scale + 0.5;
	// 偏移
	shadow_uv += shadow_offset * TEXTURE_PIXEL_SIZE;

	// 采样并模糊阴影
	vec4 shadow_sample = blur_texture(TEXTURE, shadow_uv, TEXTURE_PIXEL_SIZE, shadow_softness);

	// 创建阴影
	vec4 shadow = shadow_color;
	shadow.a *= shadow_sample.a;

	// 柔光效果（可选）
	vec4 glow = vec4(0.0);
	if (enable_glow) {
		// 环形采样计算光晕
		float glow_alpha = 0.0;
		const int SAMPLES = 8;

		for (int i = 0; i < SAMPLES; i++) {
			float angle = float(i) * 6.28318 / float(SAMPLES);  // 2*PI
			vec2 dir = vec2(cos(angle), sin(angle));
			vec2 glow_uv = UV + dir * glow_radius * TEXTURE_PIXEL_SIZE;
			glow_alpha += texture(TEXTURE, glow_uv).a;
		}

		glow_alpha /= float(SAMPLES);
		glow = glow_color * glow_intensity * glow_alpha;
	}

	// 最终混合
	vec4 result = original;

	// 先绘制阴影（在物体下方）
	result.rgb = mix(shadow.rgb, result.rgb, result.a);
	result.a = max(result.a, shadow.a);

	// 叠加光晕（加法混合）
	if (enable_glow) {
		result.rgb += glow.rgb * glow.a * (1.0 - original.a);
	}

	COLOR = result;
}
