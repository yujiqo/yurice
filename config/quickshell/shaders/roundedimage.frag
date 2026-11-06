#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float radius;
    vec4 uvRect;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 halfSize = size * 0.5;
    vec2 q = abs(qt_TexCoord0 * size - halfSize) - (halfSize - vec2(radius));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    float aa = max(fwidth(d), 1e-4);
    float coverage = clamp(0.5 - d / aa, 0.0, 1.0);
    vec4 color = texture(source, uvRect.xy + qt_TexCoord0 * uvRect.zw);
    fragColor = color * coverage * qt_Opacity;
}
