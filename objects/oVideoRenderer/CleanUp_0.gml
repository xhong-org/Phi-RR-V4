/// @description Release frame and encoder resources.
if (encoder_started && !encoder_finished) video_renderer_finish();
if (surface_exists(overlay_surface)) surface_free(overlay_surface);
overlay_surface = -1;
if (font_exists(ui_font)) font_delete(ui_font);
ui_font = -1;
audio_master_gain(1);
if (variable_global_exists("render_cli") && !global.render_cli) global.render_mode = false;
