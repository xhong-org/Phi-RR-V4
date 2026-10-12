///@desc 步进结束：所有线求值后再做父级变换和屏幕映射
// RPE 在父级旋转之前，用视口宽/1350 和视口高/900 缩放子级偏移。
// 步进结束时，每条线这一帧的 __raw_* 都已经写完。

// 加载动画或暂停时不做屏幕映射，除非强制初始化或转场还在更新。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !rpe_force_event_init) then exit;
var _transition_updates = instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "play_transition_active")
	&& bool(oRender_1.play_transition_active);
if (variable_global_exists("game") && is_struct(game) && game.paused
	&& !_transition_updates && !rpe_force_event_init) then exit;

// 姿态已经是视图像素。高度用窗口高度。只有水平范围受谱面宽高比限制。
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
// attachUI：把线的变换写进 oRender_1.bindUI（对齐 PCR），并隐藏线的绘制。
// PCR 存的是相对中心的偏移：posx = x - 场景半宽，posy = y - 场景半高。
// 界面最终位置 = 默认布局位置 + 偏移，不是线的绝对坐标。
// 原始值留给 PE 的负透明度音符语义，可绘制值再夹取。
// 多层 RPE 谱的透明度相加后经常是 510、1020 或 1530。
var ui_alpha = clamp(__raw_a / 255, 0, 1);
_alpha_decimal = __raw_a;
if (is_attach_ui && is_string(attach_ui_key) && string_length(attach_ui_key) > 0
        && instance_exists(oRender_1) && variable_instance_exists(oRender_1, "bindUI")) {
		var ui_off_x = x - (chart_view_left + chart_view_w * 0.5);
		var ui_off_y = y - (chart_view_h * 0.5);
        with (oRender_1) {
                if (is_struct(bindUI) && struct_exists(bindUI, other.attach_ui_key)) {
                        var slot = bindUI[$ other.attach_ui_key];
                        // 槽不够长就重建，避免写越界。
                        if (!is_array(slot) || array_length(slot) < 7) {
                                slot = array_create(7, 0);
                                bindUI[$ other.attach_ui_key] = slot;
                        };
                        // 槽位：[offX, offY, color, alpha, rot, scaleX, scaleY]
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
        // PCR：绑定界面的线不绘制（enabled=false）。
        image_alpha = 0;
} else {
        image_alpha = ui_alpha;
};
