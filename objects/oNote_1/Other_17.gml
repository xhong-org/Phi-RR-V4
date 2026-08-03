/// @description Refresh note scale after window scale change
image_xscale = (global_scales / 6) * size;
image_yscale = bool(game.settings.noteUniformScale ?? false) ? image_xscale : (global_scales / 6);
