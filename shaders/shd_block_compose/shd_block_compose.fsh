precision highp float;
precision highp int;
uniform 	vec4 _BlockTime;
uniform 	mediump float _DisplaceSpeed;
uniform 	mediump float _DisplaceStrength;
uniform 	mediump vec4 _DisplaceDirection;
uniform mediump sampler2D _DisplaceMap;
uniform vec4 _DisplaceMap_Rect;

vec2 block_repeat(vec4 rect, vec2 uv) {
    return mix(rect.xy, rect.zw, fract(uv));
}
uniform mediump sampler2D _NormalBlockRT;
uniform mediump sampler2D _SubtractBlockRT;
varying highp vec2 vs_TEXCOORD0;
varying highp vec2 vs_TEXCOORD1;
float SV_Target0;
mediump vec2 u_xlat16_0;
vec2 u_xlat1;
mediump float u_xlat16_1;
mediump float u_xlat16_4;
vec2 u_xlat5;
mediump float u_xlat16_5;
mediump float u_xlat16_6;
void main()
{
    u_xlat16_0.x = dot(_DisplaceDirection.xy, _DisplaceDirection.xy);
    u_xlat16_0.x = inversesqrt(u_xlat16_0.x);
    u_xlat16_0.xy = u_xlat16_0.xx * _DisplaceDirection.xy;
    u_xlat1.x = _BlockTime.x * _DisplaceSpeed;
    u_xlat5.y = u_xlat16_0.x * u_xlat1.x;
    u_xlat5.x = (-u_xlat16_0.y) * u_xlat1.x;
    u_xlat1.xy = u_xlat16_0.xy * u_xlat1.xx + vs_TEXCOORD1.xy;
    u_xlat16_1 = texture2D(_DisplaceMap, block_repeat(_DisplaceMap_Rect, u_xlat1.xy)).x;
    u_xlat16_4 = u_xlat16_1 + -0.5;
    u_xlat1.xy = u_xlat5.xy + vs_TEXCOORD1.xy;
    u_xlat16_1 = texture2D(_DisplaceMap, block_repeat(_DisplaceMap_Rect, u_xlat1.xy)).x;
    u_xlat16_6 = u_xlat16_1 + -0.5;
    u_xlat1.x = u_xlat16_6 * (-u_xlat16_0.y);
    u_xlat1.y = u_xlat16_6 * u_xlat16_0.x;
    u_xlat1.xy = u_xlat16_0.xy * vec2(u_xlat16_4) + u_xlat1.xy;
    u_xlat1.xy = u_xlat1.xy * vec2(vec2(_DisplaceStrength, _DisplaceStrength)) + vs_TEXCOORD0.xy;
    u_xlat16_5 = texture2D(_NormalBlockRT, u_xlat1.xy).x;
    u_xlat16_1 = texture2D(_SubtractBlockRT, u_xlat1.xy).x;
    u_xlat16_0.x = (-u_xlat16_5) + u_xlat16_1;
    SV_Target0 = abs(u_xlat16_0.x);
    gl_FragColor = vec4(SV_Target0,0.,0.,1.);
    return;
}
