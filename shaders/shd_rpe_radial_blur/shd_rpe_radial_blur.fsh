precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float centerX;
uniform float centerY;
uniform float power;
uniform float sampleCount;
void main() {
    float count = max(1.0, min(64.0, floor(sampleCount + 0.5)));
    vec2 direction = v_vTexcoord - vec2(centerX, centerY);
    vec3 colour = vec3(0.0);
    for (int i = 0; i < 64; i++) {
        if (float(i) < count) {
            colour += texture2D(gm_BaseTexture, v_vTexcoord - power * direction * float(i)).rgb / count;
        }
    }
    float alpha = texture2D(gm_BaseTexture, v_vTexcoord).a;
    gl_FragColor = vec4(colour, alpha) * v_vColour;
}
