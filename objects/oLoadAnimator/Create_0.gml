/// @description Loading UI animator. The async loader owns chart preparation.
if (variable_global_exists("load_animator_instance")
        && instance_exists(global.load_animator_instance)) {
    instance_destroy();
    exit;
};
global.load_animator_instance = id;

enum LOAD_ANIM_STATE {
    PREPARING,
    COVERING,
    REVEALING,
    HOLDING,
    EXITING
};

state = LOAD_ANIM_STATE.PREPARING;
started_at = current_time;
intro_started_at = -1;
cover_duration = 900;
reveal_duration = 500;
exit_duration = 1000;
exit_wait_duration = 1000;
ready_hold_duration = 2000;
ready_at = -1;
exit_started_at = -1;
exit_finished_at = -1;
loading_rect_duration = 1.0;
loading_rect_elapsed = 0;
loading_rect_phase = 0;
loading_rect_scale = 0;
loading_rect_width_design = 0;
loading_rect_height_design = 0;
target_room = -1;
chart_ready = false;
clear_sprite = -1;
blur_sprite = -1;
panel_sprite = -1;
assets_loaded = false;
ui_font = -1;
global.loading_animation_load_start = false;
global.loading_render_ready = false;
global.loading_animator_finished = false;
global.loading_animation_active = true;
tips = [];
tip_index = 0;

var _tips_path = working_directory + "resource/tips.txt";
if (file_exists(_tips_path)) {
    var _tips_file = file_text_open_read(_tips_path);
    while (!file_text_eof(_tips_file)) {
        var _tip = string_trim(file_text_readln(_tips_file));
        if (string_length(_tip) > 0) then array_push(tips, _tip);
    };
    file_text_close(_tips_file);
};
if (array_length(tips) == 0) then array_push(tips, lang("loadAnim.tipsFallback"));
tip_index = irandom(array_length(tips) - 1);

ui_font = pls_ui_font_add(35, false, false, -infinity, infinity, false);
// Cache the loading box dimensions once. Draw must only animate its scale;
// recalculating the base width every frame can make the box drift when draw
// state or the UI scale changes.
draw_set_font(ui_font);
var _loading_font_width = string_width(lang("loadAnim.loading")) * 0.5;
var _loading_font_height = string_height(lang("loadAnim.loading")) * 0.5;
loading_rect_width_design = _loading_font_width + 40;
loading_rect_height_design = _loading_font_height + 30;

// High-resolution black parallelogram. Its corners stay fixed through nine-slice scaling.
var _panel_surface = surface_create(512, 256);
if (surface_exists(_panel_surface)) {
    surface_set_target(_panel_surface);
    draw_clear_alpha(c_black, 0);
    draw_set_colour(c_black);
    draw_triangle(128, 0, 512, 0, 384, 256, true);
    draw_triangle(128, 0, 384, 256, 0, 256, true);
    surface_reset_target();
    panel_sprite = sprite_create_from_surface(_panel_surface, 0, 0, 512, 256, false, true, 0, 0);
    surface_free(_panel_surface);
    if (sprite_exists(panel_sprite)) {
        var _slice = sprite_nineslice_create();
        _slice.enabled = true;
        _slice.left = 128;
        _slice.right = 128;
        _slice.top = 64;
        _slice.bottom = 64;
        _slice.tilemode[nineslice_centre] = nineslice_stretch;
        sprite_set_nineslice(panel_sprite, _slice);
    };
};
/// 绘制填充平行四边形（锐角 75°）
/// 参数：px, py 为左下角起点坐标；pw 为底边长度；ph 为高；col 为颜色

function draw_parallelogram_fill(px, py, pw, ph, col) {
    // 锐角（75°）转弧度
    var ang = degtorad(75);

    // 顶点坐标计算
    var x1 = px;
    var y1 = py; // 左下角

    var x2 = px + pw;
    var y2 = py; // 右下角

    var x3 = x2 + ph / tan(ang);
    var y3 = py - ph; // 右上角

    var x4 = x1 + ph / tan(ang);
    var y4 = py - ph; // 左上角

    // 绘制填充图形
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(x1, y1, col, 1);
    draw_vertex_color(x2, y2, col, 1);
    draw_vertex_color(x3, y3, col, 1);
    draw_vertex_color(x4, y4, col, 1);
    draw_primitive_end();
}

/// 将目标 sprite 放大到 1080p 16:9 后再裁成 75° 平行四边形。
/// @param {Asset.GMSprite} target_spr
function sprite_parallelogram_fixed(target_spr) {
    if (!sprite_exists(target_spr)) then return -1;
    var src_w = sprite_get_width(target_spr);
    var src_h = sprite_get_height(target_spr);
    if (src_w <= 0 || src_h <= 0) then return -1;

    var box_w = pls_is_gxgames() ? 960 : 1920;
    var box_h = pls_is_gxgames() ? 540 : 1080;
    var cover = max(box_w / src_w, box_h / src_h);
    var plate = surface_create(box_w, box_h);
    if (!surface_exists(plate)) then return -1;
    var _old_colour = draw_get_colour();
    var _old_alpha = draw_get_alpha();
    gpu_set_blendmode(bm_normal);
    surface_set_target(plate);
    draw_clear_alpha(c_black, 0);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    draw_sprite_ext(target_spr, 0, (box_w - src_w * cover) * 0.5, (box_h - src_h * cover) * 0.5,
        cover, cover, 0, c_white, 1);
    surface_reset_target();

    var offset = box_h / tan(degtorad(75));
    var surf = surface_create(box_w, box_h);
    if (!surface_exists(surf)) {
        surface_free(plate);
        draw_set_alpha(_old_alpha);
        draw_set_colour(_old_colour);
        return -1;
    };
    surface_set_target(surf);
    draw_clear_alpha(c_black, 0);
    var tex = surface_get_texture(plate);
    draw_primitive_begin_texture(pr_trianglefan, tex);
    draw_vertex_texture(0, box_h, 0, 1);
    draw_vertex_texture(box_w - offset, box_h, (box_w - offset) / box_w, 1);
    draw_vertex_texture(box_w, 0, 1, 0);
    draw_vertex_texture(offset, 0, offset / box_w, 0);
    draw_primitive_end();
    surface_reset_target();
    surface_free(plate);
    draw_set_alpha(_old_alpha);
    draw_set_colour(_old_colour);

    var spr_new = sprite_create_from_surface(surf, 0, 0, box_w, box_h, false, false, 0, 0);
    surface_free(surf);
    if (!sprite_exists(spr_new)) then return -1;
    sprite_set_offset(spr_new, box_w * 0.5, box_h * 0.5);
    return spr_new;
}


depth = -1000000;

/*
/// 裁剪 sprite 为锐角 75° 的平行四边形
/// 参数：target_spr 源 sprite；_spr_w, _spr_h 输入目标宽高
function sprite_parallelogram_clip(target_spr, _spr_w, _spr_h) {


    // 从 surface 创建新 sprite
    var spr_new = sprite_create_from_surface(surf, 0, 0, surface_get_width(surf), surface_get_height(surf), false, false, 0);

    // 释放 surface
    surface_free(surf);

    return spr_new;
}

