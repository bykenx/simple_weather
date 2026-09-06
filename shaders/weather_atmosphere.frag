#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uPixelRatio;
uniform vec3 uTop;
uniform vec3 uBottom;
uniform float uCount;
uniform vec4 uBounds[24];
uniform vec4 uColors[24];
uniform vec4 uSun;
uniform float uSunAngle;
out vec4 fragColor;

// Screen-space, stationary noise: no repeating Bayer tile, no moving grain.
float noise(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float y = clamp(p.y / uSize.y, 0.0, 1.0);
  vec3 color = mix(uTop, uBottom, y);
  float sunHighlight = 0.0;
  if (uSun.w > 0.5) {
    vec2 delta = p - uSun.xy;
    float radius = uSun.z;
    vec2 q = delta / radius;
    float c = cos(uSunAngle);
    float s = sin(uSunAngle);
    // Inverse rotation keeps the light source fixed while rays and flares sway.
    vec2 opticalDelta = vec2(c * delta.x + s * delta.y,
        -s * delta.x + c * delta.y);
    vec2 ray = opticalDelta / radius;
    // Exposure bloom: the aperture is only suggested inside the white light,
    // never rendered as a flat polygon with a visible outline.
    vec2 hex = abs(q);
    float hexDistance = max(hex.y, hex.x * 0.8660254 + hex.y * 0.5);
    float aperture = mix(length(q), hexDistance, 0.55);
    float coreLight = 6.0 * exp(-2.3 * pow(aperture, 4.0));
    sunHighlight = 1.0 - exp(-coreLight);
    float bloom = 0.85 * exp(-dot(q, q) / 3.5)
        + 0.28 * exp(-dot(q, q) / 22.0);
    float rays = 0.0;
    for (int k = 0; k < 3; k++) {
      float angle = 0.28 + float(k) * 1.04719755;
      vec2 axis = vec2(cos(angle), sin(angle));
      float along = abs(dot(ray, axis));
      float across = dot(ray, vec2(-axis.y, axis.x));
      float spread = 0.20 + along * 0.10;
      rays += exp(-across * across / (spread * spread))
          * exp(-along * 0.65) * (k == 1 ? 0.85 : 0.60);
    }
    vec3 exposure = vec3(0.96, 0.985, 1.0) * coreLight
        + vec3(1.0, 0.96, 0.88) * (bloom + rays);
    color = 1.0 - (1.0 - color) * exp(-exposure);
    // Rotate the whole optical axis with the rays, including elliptical spots.
    vec2 flareEnd = vec2(uSize.x * 0.65,
        min(uSize.y * 0.47, uSun.y + uSize.x * 0.58));
    for (int j = 0; j < 5; j++) {
      float index = float(j);
      float along = 0.30 + index * 0.175;
      vec2 center = (flareEnd - uSun.xy) * along;
      float r = radius * (0.36 + index * 0.12);
      vec2 offset = (opticalDelta - center) / r;
      if (j == 0) offset.y *= 1.8;
      float fd = length(offset);
      float spot = (1.0 - smoothstep(0.25, 1.25, fd)) * 0.055;
      float ring = exp(-pow((fd - 0.86) / 0.16, 2.0)) * 0.023;
      vec3 tint = j == 0 ? vec3(0.70, 0.64, 1.0)
          : (j == 3 ? vec3(0.48, 0.92, 0.95) : vec3(0.62, 0.82, 1.0));
      float upperHalf = 1.0 - smoothstep(0.44, 0.50, y);
      color = mix(color, tint, (spot + ring) * upperHalf);
    }
  }
  // Composite the entire atmosphere in float precision, then quantize once.
  for (int i = 0; i < 24; i++) {
    if (float(i) >= uCount) break;
    vec4 bounds = uBounds[i];
    float distance = length((p - bounds.xy) / bounds.zw);
    float alpha = (1.0 - smoothstep(0.0, 1.0, distance)) * uColors[i].a;
    color = mix(color, uColors[i].rgb, alpha);
    // Clouds still attenuate the highlight; the foreground scrim must not.
    sunHighlight *= 1.0 - alpha;
  }
  float scrim = y < 0.35
      ? mix(24.0, 8.0, y / 0.35) / 255.0
      : mix(8.0, 153.0, (y - 0.35) / 0.65) / 255.0;
  color = mix(color, vec3(6.0, 22.0, 43.0) / 255.0, scrim);
  color = mix(color, vec3(1.0), sunHighlight);
  float dither = (noise(floor(p * uPixelRatio)) - 0.5) / 255.0;
  fragColor = vec4(clamp(color + dither, 0.0, 1.0), 1.0);
}
