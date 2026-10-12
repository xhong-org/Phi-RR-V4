///@desc 按屏幕宽度重排 GX 菜单按钮
if (!variable_global_exists("global_scales")) {
        globalvar global_scales;
        global_scales = 1.0;
};

var s = global_scales;
if (!is_real(s) || s <= 0) then s = 1.0;

var rw = max(1, room_width);
var rh = max(1, room_height);
var gap = max(12, 18 * s);
var btn_h = min(rh * 0.13, 92 * s);
// 远程少一个 API 按钮。
var remote = pls_is_gx_remote();
var count = remote ? 2 : 3;
var btn_w = min((rw - gap * (count + 1)) / count, 280 * s);
var total = count * btn_w + (count - 1) * gap;
var x0 = (rw - total) * 0.5;
var yy = rh * 0.44;

pick_x = x0;
pick_y = yy;
pick_w = btn_w;
pick_h = btn_h;

drop_btn_x = x0 + btn_w + gap;
drop_btn_y = yy;
drop_btn_w = btn_w;
drop_btn_h = btn_h;

if (remote) {
        api_btn_x = 0;
        api_btn_y = 0;
        api_btn_w = 0;
        api_btn_h = 0;
} else {
        api_btn_x = x0 + 2 * (btn_w + gap);
        api_btn_y = yy;
        api_btn_w = btn_w;
        api_btn_h = btn_h;
};

drop_x = pick_x;
drop_y = pick_y;
drop_w = pick_w;
drop_h = pick_h;

layout_w = rw;
layout_h = rh;
layout_scale = s;
settings_menu_button_layout();
