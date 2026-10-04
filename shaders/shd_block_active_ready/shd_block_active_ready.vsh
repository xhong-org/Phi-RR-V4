attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform vec4 _ScreenParams;
uniform vec4 _DisplaceMap_ST;
uniform vec4 _SparkMap_ST;
uniform vec4 _TouchDisplaceMap_ST;
uniform vec4 _NoiseMap_ST;
varying highp vec2 vs_TEXCOORD0;
varying highp vec2 vs_TEXCOORD1;
varying highp vec2 vs_TEXCOORD2;
varying highp vec2 vs_TEXCOORD4;
varying highp vec4 vs_TEXCOORD3;
varying highp vec2 vs_TEXCOORD5;
varying highp float vs_TEXCOORD6;
void main() {
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
	gl_Position.z += in_Colour.r * 0.0;
	vec2 uv = in_TextureCoord;
	vs_TEXCOORD0 = uv;
	vs_TEXCOORD1 = uv * _DisplaceMap_ST.xy + _DisplaceMap_ST.zw;
	vs_TEXCOORD2 = uv * _SparkMap_ST.xy + _SparkMap_ST.zw;
	vs_TEXCOORD4 = uv * _TouchDisplaceMap_ST.xy + _TouchDisplaceMap_ST.zw;
	vs_TEXCOORD5 = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
	vs_TEXCOORD3 = vec4(uv, 0.0, 1.0);
	vs_TEXCOORD6 = _ScreenParams.y * 0.888888896 / max(_ScreenParams.x, 1.0);
}
