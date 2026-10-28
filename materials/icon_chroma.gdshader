shader_type canvas_item;

// 按背景键颜色抠图：与 key_color 接近的像素透明，其余保留。
// key_color 由脚本读取贴图角像素后写入；仅纯色背景时启用。
// 用颜色距离 + 平滑阈值，避免误伤壶体亮部（尤其玻璃轻壶）。

uniform vec3 key_color = vec3(1.0, 1.0, 1.0);
uniform float key_tolerance = 0.14;
uniform float key_softness = 0.10;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float dist = distance(tex.rgb, key_color);
	float mask = smoothstep(key_tolerance, key_tolerance + key_softness, dist);
	COLOR = vec4(tex.rgb, tex.a * mask) * COLOR;
}
