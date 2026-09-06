#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;
uniform vec2 uSize;
uniform float uPixelRatio;
out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy - uSize * 0.5;
  float radius = min(uSize.x, uSize.y) * 0.30;
  vec2 q = p / radius;
  float outer = length(q) - 1.0;
  float cutout = length(q - vec2(0.43, -0.22)) - 0.96;
  float distance = max(outer, -cutout) * radius;
  float aa = 0.8 / uPixelRatio;
  float surface = 1.0 - smoothstep(-aa, aa, distance);
  vec2 rim = q / max(length(q), 0.0001);
  float illuminatedRim = smoothstep(
    0.0,
    0.16,
    length(rim - vec2(0.43, -0.22)) - 0.96
  );
  float glow = exp(-max(outer, 0.0) / 0.18) * 0.12 * illuminatedRim;
  glow *= smoothstep(-aa, aa, outer * radius);
  glow *= 1.0 - smoothstep(1.25, 1.63, length(q));
  float shade = clamp(0.56 + dot(q, vec2(-0.23, -0.12)), 0.0, 1.0);
  vec3 silver = mix(vec3(0.70, 0.80, 0.91), vec3(0.99, 0.99, 0.94), shade);
  float texture =
      exp(-dot(q - vec2(-0.53, 0.18), q - vec2(-0.53, 0.18)) * 65.0) * 0.045;
  silver -= texture;
  float alpha = surface + glow * (1.0 - surface);
  vec3 premultiplied =
      silver * surface + vec3(0.60, 0.75, 1.0) * glow * (1.0 - surface);
  fragColor = vec4(premultiplied, alpha);
}
