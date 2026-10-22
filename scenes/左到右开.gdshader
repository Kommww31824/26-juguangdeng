shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec3 current_rgb = texture(TEXTURE, UV).rgb;
    float current_a = texture(TEXTURE, UV).a;
    float step_a = step(UV.x, progress);
    COLOR.a = min(current_a, step_a);
}