if (!paused_ui_can_control() || (!game.paused && !retry_waiting)) then exit;

if (!draw_logged) {
        draw_logged = true;
        print("[PausedUI] Draw visible");
};

var old_colour = draw_get_colour();
var old_alpha = draw_get_alpha();
var fade = clamp((get_timer() - opened_at) / 100000, 0, 1);
var countdown_progress = retry_waiting
        ? clamp((get_timer() - retry_started_at) / retry_delay, 0, 1)
        : 0;
var overlay_alpha = retry_waiting
        ? (retry_mode == 2 ? 0.6 * (1 - countdown_progress) : 0.6)
        : (0.6 * fade);

draw_set_colour(c_black);
draw_set_alpha(overlay_alpha);
draw_rectangle(0, 0, room_width, room_height, false);

draw_set_colour(c_white);
draw_set_alpha(retry_waiting ? 1 : fade);
if (retry_waiting && retry_mode == 2) {
        var seconds_left = max(1, ceil((retry_delay - (get_timer() - retry_started_at)) / 1000000));
        draw_set_font(game.font);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed(room_width * 0.5, room_height * 0.5, string(seconds_left),
                1.4 * ui_scale, 1.4 * ui_scale, 0);
        //draw_set_halign(fa_left);
        //draw_set_valign(fa_top);
} else if (!retry_waiting) {
        var base_scale = 0.9 * ui_scale;
        for (var i = 0; i < 3; i++) {
                var sprite = button_sprite[i];
                var hover_scale = button_hover[i] ? 1.1 : 1;
                var scale = base_scale * hover_scale;
                var draw_x = button_x[i] - sprite_get_width(sprite) * scale * 0.5;
                var draw_y = button_y - sprite_get_height(sprite) * scale * 0.5;
                draw_sprite_ext(sprite, 0, draw_x, draw_y, scale, scale, 0,
                        button_hover[i] ? make_colour_rgb(210, 235, 255) : c_white, fade);
        };
};

draw_set_colour(old_colour);
draw_set_alpha(old_alpha);
