///@desc 窗口缩放变化后刷新 RPE 音符缩放
var note_scale = (global_scales / 6) * game.settings.noteSize;
image_xscale = note_scale * size;
image_yscale = bool(game.settings.noteUniformScale ?? false) ? image_xscale : note_scale;
