/// @description 第一次启动自动检测读取
start = false;
event_user(0);
event_user(8);

if(self[$ "isExists"]){
	event_user(1);
}

start = true;