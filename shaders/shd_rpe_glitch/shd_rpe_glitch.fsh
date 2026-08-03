varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float time;
uniform float power;
uniform float rate;
uniform float speed;
uniform float blockCount;
uniform float colorRate;
float truncValue(float value) { return value < 0.0 ? -floor(-value) : floor(value); }
float randomValue(float seed) { return fract(543.2543 * sin(dot(vec2(seed), vec2(3525.46, -54.3415)))); }
void main() {
    float enabled = randomValue(truncValue(time * speed)) < rate ? 1.0 : 0.0;
    vec2 fixedUv = v_vTexcoord;
    fixedUv.x += (randomValue((truncValue(v_vTexcoord.y * blockCount) / max(blockCount, 0.001)) + time) - 0.5) * power * enabled;
    vec4 colour = texture2D(gm_BaseTexture, fixedUv);
    colour.r = mix(colour.r, texture2D(gm_BaseTexture, fixedUv + vec2(colorRate, 0.0)).r, enabled);
    colour.b = mix(colour.b, texture2D(gm_BaseTexture, fixedUv - vec2(colorRate, 0.0)).b, enabled);
    gl_FragColor = colour * v_vColour;
}
