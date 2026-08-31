precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float factor;
void main() {
    vec4 source = texture2D(gm_BaseTexture, v_vTexcoord);
    float luminance = dot(vec3(0.299, 0.587, 0.114), source.rgb);
    gl_FragColor = vec4(mix(source.rgb, vec3(luminance), factor), source.a) * v_vColour;
}
