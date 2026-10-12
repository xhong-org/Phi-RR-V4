///@desc 用户事件 8：检测音频文件是否存在
// 本地找不到时，GX 仍可能有宿主路径。
if(is_undefined(self[$ "name"]) || !chart_file_exists_any(self[$ "name"] ?? "")){
	if (media_use_gx() && string_length(gx_media_host_path_for(self[$ "name"] ?? ""))) {
		self[$ "isExists"] = true;
	} else {
		self[$ "isExists"] = false;
		print("[F-Sound] No Exists.");
	};
}else self[$ "isExists"] = true;