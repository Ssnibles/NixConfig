#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float barCount;
    float barWidth;
    float barSpacing;
    float heightPx;
    float phase;
    float play;
    float progress;
    vec4 colorStart;
    vec4 colorEnd;
    vec4 bgColor;
};

void main() {
    float barSpan = barWidth + barSpacing;
    float totalWidth = barCount * barWidth + (barCount - 1.0) * barSpacing;
    float halfHeight = heightPx * 0.5;

    float x = qt_TexCoord0.x * totalWidth;
    float index = floor(x / barSpan);

    if (index < 0.0 || index >= barCount) {
        fragColor = vec4(0.0);
        return;
    }

    float xIn = x - index * barSpan;
    float inBar = 1.0 - smoothstep(barWidth, barWidth + 1.0, xIn);

    float waveHeight = 6.0 + sin(phase + index * 0.55) * 4.0;
    float barHeight = mix(3.0, waveHeight, play);
    float dy = abs(qt_TexCoord0.y * heightPx - halfHeight);
    float inY = 1.0 - smoothstep(barHeight * 0.5, barHeight * 0.5 + 1.0, dy);

    float frac = (index + 1.0) / barCount;
    vec4 color = bgColor;
    if (frac <= progress) {
        float t = frac / max(progress, 0.01);
        color = mix(colorStart, colorEnd, t);
    }

    fragColor = color * inBar * inY * qt_Opacity;
}
