shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 VIEWPORT_SIZE;

// ===== 全局强度：0=正常，1=重度反胃/中毒 =====
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// ===== 反胃/眩晕：速度与旋转 =====
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float rotate_amt : hint_range(0.0, 0.2) = 0.03;

// ===== 空间扭曲强度 =====
uniform float wave_x : hint_range(0.0, 0.2) = 0.025;
uniform float wave_y : hint_range(0.0, 0.2) = 0.02;

// ===== RGB 分离（色差）=====
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.0;

// ===== 中毒配色 =====
uniform vec4 poison_tint : source_color = vec4(0.45, 0.95, 0.35, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.35;
uniform float desat : hint_range(0.0, 1.0) = 0.25;
uniform float grain : hint_range(0.0, 0.2) = 0.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.5;

// ===== 黄色泡泡 =====
uniform vec4 bubble_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float bubble_amount : hint_range(0.0, 1.0) = 0.0;
uniform float bubble_size : hint_range(0.0, 1.0) = 0.35;
uniform float bubble_count : hint_range(1.0, 8.0) = 4.0;
uniform float bubble_speed : hint_range(0.0, 0.3) = 0.05;

// ===== 泡泡形变强度 =====
uniform float bubble_deform : hint_range(0.0, 1.0) = 1.0;
uniform float bubble_stretch : hint_range(0.0, 1.0) = 0.4;
uniform float bubble_bend : hint_range(0.0, 1.0) = 0.3;

// ===== 泡泡圆环挖空 =====
uniform float bubble_hollow : hint_range(0.0, 1.0) = 0.5;

// ===== 泡泡蓝色模糊边缘 =====
uniform vec4 bubble_edge_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float bubble_edge_amount : hint_range(0.0, 1.0) = 0.5;

// 随机函数，用于颗粒噪声
float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 画一个柔边的、可挖空成圆环的泡泡，带蓝色模糊边缘（返回 vec2: 黄, 蓝）
vec2 bubble(vec2 center, float size, vec2 uv, float phase) {
    vec2 delta = uv - center;
    float d = length(delta);
    float a = atan(delta.y, delta.x);

    // 形变幅度
    float m1 = bubble_stretch * bubble_deform * (0.6 + 0.4 * sin(TIME * 1.2 + phase));
    float m2 = bubble_bend    * bubble_deform * (0.6 + 0.4 * cos(TIME * 1.0 + phase));

    float radius = size * (1.0 + m1 * cos(2.0 * a + phase)
                               + m2 * cos(3.0 * a - phase * 1.3));
    radius = max(radius, size * 0.6);

    // ---- 空心圆环（bubble_hollow=0 实心，1 细环）----
    float inner = radius * (0.0 + 0.75 * bubble_hollow);
    float outer_edge = 1.0 - smoothstep(radius * 0.7, radius, d);
    float inner_edge = smoothstep(inner, inner + radius * 0.25, d);
    float ring = outer_edge * inner_edge;

    // ---- 蓝色模糊边缘：比外圈更大、更虚 ----
    float blue_edge = 1.0 - smoothstep(radius * 0.5, radius * 1.6, d);
    blue_edge = clamp(blue_edge - ring, 0.0, 1.0) * bubble_edge_amount;

    float breath = 0.5 + 0.5 * sin(TIME * 2.0 + phase);
    return vec2(ring * breath, blue_edge * breath);
}

void fragment() {
    vec2 uv = SCREEN_UV - 0.5;

    // ---- 1. 整体微旋转（"天旋地转"）----
    float ang = sin(TIME * speed * 0.7) * rotate_amt * intensity;
    float s = sin(ang);
    float co = cos(ang);
    uv = mat2(vec2(co, s), vec2(-s, co)) * uv;

    // ---- 2. 双轴正弦平移（画面漂移）----
    uv.x += sin(TIME * speed * 1.3) * 0.012 * intensity;
    uv.y += cos(TIME * speed * 1.1) * 0.012 * intensity;

    // ---- 3. 桶形抖动（边缘更晕）----
    float r = length(uv);
    uv += normalize(uv + 1e-5) * sin(TIME * speed + r * 10.0) * 0.004 * intensity;

    vec2 final_uv = uv + 0.5;

    // ---- 3.5 空间扭曲（波纹拉扯）----
    float wave = sin(final_uv.y * 16.0 + TIME * speed * 2.0) * wave_x
               + sin(final_uv.x * 12.0 - TIME * speed * 1.6) * wave_y;
    final_uv.x += wave * intensity;
    final_uv.y += cos(final_uv.x * 10.0 + TIME * speed * 1.3) * wave_y * intensity;

    // ---- 3.7 RGB 分离（色差：三通道不同偏移）----
    float ca = chromatic_aberration * intensity;
    vec3 col;
    col.r = texture(screen_tex, final_uv + vec2(ca, 0.0)).r;
    col.g = texture(screen_tex, final_uv).g;
    col.b = texture(screen_tex, final_uv - vec2(ca, 0.0)).b;

    // ---- 4. 降饱和 ----
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(l), desat * intensity);

    // ---- 5. 绿毒偏色 ----
    col = mix(col, col * poison_tint.rgb * 1.6, tint_amount * intensity);

    // ---- 6. 颗粒噪点 ----
    float n = rand(SCREEN_UV * VIEWPORT_SIZE + TIME) - 0.5;
    col += n * grain * intensity;

    // ---- 7. 暗角（头重脚轻感）----
    float d = distance(SCREEN_UV, vec2(0.5));
    col *= 1.0 - smoothstep(0.4, 0.75, d) * vignette * intensity;

    // ---- 8. 黄色泡泡（带蓝色模糊边缘，空心圆环）----
    if (bubble_amount > 0.0) {
        float bubbles = 0.0;
        float blue_bubbles = 0.0;
        for (int i = 0; i < 8; i++) {
            if (float(i) >= bubble_count) break;
            float fi = float(i);
            float px = fract(sin(fi * 12.9898) * 43758.5453);
            float py = fract(sin(fi * 78.233 + 3.7) * 43758.5453);
            float sx = sin(TIME * bubble_speed + fi * 1.7) * 0.15;
            float sy = cos(TIME * bubble_speed * 0.8 + fi * 2.3) * 0.15;
            vec2 center = vec2(px + sx, py + sy);
            float phase = fi * 1.13 + sin(fi * 2.7);
            vec2 b = bubble(center, bubble_size, SCREEN_UV, phase);
            bubbles += b.x;
            blue_bubbles += b.y;
        }
        bubbles = clamp(bubbles, 0.0, 1.0) * bubble_amount;
        blue_bubbles = clamp(blue_bubbles, 0.0, 1.0) * bubble_amount;

        col += bubble_color.rgb * bubbles * 0.6;
        col += bubble_edge_color.rgb * blue_bubbles * 0.5;
    }

    COLOR = vec4(col, 1.0);
}