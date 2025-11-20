shader_type canvas_item;

uniform float intensity : hint_range(0.0, 0.6) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.4, 0.9, dist);
    COLOR = vec4(1.0, 0.0, 0.0, vignette * intensity);
}