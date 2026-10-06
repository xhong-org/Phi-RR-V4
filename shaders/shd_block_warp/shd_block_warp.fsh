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
uniform vec3 u_fill;

vec2 warp_repeat(vec4 rect, vec2 logical) {
	return mix(rect.xy, rect.zw, fract(logical));
}

void main() {
	vec2 uv = v_uv;
	vec2 screen = max(u_screen.xy, vec2(1.0));
	// Six surface pixels. A larger chart surface makes each cell a smaller
	// fraction of the zone. The mask quad still decides the covered area.
	float pixel = 6.0;
	vec2 snapped = (floor(uv * screen / pixel) + 0.5) * pixel / screen;
	// Official wobble is 0.15 UV. This pass uses half of that.
	float travel = u_screen.z / 20.0 * 1.5;
	vec2 dir = vec2(0.70710678, 0.70710678);
	vec2 perp = vec2(-dir.y, dir.x);
	vec2 base = uv * vec2(0.8, 0.3);
	float n1 = texture2D(u_noise, warp_repeat(u_noise_uv, base + dir * travel)).r;
	float n2 = texture2D(u_noise, warp_repeat(u_noise_uv, base + vec2(-dir.y, dir.x) * travel)).r;
	vec2 offset = (dir * (n1 - 0.5) + perp * (n2 - 0.5)) * 0.075;
	vec2 displaced = clamp(snapped + offset, 0.0, 1.0);
	// Stay inside this surface. Raw 0..1 reads neighbouring sprites on the page.
	vec2 scene_uv = mix(u_scene.xy, u_scene.zw, displaced);
	vec3 scene = texture2D(gm_BaseTexture, scene_uv).rgb;
	float mask = texture2D(u_mask, uv).r;
	vec2 edge_sample = texture2D(u_edge, uv).rg;
	float rim = clamp(max(edge_sample.r, edge_sample.g), 0.0, 1.0);
	float outside = 1.0 - clamp(mask, 0.0, 1.0);
	float rim_a = rim * outside * 0.38;
	if (mask < 0.004 && rim_a < 0.004) discard;
	vec3 interior = mix(u_fill, scene, 0.667);
	// texture_17, one texel per surface pixel, so each authored dot keeps its size.
	// The origin jumps by whole texels. u_screen.w is how long one arrangement stays put.
	vec2 spark_px = max(u_spark_px, vec2(1.0));
	float period = max(u_screen.w, 0.05);
	float slot = floor(u_screen.z / period);
	vec2 jump = floor(vec2(mod(slot * 37.0, spark_px.x), mod(slot * 19.0, spark_px.y)));
	vec2 spark_logical = (floor(uv * screen) + jump) / spark_px;
	float spark = texture2D(u_spark, warp_repeat(u_spark_uv, spark_logical)).r;
	vec3 pale = vec3(1.0, 0.64, 0.58) * spark;
	interior = 1.0 - (1.0 - interior) * (1.0 - pale);
	vec3 outline = vec3(1.0, 0.84, 0.84);
	gl_FragColor = vec4(interior * mask + outline * rim_a, mask + rim_a);
}
