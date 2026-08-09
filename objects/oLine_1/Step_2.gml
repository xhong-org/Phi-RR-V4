/// @description Apply parent transform + screen mapping after all lines evaluated
// Parent transform uses RPE coordinate-space conversion (notes/rpe_parse).
// End Step runs after every line finished writing __raw_* this frame.
// Parent world position is resolved with a small stack (no nested function defs).

if (variable_global_exists("game") && is_struct(game) && game.paused) then exit;

var out_x = __raw_x;
var out_y = __raw_y;
var out_r = __raw_r;

if (is_array(_father_chain) && array_length(_father_chain) > 0) {
                var chain = _father_chain;
                // Resolve world position of immediate parent by folding ancestors from root
                var wx = 0;
                var wy = 0;
                var have_world = false;
                for (var ai = array_length(chain) - 1; ai >= 0; ai--) {
                        var ainst = chain[ai];
                        if (!instance_exists(ainst) || !variable_instance_exists(ainst, "__raw_x")) {
                                have_world = false;
                                break;
                        };
                        var lx = ainst.__raw_x;
                        var ly = ainst.__raw_y;
                        if (!have_world) {
                                // root ancestor: world == local
                                wx = lx;
                                wy = ly;
                                have_world = true;
                        } else {
                                // convert this ancestor local into current world using its parent world
                                // parent for this node is the previously folded world (wx,wy) with parent local angle
                                var pinst = chain[ai + 1];
                                var pr = pinst.__raw_r;
                                var rad = degtorad(pr);
                                var cc = cos(rad);
                                var ss = sin(rad);
                                var nx = lx * cc + ly * ss + wx;
                                var ny = ly * cc - lx * ss + wy;
                                wx = nx;
                                wy = ny;
                        };
                };

                if (have_world) {
                        var pinst = chain[0];
                        if (instance_exists(pinst) && variable_instance_exists(pinst, "__raw_r")) {
                                var pr = pinst.__raw_r;
                                var rad = degtorad(pr);
                                var cc = cos(rad);
                                var ss = sin(rad);
                                out_x = __raw_x * cc + __raw_y * ss + wx;
                                out_y = __raw_y * cc - __raw_x * ss + wy;

                                if (rotFatherLine) {
                                        // accumulate ancestor local rotations root->leaf? child inherits parent world rotation
                                        for (var ri = array_length(chain) - 1; ri >= 0; ri--) {
                                                var rinst = chain[ri];
                                                if (instance_exists(rinst) && variable_instance_exists(rinst, "__raw_r")) {
                                                        out_r += rinst.__raw_r;
                                                };
                                        };
                                };
                        };
                };
};

// get_window_pos_scale: x*(W/1350)+W/2 , -y*(H/900)+H/2
x = out_x * (room_width / 1350) + room_width * 0.5;
y = -out_y * (room_height / 900) + room_height * 0.5;
image_angle = -out_r;
image_blend = __color;

__x = x;
__y = y;
__r = image_angle;
__cos = dcos(image_angle);
__sin = dsin(image_angle);
// attachUI: push line transform into oRender_1.bindUI (PCR-aligned), hide line draw
// PCR stores center-relative offset: posx = x - scene_width_half, posy = y - scene_height_half
// HUD final pos = default_layout_pos + offset (NOT hard absolute line xy)
// Keep the raw value for PE negative-alpha note semantics, but saturate the
// drawable value. Multi-layer RPE charts commonly sum to 510/1020/1530.
var ui_alpha = clamp(__raw_a / 255, 0, 1);
_alpha_decimal = __raw_a;
if (is_attach_ui && is_string(attach_ui_key) && string_length(attach_ui_key) > 0 && instance_exists(oRender_1)) {
        var ui_off_x = x - (room_width * 0.5);
        var ui_off_y = y - (room_height * 0.5);
        with (oRender_1) {
                if (is_struct(bindUI) && struct_exists(bindUI, other.attach_ui_key)) {
                        var slot = bindUI[$ other.attach_ui_key];
                        if (!is_array(slot) || array_length(slot) < 7) {
                                slot = array_create(7, 0);
                                bindUI[$ other.attach_ui_key] = slot;
                        };
                        // [offX, offY, color, alpha, rot, scaleX, scaleY]
                        slot[@ 0] = ui_off_x;
                        slot[@ 1] = ui_off_y;
                        slot[@ 2] = other.image_blend;
                        slot[@ 3] = ui_alpha;
                        slot[@ 4] = other.image_angle;
                        slot[@ 5] = other.__scale_x;
                        slot[@ 6] = other.__scale_y;
                        if (is_struct(bindUI_attached)) then bindUI_attached[$ other.attach_ui_key] = true;
                };
        };
        // PCR: attached line is not drawn (enabled=false)
        image_alpha = 0;
} else {
        image_alpha = ui_alpha;
};
