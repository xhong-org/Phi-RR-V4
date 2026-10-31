precision highp float;
varying vec2 v_uv;
uniform sampler2D u_mask;
uniform sampler2D u_noise;
uniform sampler2D u_edge;
uniform sampler2D u_spark;
uniform vec4 u_screen;
uniform vec4 u_scene;
uniform vec4 u_noise_uv;
uniform vec4 u_spark_uv;
uniform vec2 u_spark_px;
uniform vec2 u_effect_size;
uniform vec3 u_fill;
uniform vec3 u_edge_color;
uniform vec3 u_glow_color;
uniform vec3 u_spark_color;

// All custom samplers use u_*: gm_BaseTexture remains the draw texture.
vec2 block_repeat(vec4 rect, vec2 logical) {
    return mix(rect.xy, rect.zw, fract(logical));
}

vec2 block_grid(vec2 uv, vec2 size) {
    return (floor(uv * size) + 0.5) / size;
}

vec3 block_rgb_to_hsv(vec3 c) {
    vec4 k = vec4(0.0, -0.33333333, 0.66666667, -1.0);
    vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-6)),
        d / (q.x + 1e-6), q.x);
}

vec3 block_hsv_to_rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 0.66666667, 0.33333333)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 block_overlay(vec3 base, vec3 blend) {
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend),
        step(vec3(0.5), blend));
}

vec3 block_field(vec2 uv, float speed, vec2 tiling, float pixel) {
    vec2 screen = max(u_screen.xy, vec2(1.0));
    float travel = u_screen.z * 0.05 * speed;
    vec2 direction = vec2(0.70710678);
    vec2 perpendicular = vec2(-direction.y, direction.x);
    vec2 a = (floor((uv * tiling + direction * travel) * screen / pixel) + 0.5) * pixel / screen;
    vec2 b = (floor((uv * tiling + perpendicular * travel) * screen / pixel) + 0.5) * pixel / screen;
    float n1 = texture2D(u_noise, block_repeat(u_noise_uv, a)).r;
    float n2 = texture2D(u_noise, block_repeat(u_noise_uv, b)).r;
    return vec3(direction * (n1 - 0.5) + perpendicular * (n2 - 0.5), (n1 + n2) * 0.5);
}

void main() {
    vec2 uv = v_uv;
    vec2 screen = max(u_screen.xy, vec2(1.0));
    vec4 masks = texture2D(u_mask, uv);
    vec3 effects = texture2D(u_edge, uv).rgb;
    float coverage = clamp(masks.r, 0.0, 1.0);
    float edge = texture2D(u_edge, block_grid(uv, u_effect_size)).r;
    float glow = effects.g * (1.0 - clamp(coverage + edge, 0.0, 1.0));
    float ready = masks.g * abs(masks.b - masks.a);
    if (coverage + edge + glow + ready < 0.0001) discard;

    // Scene pixels and fine sparks are independent of mask resolution.
    // Subtract holes preserve the untouched chart beneath this material.
    float pixel = max(u_screen.w, 1.0);
    vec3 field = block_field(uv, 1.5, vec2(0.8, 0.3), pixel);
    vec2 displaced = block_grid(uv, screen / pixel) + field.xy * 0.15;
    vec2 scene_uv = mix(u_scene.xy, u_scene.zw,
        clamp(displaced, 0.5 / screen, 1.0 - 0.5 / screen));
    vec3 scene = texture2D(gm_BaseTexture, scene_uv).rgb;

    // Sparse authored sparks move with the scene's continuous noise field.
    vec2 spark_coord = uv * screen / max(u_spark_px, vec2(1.0)) + field.xy * 2.39;
    float spark = texture2D(u_spark, block_repeat(u_spark_uv, spark_coord)).r;
    // Suppress the dark texels' red haze, retaining the sparse bright flecks.
    spark = min(1.0, spark * spark * 2.0);
    float noise = field.z;
    vec3 sparks = spark * u_spark_color * noise * 5.69;
    vec3 hsv = block_rgb_to_hsv(scene) + sparks * 0.2;
    vec3 shifted = block_hsv_to_rgb(hsv);
    vec3 mixed_scene = clamp(block_overlay(sparks, shifted), 0.0, 1.0);
    vec3 fill = mix(u_fill - vec3(noise * 0.411), mixed_scene, 0.667);

    // Premultiplied material plus the original scene contribution keeps the
    // thin intact UI/line silhouette alongside its displaced image.
    vec3 colour = coverage * fill + u_edge_color * edge * 0.8 + u_glow_color * glow * 0.8;
    float alpha = clamp(coverage * 0.667 + edge * 0.8 + glow * 0.8, 0.0, 1.0);
    float shine = (sin(u_screen.z * 37.9) * 0.5 + 1.0) * 0.12 * ready;
    colour += vec3(shine * ready);
    alpha = clamp(alpha + ready, 0.0, 1.0);

    gl_FragColor = vec4(max(colour, 0.0), alpha);
}
