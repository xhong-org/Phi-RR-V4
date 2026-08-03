// 可调节半径的二维高斯模糊
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_blur_amount;     // 模糊强度
uniform int u_kernel_radius;     // 核半径 (1-4)
uniform vec2 u_texture_size;     // 纹理尺寸

// 生成高斯权重函数
float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(6.28318530718) * sigma);
}

void main() {
    vec2 pixel_size = vec2(1.0) / u_texture_size;
    int radius = u_kernel_radius;
    
    // 计算一维高斯权重
    float weights[9];
    float sigma = float(radius) * 0.5;
    float total = 0.0;
    
    for (int i = -radius; i <= radius; i++) {
        float w = gaussian(float(i), sigma);
        weights[i + radius] = w;
        total += w;
    }
    
    // 归一化
    for (int i = 0; i <= radius * 2; i++) {
        weights[i] /= total;
    }
    
    // 二维卷积
    vec4 total_color = vec4(0.0);
    
    for (int y = -radius; y <= radius; y++) {
        for (int x = -radius; x <= radius; x++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size * u_blur_amount;
            float weight = weights[x + radius] * weights[y + radius];
            total_color += texture2D(gm_BaseTexture, v_vTexcoord + offset) * weight;
        }
    }
    
    gl_FragColor = total_color;
}