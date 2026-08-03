varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float factor;
void main() {
    vec4 source = texture2D(gm_BaseTexture, v_vTexcoord);
    gl_FragColor = mix(source, vec4(1.0, 0.0, 0.0, 1.0), factor) * v_vColour;
}
