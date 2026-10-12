///@desc 释放结算精灵和结算音乐
if (variable_instance_exists(id, "settlement_stop_audio") && is_method(settlement_stop_audio)) {
	settlement_stop_audio();
};
if (variable_instance_exists(id, "illustration_owned") && illustration_owned
	&& asset_sprite_valid(illustration)) {
	var bg_spr = (variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg)) ? game.bg : -1;
	// 和谱面背景是同一张时不能删。
	if (illustration != bg_spr) then sprite_delete(illustration);
};
illustration = -1;
illustration_owned = false;
if (variable_instance_exists(id, "rank_sprite") && asset_sprite_valid(rank_sprite)) then sprite_delete(rank_sprite);
rank_sprite = -1;
if (variable_instance_exists(id, "head_sprite") && asset_sprite_valid(head_sprite)) then sprite_delete(head_sprite);
head_sprite = -1;
