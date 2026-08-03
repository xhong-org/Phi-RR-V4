/// @description 
var is_exists = false,
	success = false;
with(oMedia){
	is_exists = (self[$ "isExists"]);
	success = (self[$ "success"]);
};
with(oNote){ canDraw = true; };
if(!is_exists || !success) then exit;

print("Playing" , game.settings.enableDebug);
m_play();
game.Math.now(0);
game.paused = false;
print($"notes count: {instance_number(oNote)}" , game.settings.enableDebug);
