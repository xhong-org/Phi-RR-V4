varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 screenSize;
uniform float power;
void main() {
    float aspect = screenSize.x / max(screenSize.y, 1.0);
    vec2 p = vec2(v_vTexcoord.x, v_vTexcoord.y / aspect);
    vec2 centre = vec2(0.5, 0.5 / aspect);
    vec2 delta = p - centre;
    float radius = length(delta);
    vec2 newUv = v_vTexcoord;
    if (radius > 0.000001 && abs(power) > 0.000001) {
        float strength = (6.283184 / (2.0 * length(centre))) * power;
        float bind = strength > 0.0 ? length(centre) : (aspect < 1.0 ? centre.x : centre.y);
        vec2 warped;
        if (strength > 0.0) warped = centre + normalize(delta) * tan(radius * strength) * bind / tan(bind * strength);
        else warped = centre + normalize(delta) * atan(radius * -strength * 10.0) * bind / atan(-strength * bind * 10.0);
        newUv = vec2(warped.x, warped.y * aspect);
    }
    gl_FragColor = texture2D(gm_BaseTexture, newUv) * v_vColour;
}
