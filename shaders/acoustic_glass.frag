// AcousticGlassPanel hardware shader.
// Draws the glass fill of a rounded panel: tint, inner luminosity border and
// a soft vertical sheen. The frost blur itself stays a compositor
// BackdropFilter pass (a runtime effect cannot sample the backdrop); this
// shader replaces the plain translucent color layer with a GPU-drawn one.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;               // logical panel size
uniform vec4 uTint;               // tint rgb + tint opacity (a)
uniform float uBorderLuminosity;  // 0..1 strength of the inner light edge
uniform float uCornerRadius;      // corner radius in logical px

out vec4 fragColor;

float roundedRectSDF(vec2 p, vec2 halfSize, float r) {
  vec2 q = abs(p) - halfSize + r;
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 center = uSize * 0.5;
  vec2 p = FlutterFragCoord() - center;
  float d = roundedRectSDF(p, center, uCornerRadius);

  // Full coverage inside the rounded rect, antialiased over ~1px at the edge.
  float inside = 1.0 - smoothstep(-1.0, 0.0, d);
  // Band hugging the inner edge, used for the luminous border.
  float edge = 1.0 - smoothstep(-2.5, -0.5, d);

  // Gentle top-to-bottom sheen so the panel reads as lit glass, not flat fill.
  float sheen = ((FlutterFragCoord().y / max(uSize.y, 1.0))) * 0.10;

  vec3 color = uTint.rgb + sheen;
  float alpha = uTint.a * inside + edge * uBorderLuminosity * 0.35;
  fragColor = vec4(color, clamp(alpha, 0.0, 1.0));
}
