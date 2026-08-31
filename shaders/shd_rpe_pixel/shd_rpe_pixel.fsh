precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 screenSize;
uniform float size;
void main() {
    vec2 factor = screenSize / max(size, 1.0);
    vec2 pixelUv = floor(v_vTexcoord * factor + vec2(0.5)) / factor;
    gl_FragColor = texture2D(gm_BaseTexture, pixelUv) * v_vColour;
}
