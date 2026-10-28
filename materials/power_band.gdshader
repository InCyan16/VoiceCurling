shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, unshaded, shadows_disabled;

uniform vec4 band_color : source_color = vec4(0.12, 0.95, 0.52, 0.5);
uniform vec4 rim_color : source_color = vec4(0.85, 1.0, 0.92, 0.85);
uniform sampler2D arrow_tex : filter_linear_mipmap, repeat_enable;
uniform float scroll_speed = 0.42;
uniform float scroll_direction = 1.0;
uniform float pulse_speed = 1.8;
uniform float pulse_strength = 0.28;

void fragment() {
	vec2 uv = UV;
	float pulse = 1.0 + pulse_strength * sin(TIME * pulse_speed);
	float pulse_fast = 0.9 + 0.1 * sin(TIME * pulse_speed * 2.6);
	float scroll = TIME * scroll_speed * scroll_direction;
	vec2 arrow_uv = vec2(uv.x, fract(uv.y * 1.35 + scroll));

	vec4 arrow_sample = texture(arrow_tex, arrow_uv);
	float arrow_mask = max(arrow_sample.r, max(arrow_sample.g, arrow_sample.b));

	float edge_x = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x);
	float edge_y = smoothstep(0.0, 0.1, uv.y) * smoothstep(1.0, 0.9, uv.y);
	float edge_mask = edge_x * edge_y;

	float border = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float rim = smoothstep(0.13, 0.0, border);
	float inner_glow = smoothstep(0.42, 0.0, border) * 0.55;

	float sweep_pos = fract(uv.y - TIME * scroll_speed * scroll_direction * 0.65);
	float sweep = smoothstep(0.14, 0.0, abs(sweep_pos - 0.5));

	vec3 body = band_color.rgb * (0.65 + arrow_mask * 1.25 + sweep * 0.45) * pulse;
	vec3 rim_glow = rim_color.rgb * rim * 1.35 * pulse;
	vec3 color = body + rim_glow + band_color.rgb * inner_glow * pulse_fast;
	color += rim_color.rgb * sweep * 0.35 * pulse;

	float alpha = band_color.a * edge_mask * (0.5 + arrow_mask * 0.65 + sweep * 0.25) * pulse;
	alpha = max(alpha, rim * rim_color.a * 0.95);

	ALBEDO = color;
	ALPHA = clamp(alpha, 0.0, 0.98);
}
