shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec3 main_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : hint_default_white;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float rim_power : hint_range(1.0, 20.0) = 6.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec3 tex_color = texture(albedo_texture, UV).rgb;
    ALBEDO = main_color * tex_color;
}

void light() {
    // Toon硬阴影：2层（亮/暗）
    float NdotL = dot(NORMAL, LIGHT);
    float toon = smoothstep(shadow_threshold - 0.05, shadow_threshold + 0.05, NdotL);
    DIFFUSE_LIGHT = toon * ATTENUATION * LIGHT_COLOR;

    // 高光（柔和）
    vec3 half_vec = normalize(LIGHT + VIEW);
    float spec = pow(max(0.0, dot(NORMAL, half_vec)), 32.0);
    SPECULAR_LIGHT = spec * 0.4 * ATTENUATION * LIGHT_COLOR;

    // Rim光（动漫边缘发光）
    float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
    rim = smoothstep(0.6, 1.0, pow(rim, rim_power));
    DIFFUSE_LIGHT += rim * rim_intensity * LIGHT_COLOR;
}
