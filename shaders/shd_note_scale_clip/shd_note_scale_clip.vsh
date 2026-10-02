attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_world;
void main() {
	vec4 world_pos = gm_Matrices[MATRIX_WORLD] * vec4(in_Position.xy, 0.0, 1.0);
	v_world = world_pos.xy;
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	v_vTexcoord = in_TextureCoord;
	v_vColour = in_Colour;
}
