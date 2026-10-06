precision highp float;
varying vec2 v_uv;
uniform sampler2D u_mask;
uniform sampler2D u_noise;
uniform sampler2D u_edge;
uniform vec4 u_screen;
uniform vec4 u_scene;
uniform vec4 u_noise_uv;
uniform vec3 u_fill;

vec2 warp_repeat(vec4 rect, vec2 logical) {
	return mix(rect.xy, rect.zw, fract(logical));
}

float grain_hash(vec2 cell) {
	vec3 p = fract(vec3(cell.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void main() {
	vec2 uv = v_uv;
	vec2 screen = max(u_screen.xy, vec2(1.0));
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
	// 4px pale-red lights. Screen-blended so the chart stays visible and the
	// halo is not replaced by an opaque disc. u_screen.w is the hold time.
	float period = max(u_screen.w, 0.05);
	float slot = floor(u_screen.z / period);
	vec2 pix = uv * screen;
	vec2 seed = vec2(slot * 17.0, slot * 9.0);
	float core = 0.0;
	float halo = 0.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 cell = floor(pix / 6.0) + vec2(float(i), float(j));
			if (grain_hash(cell + seed) < 0.921) continue;
			vec2 nudge = vec2(
				grain_hash(cell + seed + vec2(3.1, 1.7)),
				grain_hash(cell + seed + vec2(8.7, 4.2))
			) - 0.5;
			vec2 center = (cell + 0.5) * 6.0 + nudge;
			float dist = length(pix - center);
			core = max(core, 1.0 - smoothstep(1.15, 2.05, dist));
			halo = max(halo, 1.0 - smoothstep(1.6, 6.5, dist));
		}
	}
	float light = max(core * 0.82, halo * 0.48);
	vec3 pale = vec3(1.0, 0.64, 0.58) * light;
	interior = 1.0 - (1.0 - interior) * (1.0 - pale);
	vec3 outline = vec3(1.0, 0.84, 0.84);
	gl_FragColor = vec4(interior * mask + outline * rim_a, mask + rim_a);
}
