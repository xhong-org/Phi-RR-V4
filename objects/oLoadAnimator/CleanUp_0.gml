/// @description Release runtime artwork and font.
if (sprite_exists(clear_sprite)) then sprite_delete(clear_sprite);
if (sprite_exists(blur_sprite)) then sprite_delete(blur_sprite);
if (sprite_exists(panel_sprite)) then sprite_delete(panel_sprite);
if (font_exists(ui_font)) then font_delete(ui_font);
if (variable_global_exists("loading_animation_active")
        && (!variable_global_exists("loading_animator_finished") || !global.loading_animator_finished)) {
    global.loading_animation_active = false;
};
if (variable_global_exists("load_animator_instance")
        && global.load_animator_instance == id) {
    global.load_animator_instance = noone;
};
