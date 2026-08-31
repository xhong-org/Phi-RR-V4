precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 screenSize;
uniform float size;
void main() {
    float radius = clamp(size, 0.0, 12.0);
    vec4 colour = texture2D(gm_BaseTexture, v_vTexcoord);
    float best = dot(colour, colour);
    vec2 pixelSize = 1.0 / max(screenSize, vec2(1.0));
    for (int x = -12; x <= 12; x++) {
        for (int y = -12; y <= 12; y++) {
            float dist2 = float(x * x + y * y);
            if (dist2 <= radius * radius) {
                vec4 candidate = texture2D(gm_BaseTexture, v_vTexcoord + pixelSize * vec2(float(x), float(y)));
                float value = dot(candidate, candidate);
                if (value > best) { best = value; colour = candidate; }
            }
        }
    }
    gl_FragColor = colour * v_vColour;
}
