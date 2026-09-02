/// @description 用于检测文件存在问题
if(is_undefined(self[$ "name"]) || !chart_file_exists_any(self[$ "name"] ?? "")){
	if (media_use_gx() && string_length(gx_media_host_path_for(self[$ "name"] ?? ""))) {
		self[$ "isExists"] = true;
	} else {
		self[$ "isExists"] = false;
		print("[F-Sound] No Exists.");
	};
}else self[$ "isExists"] = true;