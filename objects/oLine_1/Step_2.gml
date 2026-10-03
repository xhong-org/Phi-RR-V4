/// @description Apply parent transform + screen mapping after all lines evaluated
// RPE scales a child offset by view/1350 and view/900 before the father rotation.
// End Step runs after every line finished writing __raw_* this frame.

if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !rpe_force_event_init) then exit;
var _transition_updates = instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "play_transition_active")
	&& bool(oRender_1.play_transition_active);
if (variable_global_exists("game") && is_struct(game) && game.paused
	&& !_transition_updates && !rpe_force_event_init) then exit;

// Pose is already in view pixels. Height is the window height.
// Only the horizontal area is limited by chart aspect.
var chart_view_h = chart_view_height;
var chart_view_w = chart_view_width;
var pose = rpe_line_view_pose(id, chart_view_w / 1350, chart_view_h / 900);
x = pose[0] + chart_view_left + chart_view_w * 0.5;
y = -pose[1] + chart_view_h * 0.5;
image_angle = -pose[2];
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
if (is_attach_ui && is_string(attach_ui_key) && string_length(attach_ui_key) > 0
        && instance_exists(oRender_1) && variable_instance_exists(oRender_1, "bindUI")) {
		var ui_off_x = x - (chart_view_left + chart_view_w * 0.5);
		var ui_off_y = y - (chart_view_h * 0.5);
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
