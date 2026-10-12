///@desc 窗口缩放变化后刷新 RPE 音符缩放
image_xscale = (global_scales / 6) * size;
image_yscale = bool(game.settings.noteUniformScale ?? false) ? image_xscale : (global_scales / 6);
