precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float time;
uniform float sampleCount;
uniform float power;
uniform float speed;
uniform float rate;

float trunc_value(float value) {
    return value < 0.0 ? -floor(-value) : floor(value);
}
float randomi(float seed) {
    return fract(543.2543 * sin(dot(vec2(seed), vec2(3525.46, -54.3415))));
}
float random_value(float seed) {
    return sin(fract(543.2543 * sin(dot(vec2(seed), vec2(3525.46, -54.3415)))) * 2307.9461);
}

void main() {
    vec4 base = texture2D(gm_BaseTexture, v_vTexcoord);
    vec4 effect_colour;
    if (randomi(trunc_value(time)) >= rate) {
        effect_colour = base * v_vColour;
    } else {
        float count = clamp(floor(sampleCount + 0.5), 2.0, 8.0);
        vec3 sum = vec3(0.0);
        vec3 colour = vec3(0.0);
        vec2 offset = (v_vTexcoord - vec2(0.5)) * vec2(random_value(time * speed), random_value(time * speed * 2.0));
        for (int i = 0; i < 8; i++) {
            if (float(i) < count) {
                float t = 2.0 * float(i) / max(count - 1.0, 1.0);
                vec3 slice = max(vec3(1.0 - t, 1.0 - abs(t - 1.0), t - 1.0), 0.0);
                sum += slice;
                colour += slice * texture2D(gm_BaseTexture, v_vTexcoord + (t - 1.0) * power * offset).rgb;
            }
        }
        if ((sum.x + sum.y + sum.z) > 0.001) {
            effect_colour = vec4(colour / max(sum, vec3(0.0001)), base.a) * v_vColour;
        } else {
            effect_colour = base * v_vColour;
        }
    }
    gl_FragColor = effect_colour;
}
