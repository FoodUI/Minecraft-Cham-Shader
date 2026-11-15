/* =====================================================================
 *  [Cham] Inner-See-Through Plus - global settings
 *
 *  Every #define becomes an entry in the "Shader Pack Settings" screen.
 *  A commented-out #define still creates the option, defaulting to off.
 * ===================================================================== */

// ---------------- X-ray targets ----------------
#define XRAY_PLAYERS          // gbuffers_entities : whole entity pass
#define XRAY_CHESTS           // gbuffers_block    : chests, ender chests, barrels...
#define XRAY_BEDS             // gbuffers_terrain  : beds

// ---------------- Visual ----------------
//#define NIGHT_VISION        // fullbright for the whole world
#define NO_ENTITY_SHADOW      // drop the vanilla blob shadow under entities
#define XRAY_FULLBRIGHT       // x-ray targets ignore the lightmap
#define XRAY_NOFOG            // x-ray targets ignore fog

// ---------------- Advanced ----------------
#define XRAY_F1_PANIC         // F1 (hide HUD) also turns x-ray off
//#define XRAY_DEBUG          // paint every x-rayed fragment magenta

/* Nametag plate style. The plate is the black box behind the name; the
 * engine's translucency does not survive the shader pipeline reliably, so
 * we decide here.
 *   0 = leave it to the engine (original look)
 *   1 = drop the plate, names are plain text
 *   2 = draw our own translucent box (alpha 0.40)
 */
#define NAMETAG_BG 1 // [0 1 2]

uniform bool hideGUI;

/* Entity IDs from entity.properties. Only used to tell the blob shadow
 * and nametag layers apart; the x-ray itself no longer filters by entity
 * type, so these are optional.
 */
const int ID_PLAYER   = 1;   // minecraft:player
const int ID_SHADOW   = 2;   // minecraft:entity_shadow (Iris built-in)
const int ID_NAMETAG  = 3;   // minecraft:name_tag      (Iris built-in)

/* Bed ID band from block.properties. A band instead of one exact value
 * because loaders have disagreed about storing the ID or the ID - 1.
 */
const float BED_ID_MIN = 10100.0;
const float BED_ID_MAX = 10120.0;

/* The original gate from the pack this started from: x-ray is on unless
 * the HUD is hidden with F1.
 */
bool xrayAllowed() {
#ifdef XRAY_F1_PANIC
    return hideGUI == false;
#else
    return true;
#endif
}

bool isBedId(float id) {
    if (id >= BED_ID_MIN && id <= BED_ID_MAX) return true;
    return id == 26.0;   // legacy minecraft:bed (1.8 - 1.11)
}
