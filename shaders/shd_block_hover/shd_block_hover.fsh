precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
void main() {
	float coverage = texture2D(gm_BaseTexture, v_vTexcoord).a * v_vColour.a;
	gl_FragColor = vec4(coverage, coverage, coverage, coverage);
}
