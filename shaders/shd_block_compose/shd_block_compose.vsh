attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform vec4 _DisplaceMap_ST;
varying highp vec2 vs_TEXCOORD0;
varying highp vec2 vs_TEXCOORD1;
void main() {
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	gl_Position.z += in_Colour.r * 0.0;
	vs_TEXCOORD0 = in_TextureCoord;
	vs_TEXCOORD1 = in_TextureCoord * _DisplaceMap_ST.xy + _DisplaceMap_ST.zw;
}
