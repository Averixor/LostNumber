shader_type canvas_item;
render_mode unshaded;

uniform vec4 face_color : source_color = vec4(0.24, 0.55, 0.32, 0.94);


float rounded_box_distance(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}


void fragment() {
	vec2 uv = UV;
	float distance_to_face = rounded_box_distance(uv - vec2(0.5), vec2(0.49), 0.075);
	float face_mask = 1.0 - smoothstep(-0.006, 0.008, distance_to_face);
	float bevel = smoothstep(0.0, 0.075, -distance_to_face);

	float vertical_light = mix(1.20, 0.70, uv.y);
	float center_glow = pow(max(0.0, 1.0 - length((uv - vec2(0.46, 0.39)) * vec2(1.0, 1.25)) * 1.9), 2.0);
	float diagonal_sheen = pow(max(0.0, 1.0 - abs((uv.x + uv.y) - 0.68) * 5.5), 4.0);
	float top_glint = pow(max(0.0, 1.0 - uv.y * 7.0), 3.0);

	vec3 colour = face_color.rgb * vertical_light;
	vec3 highlight = mix(face_color.rgb, vec3(1.0), 0.72);
	colour += highlight * (center_glow * 0.12 + diagonal_sheen * 0.10 + top_glint * 0.15);
	colour *= mix(0.72, 1.0, bevel);

	float inner_rim = smoothstep(0.01, 0.025, -distance_to_face) * (1.0 - smoothstep(0.04, 0.07, -distance_to_face));
	colour += highlight * inner_rim * 0.18;
	COLOR = vec4(colour, face_color.a * face_mask);
}
