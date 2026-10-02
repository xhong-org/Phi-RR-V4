precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform sampler2D u_under;
void main() {
    // Over is premultiplied. A fully empty pixel keeps the parent. A coloured
    // pixel with zero coverage is an aberration fringe and must stay opaque,
    // matching the composite that kept lines, notes, UI, and hits together.
    vec4 over = texture2D(gm_BaseTexture, v_vTexcoord) * v_vColour;
    vec4 under = texture2D(u_under, v_vTexcoord);
    if (over.r + over.g + over.b + over.a <= 0.0) {
        gl_FragColor = under;
    } else if (over.a <= 0.0) {
        gl_FragColor = vec4(over.rgb, 1.0);
    } else {
        float inv = 1.0 - over.a;
        gl_FragColor = clamp(vec4(over.rgb + under.rgb * inv, over.a + under.a * inv), 0.0, 1.0);
    }
}
