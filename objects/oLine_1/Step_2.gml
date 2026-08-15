/// @description Apply parent transform + screen mapping after all lines evaluated
// Parent transform uses RPE coordinate-space conversion (notes/rpe_parse).
// End Step runs after every line finished writing __raw_* this frame.
// Parent world position is resolved with a small stack (no nested function defs).

var _transition_updates = instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "play_transition_active")
	&& bool(oRender_1.play_transition_active);
if (variable_global_exists("game") && is_struct(game) && game.paused
	&& !_transition_updates) then exit;

var out_x = __raw_x;
var out_y = __raw_y;
var out_r = __raw_r;

if (is_array(_father_chain) && array_length(_father_chain) > 0) {
                var chain = _father_chain;
                var parent_world_x = 0;
                var parent_world_y = 0;
                var parent_world_r = 0;
                var have_parent = false;

                // Fold root -> immediate parent so nested lines use the same
                // transform rules as the renderer's non-worker path.
                for (var ai = array_length(chain) - 1; ai >= 0; ai--) {
                        var ancestor = chain[ai];
                        if (!instance_exists(ancestor) || !variable_instance_exists(ancestor, "__raw_x")) {
                                have_parent = false;
                                break;
                        };
                        if (!have_parent) {
                                parent_world_x = ancestor.__raw_x;
                                parent_world_y = ancestor.__raw_y;
                                parent_world_r = ancestor.__raw_r;
                                have_parent = true;
                        } else {
                                var parent_cos = dcos(parent_world_r);
                                var parent_sin = dsin(parent_world_r);
                                parent_world_x += ancestor.__raw_x * parent_cos + ancestor.__raw_y * parent_sin;
                                parent_world_y += ancestor.__raw_y * parent_cos - ancestor.__raw_x * parent_sin;
                                parent_world_r = ancestor.__raw_r
                                        + (bool(ancestor.rotFatherLine) ? parent_world_r : 0);
                        };
                };

                if (have_parent) {
                        var parent_cos = dcos(parent_world_r);
                        var parent_sin = dsin(parent_world_r);
                        out_x = parent_world_x + __raw_x * parent_cos + __raw_y * parent_sin;
                        out_y = parent_world_y + __raw_y * parent_cos - __raw_x * parent_sin;
                        if (rotFatherLine) then out_r += parent_world_r;
                };
};

// Map RPE coordinates into Phira's effective viewport. Narrow windows keep
// their full height; only the horizontal area is limited by chart aspect.
var chart_aspect = 16 / 9;
var chart_view_h = room_height;
var chart_view_w = min(room_width, chart_view_h * chart_aspect);
x = out_x * (chart_view_w / 1350) + room_width * 0.5;
y = -out_y * (chart_view_h / 900) + room_height * 0.5;
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
