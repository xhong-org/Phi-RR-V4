varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float offset;
uniform vec2 tex_size;

void main() {
    vec2 step = vec2(1.0 / tex_size.x, 1.0 / tex_size.y);
    vec2 uv0 = v_vTexcoord + vec2(-offset, -offset) * step;
    vec2 uv1 = v_vTexcoord + vec2( offset, -offset) * step;
    vec2 uv2 = v_vTexcoord + vec2(-offset,  offset) * step;
    vec2 uv3 = v_vTexcoord + vec2( offset,  offset) * step;
    
    vec4 color = (texture2D(gm_BaseTexture, uv0) +
                  texture2D(gm_BaseTexture, uv1) +
                  texture2D(gm_BaseTexture, uv2) +
                  texture2D(gm_BaseTexture, uv3)) / 4.0;
    gl_FragColor = color * v_vColour;
}