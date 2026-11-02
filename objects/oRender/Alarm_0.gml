///@desc 媒体就绪后开始官谱播放
var is_exists = false,
	success = false;
with(oMedia){
	is_exists = (self[$ "isExists"]);
	success = (self[$ "success"]);
};
{ var _actors_146 = chart_actor_list(oNote); for (var _actor_i_146 = 0; _actor_i_146 < array_length(_actors_146); _actor_i_146++) with (_actors_146[_actor_i_146]){ canDraw = true; } };
// 音频还没准备好就先不开播。
if(!is_exists || !success) then exit;
// 噪域还在收，先停在开头，避免开头几秒没有噪区。
if (official_block_pack_pending()) {
	official_blocks_pack_pump();
	alarm[0] = 1;
	exit;
};

print("Playing" , game.settings.enableDebug);
m_play();
game.Math.now(0);
game.paused = false;
print($"notes count: {chart_actor_number(oNote)}" , game.settings.enableDebug);
