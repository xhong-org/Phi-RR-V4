///@desc 创建：第一次启动时自动检测并读取
start = false;
event_user(0);
event_user(8);

// 文件存在才进入读取。
if(self[$ "isExists"]){
	event_user(1);
}

start = true;