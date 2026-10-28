shader_type spatial;
render_mode blend_add, depth_draw_always, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D arrow_tex : filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_speed = 3.0;
uniform float pulse_strength = 0.22;
uniform float brightness = 1.65;

void fragment() {
	vec4 tex = texture(arrow_tex, UV);
	float mask = max(tex.r, max(tex.g, tex.b));
	float pulse = 1.0 + pulse_strength * sin(TIME * pulse_speed);
	vec3 color = tint.rgb * brightness * pulse * mask;
	ALBEDO = color;
	ALPHA = clamp(mask * tint.a * pulse, 0.0, 1.0);
}
