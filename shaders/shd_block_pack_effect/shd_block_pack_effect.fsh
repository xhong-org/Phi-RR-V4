precision highp float;
varying highp vec2 vs_TEXCOORD0;
uniform sampler2D u_glow;
uniform sampler2D u_hover;
void main() {
	vec4 glow = texture2D(u_glow, vs_TEXCOORD0);
	float hover = texture2D(u_hover, vs_TEXCOORD0).r;
	gl_FragColor = vec4(glow.b, glow.g, hover, 1.0);
    gl_FragColor *= texture2D(gm_BaseTexture, vs_TEXCOORD0).a;
}
