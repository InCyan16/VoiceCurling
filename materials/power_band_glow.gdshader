shader_type spatial;
render_mode blend_add, depth_draw_always, cull_disabled, unshaded, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(0.2, 1.0, 0.55, 0.65);
uniform float pulse_speed = 2.2;
uniform float pulse_strength = 0.35;
uniform float sweep_speed = 0.55;
uniform float sweep_direction = 1.0;

void fragment() {
	vec2 uv = UV;
	float pulse = 1.0 + pulse_strength * sin(TIME * pulse_speed);
	float pulse2 = 0.85 + 0.15 * sin(TIME * pulse_speed * 1.7 + 1.2);

	float border = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float rim = smoothstep(0.24, 0.0, border);
	float core = exp(-length(uv - vec2(0.5)) * 2.8);

	float sweep_pos = fract(uv.y - TIME * sweep_speed * sweep_direction);
	float sweep = smoothstep(0.18, 0.0, abs(sweep_pos - 0.5)) * 0.55;

	vec3 color = glow_color.rgb * (rim * 1.15 + core * 0.45 + sweep);
	float alpha = (rim * 0.9 + core * 0.35 + sweep * 0.5) * glow_color.a * pulse * pulse2;

	ALBEDO = color;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
