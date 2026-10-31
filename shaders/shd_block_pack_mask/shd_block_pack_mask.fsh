precision highp float;
varying highp vec2 vs_TEXCOORD0;
uniform sampler2D u_active;
uniform sampler2D u_ready;
uniform sampler2D u_normal;
uniform sampler2D u_subtract;
void main() {
	gl_FragColor = vec4(
		texture2D(u_active, vs_TEXCOORD0).r,
		texture2D(u_ready, vs_TEXCOORD0).r,
		texture2D(u_normal, vs_TEXCOORD0).r,
		texture2D(u_subtract, vs_TEXCOORD0).g);
    gl_FragColor *= texture2D(gm_BaseTexture, vs_TEXCOORD0).a;
}
