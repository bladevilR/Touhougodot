shader_type canvas_item;

// 简化版阴影测试 - 验证CanvasGroup是否工作

uniform vec2 shadow_offset = vec2(12.0, 8.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);

void fragment() {
	// 获取原始颜色
	vec4 original = texture(TEXTURE, UV);

	// 计算阴影位置
	vec2 shadow_uv = UV + shadow_offset * TEXTURE_PIXEL_SIZE;
	vec4 shadow_sample = texture(TEXTURE, shadow_uv);

	// 创建阴影
	vec4 shadow = shadow_color;
	shadow.a *= shadow_sample.a;

	// 混合：先绘制阴影，再绘制原始图像
	vec4 result = vec4(0.0);

	// 如果在阴影位置有alpha，绘制阴影
	if (shadow.a > 0.0 && original.a < 0.1) {
		result = shadow;
	} else {
		result = original;
	}

	// 如果原始位置有内容，覆盖阴影
	if (original.a > 0.0) {
		result = original;
	}

	COLOR = result;
}
