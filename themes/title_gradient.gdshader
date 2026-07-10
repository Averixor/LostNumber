shader_type canvas_item;

// Vertical 3-stop gradient for the game title.
// Web parity: css/ui.css .main-menu__title
// linear-gradient(135deg, #ffd9fb 0%, #ff80ee 42%, #b866ff 100%).

uniform vec4 color_top : source_color = vec4(1.0, 0.851, 0.984, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.502, 0.933, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.722, 0.4, 1.0, 1.0);
uniform float gradient_height = 64.0;
uniform float mid_point = 0.42;

varying float v_local_y;

void vertex() {
	v_local_y = VERTEX.y;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = clamp(v_local_y / max(gradient_height, 1.0), 0.0, 1.0);
	float t1 = clamp(t / max(mid_point, 0.001), 0.0, 1.0);
	float t2 = clamp((t - mid_point) / max(1.0 - mid_point, 0.001), 0.0, 1.0);
	vec3 grad = mix(mix(color_top.rgb, color_mid.rgb, t1), color_bottom.rgb, t2);
	COLOR = vec4(grad, tex.a * COLOR.a);
}
