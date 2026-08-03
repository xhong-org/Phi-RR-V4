varying vec2 vv_tex;
varying vec4 vv_col;
uniform sampler2D v_chroma;

void main() {
    float y = texture2D(gm_BaseTexture, vv_tex).r - (16.0 / 255.0);
    vec2 uv = texture2D(v_chroma, vv_tex).rg - vec2(128.0 / 255.0);
    vec3 rgb = vec3(
        1.164383 * y + 1.596027 * uv.y,
        1.164383 * y - 0.391762 * uv.x - 0.812968 * uv.y,
        1.164383 * y + 2.017232 * uv.x
    );
    gl_FragColor = vec4(rgb, 1.0) * vv_col;
}
