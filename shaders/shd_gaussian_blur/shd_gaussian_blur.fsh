// 7x7二维高斯模糊 - 更高质量
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_blur_amount;   // 模糊强度
uniform vec2 u_texture_size;   // 纹理尺寸

// 7x7高斯核 (49个采样点)
void main() {
    vec2 pixel_size = vec2(1.0) / u_texture_size;
    
    // 高斯核权重 (手动展开避免数组问题)
    float gaussian[49];
    gaussian[0] = 0.000036; gaussian[1] = 0.000363; gaussian[2] = 0.001446; gaussian[3] = 0.002291; gaussian[4] = 0.001446; gaussian[5] = 0.000363; gaussian[6] = 0.000036;
    gaussian[7] = 0.000363; gaussian[8] = 0.003676; gaussian[9] = 0.014662; gaussian[10] = 0.023226; gaussian[11] = 0.014662; gaussian[12] = 0.003676; gaussian[13] = 0.000363;
    gaussian[14] = 0.001446; gaussian[15] = 0.014662; gaussian[16] = 0.058488; gaussian[17] = 0.092651; gaussian[18] = 0.058488; gaussian[19] = 0.014662; gaussian[20] = 0.001446;
    gaussian[21] = 0.002291; gaussian[22] = 0.023226; gaussian[23] = 0.092651; gaussian[24] = 0.146768; gaussian[25] = 0.092651; gaussian[26] = 0.023226; gaussian[27] = 0.002291;
    gaussian[28] = 0.001446; gaussian[29] = 0.014662; gaussian[30] = 0.058488; gaussian[31] = 0.092651; gaussian[32] = 0.058488; gaussian[33] = 0.014662; gaussian[34] = 0.001446;
    gaussian[35] = 0.000363; gaussian[36] = 0.003676; gaussian[37] = 0.014662; gaussian[38] = 0.023226; gaussian[39] = 0.014662; gaussian[40] = 0.003676; gaussian[41] = 0.000363;
    gaussian[42] = 0.000036; gaussian[43] = 0.000363; gaussian[44] = 0.001446; gaussian[45] = 0.002291; gaussian[46] = 0.001446; gaussian[47] = 0.000363; gaussian[48] = 0.000036;
    
    vec4 total_color = vec4(0.0);
    int index = 0;
    
    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size * u_blur_amount;
            total_color += texture2D(gm_BaseTexture, v_vTexcoord + offset) * gaussian[index];
            index++;
        }
    }
    
    gl_FragColor = total_color;
}