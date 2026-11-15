#version 120

/* =====================================================================
 *  gbuffers_entities.fsh  --  FULL ENTITY PASS
 *
 *  Output alpha is built explicitly:
 *
 *      vec4(albedo.rgb * lm.rgb * color.rgb,  albedo.a * color.a)
 *
 *  Do NOT multiply lm.a in. The lightmap texture's alpha channel is 0, so
 *  a whole-vec4 multiply drives every entity to alpha 0 -- with blending
 *  on that hides players completely. That was the "players disappeared"
 *  regression. Alpha comes from the texture and the vertex colour only.
 *
 *  The nametag plate is identified by its vertex colour being black (the
 *  black box MC draws behind the name). Testing "unlit + dark" instead
 *  does not work: the plate is lit, so that test never fires and the box
 *  survives. Players are explicitly exempt so they can never be discarded
 *  by mistake.
 * ===================================================================== */

#include "/settings.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform int fogMode;
uniform int entityId;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;
varying float vXray;

void main() {
    vec4 albedo = texture2D(texture, texcoord.st);

    // Unset lightmap coordinate == this layer was drawn unlit.
    bool unlit = (lmcoord.x < 0.02 && lmcoord.y < 0.02);

    /* ---- blob shadow ---------------------------------------------- */
    bool isShadow = (entityId == ID_SHADOW);
    if (entityId != ID_SHADOW && entityId != ID_NAMETAG) {
        bool whiteVertex = (color.r > 0.9 && color.g > 0.9 && color.b > 0.9);
        isShadow = unlit && color.a < 0.99 && whiteVertex;
    }

#ifdef NO_ENTITY_SHADOW
    if (isShadow) discard;
#endif

    /* ---- nametag plate --------------------------------------------
     * MC draws the box with a black vertex colour, which no entity model
     * uses (models multiply by white). That is a much sharper signal than
     * looking at the shaded result.
     */
    bool isPlayer = (entityId == ID_PLAYER);
    bool blackVertex = (color.r < 0.05 && color.g < 0.05 && color.b < 0.05);

#if defined(NAMETAG_BG) && NAMETAG_BG == 1
    if (!isPlayer && blackVertex) discard;        // clean names, no box
#endif

    vec4 lm = texture2D(lightmap, lmcoord.st);

    // Unlit overlays (nametag text, flame) are authored at full brightness.
    bool isOverlay = unlit && !isShadow;
    if (isOverlay) lm = vec4(1.0);

#ifdef NIGHT_VISION
    lm = texture2D(lightmap, vec2(1.0));
#endif

#ifdef XRAY_FULLBRIGHT
    if (vXray > 0.5) lm = texture2D(lightmap, vec2(1.0));
#endif

    vec4 col = vec4(albedo.rgb * lm.rgb * color.rgb, albedo.a * color.a);

#if defined(NAMETAG_BG) && NAMETAG_BG == 2
    if (!isPlayer && blackVertex) col = vec4(0.0, 0.0, 0.0, 0.40);
#endif

#ifdef XRAY_DEBUG
    if (vXray > 0.5) col.rgb = vec3(1.0, 0.0, 1.0);
#endif

    bool applyFog = true;
#ifdef XRAY_NOFOG
    if (vXray > 0.5) applyFog = false;
#endif

    if (applyFog) {
        if (fogMode == 9729) {
            col.rgb = mix(gl_Fog.color.rgb, col.rgb,
                clamp((gl_Fog.end - gl_FogFragCoord) / (gl_Fog.end - gl_Fog.start), 0.0, 1.0));
        } else if (fogMode == 2048) {
            col.rgb = mix(gl_Fog.color.rgb, col.rgb,
                clamp(exp(-gl_FogFragCoord * gl_Fog.density), 0.0, 1.0));
        }
    }

    gl_FragData[0] = col;
}
