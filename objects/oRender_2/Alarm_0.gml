///@desc 媒体就绪后开始 PEC 播放
var is_exists = false,
	success = false;
with(oMedia){
	is_exists = (self[$ "isExists"]);
	success = (self[$ "success"]);
};
//with(oNote){ canDraw = true; };
// 音频还没准备好就先不开播。
if(!is_exists || !success) then exit;

print("Playing" , game.settings.enableDebug);

m_play();

game.Math.now(0);
game.paused = false;