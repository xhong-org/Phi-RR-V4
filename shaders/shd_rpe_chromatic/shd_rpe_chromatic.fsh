varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float sampleCount;
uniform float power;
void main() {
    float count = max(2.0, min(64.0, floor(sampleCount + 0.5)));
    vec3 sum = vec3(0.0);
    vec3 colour = vec3(0.0);
    vec2 offset = (v_vTexcoord - vec2(0.5)) * vec2(1.0, -1.0);
    for (int i = 0; i < 64; i++) {
        if (float(i) >= count) break;
        float t = 2.0 * float(i) / (count - 1.0);
        vec3 slice = max(vec3(1.0 - t, 1.0 - abs(t - 1.0), t - 1.0), 0.0);
        sum += slice;
        colour += slice * texture2D(gm_BaseTexture, v_vTexcoord + (t - 1.0) * power * offset).rgb;
    }
    float alpha = texture2D(gm_BaseTexture, v_vTexcoord).a;
    gl_FragColor = vec4(colour / max(sum, vec3(0.0001)), alpha) * v_vColour;
}
