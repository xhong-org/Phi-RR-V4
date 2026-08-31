/// @description 用于检测文件存在问题
if(is_undefined(self[$ "name"]) || !chart_file_exists_any(self[$ "name"] ?? "")){
	self[$ "isExists"] = false;
	print("[F-Sound] No Exists.");
}else self[$ "isExists"] = true;