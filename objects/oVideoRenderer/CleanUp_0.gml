///@desc 结束编码器并释放录像覆盖层
// 编码器开了但还没正常收尾时补一次结束。
if (encoder_started && !encoder_finished) video_renderer_finish();
if (surface_exists(overlay_surface)) surface_free(overlay_surface);
overlay_surface = -1;
pls_ui_font_release_instance();
audio_master_gain(1);
if (variable_global_exists("render_cli") && !global.render_cli) global.render_mode = false;
