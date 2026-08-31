precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec4 color;
uniform float extend;
uniform float radius;
void main() {
    vec2 value = v_vTexcoord * (1.0 - v_vTexcoord.yx);
    float vignette = pow(max(value.x * value.y * radius, 0.0), extend);
    gl_FragColor = mix(color, texture2D(gm_BaseTexture, v_vTexcoord), vignette) * v_vColour;
}
