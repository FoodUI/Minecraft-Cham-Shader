#version 120

/* =====================================================================
 *  gbuffers_terrain.fsh
 *
 *  Vanilla terrain shading as the original pack wrote it -- a whole-vec4
 *  multiply, so texture alpha and vertex alpha both survive:
 *
 *      albedo * lightmap * color
 *
 *  Writing vec4(col.rgb, albedo.a) instead would drop the vertex alpha
 *  that tinted / translucent geometry relies on.
 * ===================================================================== */

#include "/settings.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform int fogMode;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;
varying float vXray;

void main() {
    vec4 albedo = texture2D(texture, texcoord.st);

    // Vanilla alpha test, needed for leaves / grass / flowers (cutout layer).
    if (albedo.a < 0.1) discard;

    vec4 lm = texture2D(lightmap, lmcoord.st);

#ifdef NIGHT_VISION
    lm = texture2D(lightmap, vec2(1.0));
#endif

#ifdef XRAY_FULLBRIGHT
    if (vXray > 0.5) lm = texture2D(lightmap, vec2(1.0));
#endif

    // rgb only: the lightmap alpha is 0 and would make everything transparent
    vec4 col = vec4(albedo.rgb * lm.rgb * color.rgb, albedo.a * color.a);

#ifdef XRAY_DEBUG
    if (vXray > 0.5) col.rgb = vec3(1.0, 0.0, 1.0);
#endif

    bool applyFog = true;
#ifdef XRAY_NOFOG
    if (vXray > 0.5) applyFog = false;
#endif

    if (applyFog) {
        if (fogMode == 9729) {          // GL_LINEAR
            col.rgb = mix(gl_Fog.color.rgb, col.rgb,
                clamp((gl_Fog.end - gl_FogFragCoord) / (gl_Fog.end - gl_Fog.start), 0.0, 1.0));
        } else if (fogMode == 2048) {   // GL_EXP
            col.rgb = mix(gl_Fog.color.rgb, col.rgb,
                clamp(exp(-gl_FogFragCoord * gl_Fog.density), 0.0, 1.0));
        }
    }

    gl_FragData[0] = col;
}
