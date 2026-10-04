precision highp float;
varying highp vec2 vs_TEXCOORD0;
uniform sampler2D Active;
uniform sampler2D Ready;
uniform sampler2D Normal;
uniform sampler2D Subtract;
void main() {
	gl_FragColor = vec4(
		texture2D(Active, vs_TEXCOORD0).r,
		texture2D(Ready, vs_TEXCOORD0).r,
		texture2D(Normal, vs_TEXCOORD0).r,
		texture2D(Subtract, vs_TEXCOORD0).g);
}
