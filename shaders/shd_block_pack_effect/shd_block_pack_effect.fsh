precision highp float;
varying highp vec2 vs_TEXCOORD0;
uniform sampler2D Glow;
uniform sampler2D Hover;
void main() {
	vec4 glow = texture2D(Glow, vs_TEXCOORD0);
	float hover = texture2D(Hover, vs_TEXCOORD0).r;
	gl_FragColor = vec4(glow.b, glow.g, hover, 1.0);
}
