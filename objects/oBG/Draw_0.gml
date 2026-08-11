/// @description BG draw: cover room, keep aspect, then dim overlay
if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings) && game.settings.showBG)) then exit;
if (!asset_sprite_valid(game.bg)) then exit;

BYD_COLOR_FUNC;
else image_blend = c_white;

var bw = sprite_get_width(game.bg);
var bh = sprite_get_height(game.bg);
if (bw <= 0 || bh <= 0) then exit;

// Cover-fit: fill room, crop overflow, preserve aspect ratio.
// Origin is top-left (sprite_add default); position so the scaled sprite is centered.
var sx = room_width / bw;
var sy = room_height / bh;
var sc = max(sx, sy);
var dw = bw * sc;
var dh = bh * sc;
var dx = (room_width) * 0.5;
var dy = (room_height) * 0.5;
var transition_alpha = 1;
if (instance_exists(oPlayTransition)) {
	var transition = instance_find(oPlayTransition, 0);
	if (instance_exists(transition.owner) && transition.owner.play_transition_active) {
		transition_alpha = transition.owner.play_transition_bg_alpha;
	};
};

draw_sprite_ext(game.bg, 0, dx, dy, sc, sc, 0, image_blend, 1);

// Dim overlay in room space.
if (sprite_exists(spr_black)) {
        var sw = max(1, sprite_get_width(spr_black));
        var sh = max(1, sprite_get_height(spr_black));
        // spr_black also uses top-left origin; stretch from (0,0).
        draw_sprite_ext(spr_black, 0, dx, dy, room_width / sw, room_height / sh, 0, c_black, 0.6 * transition_alpha);
} else {
        draw_set_alpha(0.6 * transition_alpha);
        draw_set_colour(c_black);
        draw_rectangle(0, 0, room_width, room_height, false);
        draw_set_alpha(1);
};
