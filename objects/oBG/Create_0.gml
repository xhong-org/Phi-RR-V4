/// @description Background instance (YYC-safe, accepts asset refs)
depth = DEPTH.BG;
surface = -1;
size = [ room_width , room_height ];
image_blend = c_white;
enableBlur = (variable_global_exists("game") && is_struct(game) && is_struct(game.settings) ? bool(game.settings.enableBlur) : false);

if (!(variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg))) {
        instance_destroy();
        exit;
};

// Keep sprite_add default origin (top-left).
// Forcing center origin here re-breaks cover size (same as Background() sprite_set_offset).
