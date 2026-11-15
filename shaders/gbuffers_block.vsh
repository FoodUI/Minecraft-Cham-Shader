#version 120

/* =====================================================================
 *  gbuffers_block.vsh  --  CHESTS / BLOCK ENTITIES
 *
 *  gbuffers_block renders block entities: chests, trapped chests, ender
 *  chests, barrels, shulker boxes, signs, banners, beacon beams, the
 *  enchanting table book...
 *
 *  mc_Entity is not available here, so this pass shares one switch -- the
 *  same trade-off the original pack made for its single pass. Chests and
 *  ender chests both land in it.
 * ===================================================================== */

#include "/settings.glsl"

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;
varying float vXray;

void main() {
    gl_Position = ftransform();
    gl_FogFragCoord = length((gl_ModelViewMatrix * gl_Vertex).xyz);

    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    lmcoord  = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    color    = gl_Color;

    vXray = 0.0;

#ifdef XRAY_CHESTS
    if (xrayAllowed()) {
        gl_Position.z *= 0.01;
        vXray = 1.0;
    }
#endif
}
