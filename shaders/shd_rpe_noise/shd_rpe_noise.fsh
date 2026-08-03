varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float seed;
uniform float power;
vec2 randomValue(vec2 pos) { return fract(sin(vec2(dot(pos, vec2(12.9898,78.233)), dot(pos, vec2(-148.998,-65.233)))) * 43758.5453); }
void main() {
    vec2 newUv = v_vTexcoord + (randomValue(v_vTexcoord + vec2(seed, 0.0)) - vec2(0.5)) * power;
    gl_FragColor = texture2D(gm_BaseTexture, newUv) * v_vColour;
}
