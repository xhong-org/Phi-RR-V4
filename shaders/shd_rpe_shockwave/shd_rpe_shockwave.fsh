varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 screenSize;
uniform float progress;
uniform float centerX;
uniform float centerY;
uniform float width;
uniform float distortion;
uniform float expand;
void main() {
    float aspect = screenSize.y / max(screenSize.x, 1.0);
    vec2 centre = vec2(centerX, (centerY - 0.5) * aspect + 0.5);
    vec2 coord = vec2(v_vTexcoord.x, (v_vTexcoord.y - 0.5) * aspect + 0.5);
    float dist = distance(coord, centre);
    vec2 sampleUv = v_vTexcoord;
    float glow = 0.0;
    if (progress > 0.0001 && dist > 0.0001 && progress - width <= dist && dist <= progress + width) {
        float diff = dist - progress;
        float scaleDiff = 1.0 - pow(abs(diff * expand), distortion);
        float denom = max(progress * dist * 40.0, 0.0001);
        coord += normalize(coord - centre) * diff * scaleDiff / denom;
        sampleUv = vec2(coord.x, (coord.y - 0.5) / max(aspect, 0.0001) + 0.5);
        glow = scaleDiff / denom;
    }
    vec4 colour = texture2D(gm_BaseTexture, sampleUv);
    gl_FragColor = (colour + colour * glow) * v_vColour;
}
