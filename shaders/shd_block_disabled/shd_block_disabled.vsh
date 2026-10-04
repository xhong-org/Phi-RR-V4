attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform vec4 _DisplaceMap_ST;
uniform vec4 _SparkMap_ST;
varying highp vec2 vs_TEXCOORD0;
varying highp vec2 vs_TEXCOORD2;
varying highp vec2 vs_TEXCOORD3;
varying highp vec4 vs_COLOR0;
void main() {
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	vs_TEXCOORD0 = in_TextureCoord;
	vs_TEXCOORD2 = in_TextureCoord * _DisplaceMap_ST.xy + _DisplaceMap_ST.zw;
	vs_TEXCOORD3 = in_TextureCoord * _SparkMap_ST.xy + _SparkMap_ST.zw;
	vs_COLOR0 = in_Colour;
}
