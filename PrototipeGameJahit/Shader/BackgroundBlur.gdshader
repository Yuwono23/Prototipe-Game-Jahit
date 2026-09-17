shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5.0) = 2.5;

void fragment() {
	COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	COLOR.rgb *= 0.7; // Agak digelapkan sedikit
}
