precision highp float;
varying highp vec2 vs_TEXCOORD0;
uniform sampler2D u_normal;
uniform sampler2D u_inverse;
uniform sampler2D u_active;
uniform sampler2D u_ready;
uniform float u_phase;
// Geometry adapter only. All noise, displacement, glow and touch materials
// remain the Official shaders. Later states replace earlier state coverage.
void main() {
    vec2 uv = vs_TEXCOORD0;
    float normal = step(0.5, texture2D(u_normal, uv).r);
    vec2 inverseMask = texture2D(u_inverse, uv).rg;
    // Soft subtraction stores outside=(1,0); only R*G is coverage.
    float inverse = step(0.5, inverseMask.r * mix(1.0, inverseMask.g, step(0.5, u_phase)));
    float coverage = abs(normal - inverse);
    if (u_phase > 0.5) coverage *= 1.0 - step(0.5, texture2D(u_active, uv).r);
    if (u_phase > 1.5) coverage *= 1.0 - step(0.5, texture2D(u_ready, uv).r);
    gl_FragColor = vec4(coverage, coverage, 0.0, 1.0);
    gl_FragColor *= texture2D(gm_BaseTexture, uv).a;
}
