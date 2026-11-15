#version 120

/* =====================================================================
 *  gbuffers_terrain.vsh  --  BEDS
 *
 *  mc_Entity.x carries the ID that block.properties assigned to this
 *  block, or -1.0 if the block is not listed. Beds use the same original
 *  depth trick: clip-space Z * 0.01.
 * ===================================================================== */

#include "/settings.glsl"

attribute vec4 mc_Entity;   // .x = block ID from block.properties

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

#ifdef XRAY_BEDS
    if (xrayAllowed() && isBedId(mc_Entity.x)) {
        gl_Position.z *= 0.01;
        vXray = 1.0;
    }
#endif
}
