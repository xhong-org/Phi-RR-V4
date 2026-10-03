precision mediump float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_world;
uniform vec4 color;
uniform float extend;
uniform float radius;
uniform vec2 screenSize;
void main() {
    // Sample the sprite or surface with its own UV. The falloff uses the pixel
    // on the chart surface, so a leaked pass cannot vignette the hit texture.
    vec4 src = texture2D(gm_BaseTexture, v_vTexcoord);
    vec2 suv = (screenSize.x > 1.0) ? (v_world / screenSize) : v_vTexcoord;
    vec2 value = suv * (1.0 - suv.yx);
    float vig = clamp(pow(max(value.x * value.y * radius, 0.0), extend), 0.0, 1.0);
    // The capture is premultiplied. Mixing alpha toward color.a (1) turns the
    // soft hit disc into an opaque shaded blob.
    vec3 rgb = mix(color.rgb * src.a, src.rgb, vig);
    gl_FragColor = vec4(rgb, src.a) * v_vColour;
}
