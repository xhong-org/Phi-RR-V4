///@desc 创建：背景实例，接受精灵资源引用
// 背景必须画在判定线、音符、界面和特效后面。
depth = DEPTH.BG;
surface = -1;
size = [ room_width , room_height ];
image_blend = c_white;
enableBlur = (variable_global_exists("game") && is_struct(game) && is_struct(game.settings) ? bool(game.settings.enableBlur) : false);

// 没有可用背景图就不要留着这个实例。
if (!(variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg))) {
        instance_destroy();
        exit;
};

// 把精灵原点放到中心，方便铺满视口。
if (asset_sprite_valid(game.bg)) {
        var _bw = sprite_get_width(game.bg);
        var _bh = sprite_get_height(game.bg);
        if (_bw > 0 && _bh > 0) then sprite_set_offset(game.bg, _bw * 0.5, _bh * 0.5);
};
