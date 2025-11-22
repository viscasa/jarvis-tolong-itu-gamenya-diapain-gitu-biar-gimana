shader_type canvas_item;

uniform float circle_size : hint_range(0.0, 2) = 1.0;
uniform vec2 circle_position = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 center = circle_position;
	
	// Adjust for aspect ratio
	vec2 diff = uv - center;
	diff.x *= aspect;
	
	float dist = length(diff);
	float circle = smoothstep(circle_size - 0.01, circle_size, dist);
	
	COLOR = vec4(0.0, 0.0, 0.0, circle);
}