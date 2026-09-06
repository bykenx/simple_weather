#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPixelRatio;
uniform float uPhase;
uniform float uLibrationLongitude;
uniform float uLibrationLatitude;
uniform float uOrientation;
uniform sampler2D uMoonTexture;
uniform sampler2D uNormalTexture;

out vec4 fragColor;

const float PI = 3.141592653589793;

void main() {
  vec2 centered = (FlutterFragCoord().xy - uSize * 0.5);
  float radius = min(uSize.x, uSize.y) * 0.42;
  vec2 disk = centered / radius;
  float radiusSquared = dot(disk, disk);
  float edge = 1.0 - smoothstep(
    1.0 - 2.5 / (radius * uPixelRatio),
    1.0,
    radiusSquared
  );
  // Reconstruct the visible hemisphere, then sample the equirectangular maps.
  vec3 sphereNormal = normalize(vec3(disk.x, -disk.y, sqrt(max(0.0, 1.0 - radiusSquared))));
  float orientationCos = cos(uOrientation);
  float orientationSin = sin(uOrientation);
  vec2 orientedDisk = vec2(
    disk.x * orientationCos - disk.y * orientationSin,
    disk.x * orientationSin + disk.y * orientationCos
  );
  vec3 textureSphereNormal = normalize(vec3(
    orientedDisk.x,
    -orientedDisk.y,
    sqrt(max(0.0, 1.0 - dot(orientedDisk, orientedDisk)))
  ));
  float longitude =
      atan(textureSphereNormal.x, textureSphereNormal.z) + uLibrationLongitude;
  float latitude =
      asin(clamp(textureSphereNormal.y, -1.0, 1.0)) + uLibrationLatitude;
  vec2 textureUv = vec2(
    fract(0.75 - longitude / (2.0 * PI)),
    0.5 - latitude / PI
  );
  vec3 albedo = texture(uMoonTexture, textureUv).rgb;

  // Convert the tangent-space normal map to the sphere's coordinate system.
  vec3 mapNormal = texture(uNormalTexture, textureUv).rgb * 2.0 - 1.0;
  vec3 tangent = normalize(vec3(sphereNormal.z, 0.0, -sphereNormal.x));
  vec3 bitangent = normalize(cross(sphereNormal, tangent));
  // Rebuild the mapped surface normal with enough strength for crater walls
  // to catch the light. This normal is only used for local relief below; the
  // astronomical terminator continues to use the geometric sphere normal.
  const float normalStrength = 0.64;
  vec3 surfaceNormal = normalize(
    sphereNormal * max(mapNormal.z, 0.12) -
    tangent * mapNormal.x * normalStrength -
    bitangent * mapNormal.y * normalStrength
  );

  // New moon is phase 0, full moon is phase .5.
  float angle = uPhase * 2.0 * PI;
  vec3 sunDirection = normalize(vec3(sin(angle), 0.06, -cos(angle)));
  float geometricIncidence = dot(sphereNormal, sunDirection);
  float surfaceIncidence = dot(surfaceNormal, sunDirection);
  // Preserve the sphere's broad light falloff instead of lifting the whole
  // illuminated side toward the same value.
  float directLight = pow(max(geometricIncidence, 0.0), 0.68);
  float relief = clamp(
    1.0 + (surfaceIncidence - geometricIncidence) * 1.45,
    0.62,
    1.36
  );
  // Fade mapped relief in after the geometric terminator and before the
  // outermost limb. This keeps the phase silhouette soft and stable while
  // retaining strong crater contrast across the visible illuminated face.
  float reliefLightMask = smoothstep(0.015, 0.22, geometricIncidence);
  float reliefLimbMask = smoothstep(0.015, 0.16, sphereNormal.z);
  directLight *= mix(1.0, relief, reliefLightMask * reliefLimbMask);

  // Earthshine keeps texture visible on the dark side and becomes slightly
  // stronger near the terminator, avoiding a hard black cutout.
  float terminatorBounce = smoothstep(-0.82, 0.10, geometricIncidence);
  float earthshine = 0.065 + 0.105 * terminatorBounce;
  float limb = pow(max(sphereNormal.z, 0.0), 0.12);
  float luminance = dot(albedo, vec3(0.299, 0.587, 0.114));
  vec3 neutralAlbedo = mix(albedo, vec3(luminance), 0.30);
  vec3 coolMoon = neutralAlbedo * vec3(0.76, 0.86, 1.0);
  float moonLight = earthshine + directLight * 0.86;
  // Compress the brightest crater slopes so the surface keeps a soft
  // blue-grey cast instead of turning into hard, silvery highlights.
  moonLight = moonLight / (0.82 + moonLight * 0.30);
  vec3 color = coolMoon * moonLight * limb;

  // Soft halo, strongest around a full moon.
  float fullMoon = pow(max(0.0, -cos(angle)), 4.0);
  float outside = max(length(disk) - 1.0, 0.0);
  float halo = exp(-outside * 20.0) * fullMoon * 0.16;
  float haloMask = (1.0 - edge) * step(length(disk), 1.18);

  fragColor = vec4(color * edge + vec3(0.70, 0.78, 1.0) * halo * haloMask,
                   edge + halo * haloMask);
}
