#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 dottedPaper(float2 position, half4 color) {
    constexpr float spacing = 24.0;
    float2 cell = fract(position / spacing) - 0.5;
    float distance = length(cell * spacing);
    float antialias = max(fwidth(distance), 0.5);
    float dot = 1.0 - smoothstep(1.25 - antialias, 1.25 + antialias, distance);

    float3 paper = float3(0.98, 0.976, 0.953);
    float3 graphite = float3(0.58, 0.62, 0.60);
    return half4(half3(mix(paper, graphite, dot * 0.34)), half(1.0));
}
