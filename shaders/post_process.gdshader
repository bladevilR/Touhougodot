shader_type canvas_item;

// 后处理效果 Shader - 辉光 + 色调映射
// 用于全屏 ColorRect 实现电影级画面效果

// 辉光参数
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float glow_blur_size : hint_range(1.0, 10.0) = 3.0;

// 色调映射参数
uniform int tonemap_mode : hint_range(0, 2) = 1;  // 0=Linear, 1=ACES, 2=Filmic
uniform float exposure : hint_range(0.1, 3.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.1;

// 暗角参数
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.5;

// 色彩调整
uniform vec3 color_tint : source_color = vec3(1.0, 0.98, 0.95);  // 暖色调
uniform float color_temperature : hint_range(-1.0, 1.0) = 0.1;   // 正=暖, 负=冷

// 屏幕纹理
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// ACES 色调映射
vec3 aces_tonemap(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// Filmic 色调映射
vec3 filmic_tonemap(vec3 color) {
    vec3 x = max(vec3(0.0), color - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

// 简单的模糊采样（用于辉光）
vec3 blur_sample(sampler2D tex, vec2 uv, vec2 pixel_size) {
    vec3 color = vec3(0.0);
    float total_weight = 0.0;

    // 9-tap 高斯模糊
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size * glow_blur_size;
            float weight = 1.0 - length(vec2(float(x), float(y))) * 0.3;
            color += texture(tex, uv + offset).rgb * weight;
            total_weight += weight;
        }
    }

    return color / total_weight;
}

// 提取高亮区域
vec3 extract_bright(vec3 color) {
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float contribution = max(0.0, brightness - glow_threshold);
    return color * contribution;
}

// 调整饱和度
vec3 adjust_saturation(vec3 color, float sat) {
    float grey = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(grey), color, sat);
}

// 调整色温
vec3 adjust_temperature(vec3 color, float temp) {
    // 正值变暖（增加红色，减少蓝色）
    // 负值变冷（增加蓝色，减少红色）
    color.r += temp * 0.1;
    color.b -= temp * 0.1;
    return color;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    // 使用 SCREEN_PIXEL_SIZE 代替 textureSize
    vec2 pixel_size = SCREEN_PIXEL_SIZE;

    // 获取原始颜色
    vec3 original = texture(screen_texture, uv).rgb;

    // === 辉光效果 ===
    vec3 blur = blur_sample(screen_texture, uv, pixel_size);
    vec3 bright = extract_bright(blur);
    vec3 glow = bright * glow_intensity;

    // 合并辉光
    vec3 color = original + glow;

    // === 曝光调整 ===
    color *= exposure;

    // === 色调映射 ===
    if (tonemap_mode == 1) {
        color = aces_tonemap(color);
    } else if (tonemap_mode == 2) {
        color = filmic_tonemap(color);
    }
    // mode 0 = Linear，不处理

    // === 对比度调整 ===
    color = (color - 0.5) * contrast + 0.5;

    // === 饱和度调整 ===
    color = adjust_saturation(color, saturation);

    // === 色温调整 ===
    color = adjust_temperature(color, color_temperature);

    // === 颜色色调 ===
    color *= color_tint;

    // === 暗角效果 ===
    vec2 center_uv = uv - 0.5;
    float vignette = 1.0 - dot(center_uv, center_uv) * vignette_intensity;
    vignette = smoothstep(0.0, vignette_smoothness + 0.5, vignette);
    color *= vignette;

    // 确保颜色在有效范围内
    color = clamp(color, 0.0, 1.0);

    COLOR = vec4(color, 1.0);
}
