/// @description 
var is_exists = false,
	success = false;
with(oMedia){
	is_exists = (self[$ "isExists"]);
	success = (self[$ "success"]);
};
if(!is_exists || !success) then exit;

print("Playing" , game.settings.enableDebug);
m_play();
game.Math.now(0);
game.paused = false;
print($"notes count: {instance_number(oNote_1)}" , game.settings.enableDebug);
