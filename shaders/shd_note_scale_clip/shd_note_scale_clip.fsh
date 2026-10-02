precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_world;
// xy = line anchor, zw = unit direction along the line.
uniform vec4 u_clip;
uniform float u_half;
void main() {
	vec4 col = texture2D(gm_BaseTexture, v_vTexcoord) * v_vColour;
	float along = (v_world.x - u_clip.x) * u_clip.z + (v_world.y - u_clip.y) * u_clip.w;
	if (abs(along) > u_half) col = vec4(0.0);
	gl_FragColor = col;
}
