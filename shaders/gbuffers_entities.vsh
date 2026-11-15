#version 120

/* =====================================================================
 *  gbuffers_entities.vsh  --  ORIGINAL METHOD
 *
 *  This is the original pack's vertex shader, verbatim in spirit:
 *
 *      if (hideGUI == false) gl_Position.z *= 0.01;
 *
 *  No entity filtering, no entity.properties, no remapping of the depth
 *  range -- just scale clip-space Z by 0.01 so the whole entity pass lands
 *  at depth ~= 0.5 (~0.1 blocks from the eye) and wins GL_LEQUAL against
 *  every wall. It drags mobs and dropped items along with players, which
 *  is exactly what the original did.
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

#ifdef XRAY_PLAYERS
    if (xrayAllowed()) {
        gl_Position.z *= 0.01;
        vXray = 1.0;
    }
#endif
}
