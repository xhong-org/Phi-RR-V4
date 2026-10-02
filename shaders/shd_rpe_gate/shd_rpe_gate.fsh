precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float time;
uniform float params;

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec3 hue_shift(vec3 color, float shift) {
    vec3 basis = vec3(0.55735);
    vec3 p = basis * dot(basis, color);
    vec3 u = color - p;
    vec3 v = cross(basis, u);
    return u * cos(shift * 6.2832) + v * sin(shift * 6.2832) + p;
}

void main() {
    float glitch_intensity = 0.0;
    float aberration_intensity = params;
    float hue_progress = 0.0;
    float desat_intensity = 0.0;
    vec2 sample_point = v_vTexcoord;
    float mod_value_x = 0.00137 + rand(time - mod(time, 0.053));
    float y_point = sample_point.y - mod(sample_point.y, mod_value_x);
    float adjusted_point_x = mod(rand(y_point), 0.0137);
    sample_point.x += glitch_intensity * (adjusted_point_x * 3.0);
    vec2 direction = glitch_intensity * vec2(0.001, 0.0);
    vec4 orig = texture2D(gm_BaseTexture, sample_point + direction);
    vec2 aberrated = vec2(0.01 * aberration_intensity, 0.0);
    orig.r = texture2D(gm_BaseTexture, sample_point - aberrated).r;
    orig.b = texture2D(gm_BaseTexture, sample_point + aberrated).b;
    orig.rgb = hue_shift(orig.rgb, hue_progress);
    float luma = 0.3 * orig.r + 0.6 * orig.g + 0.1 * orig.b;
    orig.r += desat_intensity * (luma - orig.r);
    orig.g += desat_intensity * (luma - orig.g);
    orig.b += desat_intensity * (luma - orig.b);
    gl_FragColor = orig * v_vColour;
}
