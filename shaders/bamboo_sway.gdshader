shader_type canvas_item;

// 竹子摇曳 Shader - 间歇性微风效果
// 大部分时间静止，偶尔一阵风吹过

// 风阵参数
uniform float wind_cycle : hint_range(5.0, 30.0) = 15.0;      // 风阵周期（秒）
uniform float wind_duration : hint_range(1.0, 5.0) = 3.0;     // 每阵风持续时间
uniform float sway_amount : hint_range(0.0, 30.0) = 12.0;     // 摇曳幅度（像素）
uniform float sway_speed : hint_range(1.0, 5.0) = 2.5;        // 摇曳速度
uniform float sway_phase : hint_range(0.0, 6.28) = 0.0;       // 相位偏移

// 碰撞摇晃（由代码控制）
uniform float impact_sway : hint_range(0.0, 50.0) = 0.0;      // 碰撞摇晃强度
uniform float impact_decay : hint_range(0.0, 1.0) = 0.0;      // 碰撞衰减进度

// 颜色调整
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.5, 1.5) = 1.0;

void vertex() {
    // 获取顶点的归一化高度 (0=底部, 1=顶部)
    float height_factor = 1.0 - UV.y;
    float sway_strength = height_factor * height_factor;

    // === 间歇性风阵 ===
    // 计算当前在风阵周期中的位置
    float cycle_pos = mod(TIME + sway_phase * 2.0, wind_cycle);

    // 风阵强度：只在周期开始的 wind_duration 秒内有风
    // 使用平滑的淡入淡出
    float wind_t = cycle_pos / wind_duration;
    float wind_strength = 0.0;
    if (wind_t < 1.0) {
        // 淡入淡出曲线：sin^2 让开始和结束都平滑
        wind_strength = sin(wind_t * 3.14159) * sin(wind_t * 3.14159);
    }

    // 风吹摇摆
    float wind_sway = sin(TIME * sway_speed + sway_phase) * sway_amount * wind_strength;

    // 次级摆动（更快的小幅度晃动）
    float secondary = sin(TIME * sway_speed * 2.5 + sway_phase * 1.7) * sway_amount * 0.3 * wind_strength;

    // === 碰撞摇晃 ===
    // 衰减的正弦波
    float impact = sin(TIME * 8.0 + sway_phase) * impact_sway * (1.0 - impact_decay);

    // 组合所有摇摆
    float total_sway = (wind_sway + secondary + impact) * sway_strength;

    // 应用偏移
    VERTEX.x += total_sway;
    VERTEX.y += abs(total_sway) * 0.015 * sway_strength;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = tex_color * tint_color * brightness;
}
