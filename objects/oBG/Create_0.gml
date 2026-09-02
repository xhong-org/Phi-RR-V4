/// @description Background instance (YYC-safe, accepts asset refs)
// Background must be behind chart lines, notes, UI, and effects.
depth = DEPTH.BG;
surface = -1;
size = [ room_width , room_height ];
image_blend = c_white;
enableBlur = (variable_global_exists("game") && is_struct(game) && is_struct(game.settings) ? bool(game.settings.enableBlur) : false);

if (!(variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg))) {
        instance_destroy();
        exit;
};

if (asset_sprite_valid(game.bg)) {
        var _bw = sprite_get_width(game.bg);
        var _bh = sprite_get_height(game.bg);
        if (_bw > 0 && _bh > 0) then sprite_set_offset(game.bg, _bw * 0.5, _bh * 0.5);
};
