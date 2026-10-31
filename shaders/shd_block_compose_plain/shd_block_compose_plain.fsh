precision highp float;
precision highp int;
uniform mediump sampler2D u_off_normal;
uniform mediump sampler2D u_off_subtract;
varying highp vec2 vs_TEXCOORD0;
vec2 SV_Target0;
mediump float u_xlat16_0;
mediump float u_xlat16_1;
mediump vec2 u_xlat16_2;
void main()
{
    u_xlat16_0 = texture2D(u_off_normal, vs_TEXCOORD0.xy).x;
    u_xlat16_2.xy = texture2D(u_off_subtract, vs_TEXCOORD0.xy).xy;
    u_xlat16_1 = u_xlat16_2.x * u_xlat16_2.y + (-u_xlat16_0);
    SV_Target0.y = u_xlat16_2.y;
    SV_Target0.x = abs(u_xlat16_1);
    gl_FragColor = vec4(SV_Target0,0.,1.);
    gl_FragColor *= texture2D(gm_BaseTexture, vs_TEXCOORD0).a;
    return;
}
