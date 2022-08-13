shader_type canvas_item;

uniform sampler2D gradient;
uniform float lowest : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float highest : hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	float col_index = smoothstep(lowest,highest,texture(TEXTURE, UV).r);
	COLOR = texture(gradient, vec2(col_index));
}