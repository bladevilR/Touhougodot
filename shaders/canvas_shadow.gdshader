shader_type canvas_item;

// ==================== SDF Drop Shadow Shader ====================
// 高质量投射阴影效果，类似《空洞骑士》的柔光
// 使用 CanvasGroup 的 screen_texture 和 SDF 数据

// 阴影参数
uniform vec2 shadow_offset = vec2(8.0, 8.0);  // 阴影偏移（斜向右下模拟午后阳光）
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);  // 阴影颜色
uniform float shadow_blur = 8.0;  // 阴影模糊半径
uniform float shadow_distance = 16.0;  // 阴影最大距离

// 柔光参数
uniform float glow_intensity = 0.3;  // 发光强度
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);  // 暖色光晕
uniform float glow_radius = 12.0;  // 光晕半径

// 采样函数：计算SDF距离场
float sample_sdf(sampler2D tex, vec2 uv) {
	vec4 color = texture(tex, uv);
	// 使用alpha通道作为距离场
	return color.a;
}

// 高斯模糊采样（优化版）
float soft_shadow(sampler2D tex, vec2 uv, vec2 pixel_size) {
	float shadow = 0.0;
	float total_weight = 0.0;

	// 使用泊松圆盘采样模拟柔和阴影
	const int SAMPLES = 12;
	vec2 poisson[12] = vec2[](
		vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457),
		vec2(-0.203, 0.621), vec2(0.962, -0.195), vec2(0.473, -0.480),
		vec2(0.519, 0.767), vec2(0.185, -0.893), vec2(0.507, 0.064),
		vec2(0.896, 0.412), vec2(-0.321, -0.932), vec2(-0.791, -0.598)
	);

	for (int i = 0; i < SAMPLES; i++) {
		vec2 offset = poisson[i] * shadow_blur * pixel_size;
		float dist = sample_sdf(tex, uv + offset);
		float weight = 1.0 - length(poisson[i]);
		shadow += dist * weight;
		total_weight += weight;
	}

	return shadow / total_weight;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel_size = SCREEN_PIXEL_SIZE;

	// 原始颜色
	vec4 original = texture(TEXTURE, UV);

	// 计算阴影UV（偏移）
	vec2 shadow_uv = uv + shadow_offset * pixel_size;

	// 采样柔和阴影
	float shadow_alpha = soft_shadow(TEXTURE, shadow_uv, pixel_size);

	// 距离衰减
	float dist = length(shadow_offset * pixel_size);
	float falloff = smoothstep(shadow_distance * pixel_size.x, 0.0, dist);
	shadow_alpha *= falloff;

	// 混合阴影
	vec4 shadow = shadow_color;
	shadow.a *= shadow_alpha;

	// 计算柔光（周围的光晕效果）
	float glow_dist = length(vec2(0.0));
	float glow_alpha = 0.0;

	// 环形采样计算光晕
	const int GLOW_SAMPLES = 8;
	for (int i = 0; i < GLOW_SAMPLES; i++) {
		float angle = float(i) * 3.14159 * 2.0 / float(GLOW_SAMPLES);
		vec2 dir = vec2(cos(angle), sin(angle));
		vec2 glow_uv = uv + dir * glow_radius * pixel_size;
		glow_alpha += sample_sdf(TEXTURE, glow_uv);
	}
	glow_alpha /= float(GLOW_SAMPLES);

	// 应用光晕
	vec4 glow = glow_color * glow_intensity * glow_alpha;

	// 最终混合：原始颜色 + 阴影 + 光晕
	vec4 result = original;

	// 先绘制阴影（在下层）
	result = mix(shadow, result, result.a);

	// 再叠加光晕（加法混合）
	result.rgb += glow.rgb * (1.0 - result.a);

	COLOR = result;
}
