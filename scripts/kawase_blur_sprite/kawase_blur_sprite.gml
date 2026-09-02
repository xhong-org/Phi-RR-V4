/*

								KawaseBlurStatic v1.0.1
								Code By XTHX_FORM
					------------------------------------------------
					||			本插件用于静态Kawase模糊			  ||
					||			支持输出图像文件					  ||
					||			也可以保存为索引以继续使用		  ||																								
					------------------------------------------------			
																						*/


/// @desc 图像偏移枚举
enum SPRITE_OFFSET {
	CUSTOM, // 自定义
	MIDDLE_CENTER, // 中心
	MIDDLE_LEFT, // 左中
	MIDDLE_RIGHT, // 右中
	MIDDLE_TOP, // 中上
	MIDDLE_BOTTOM, // 中下
	TOP_LEFT, // 左上
	TOP_RIGHT,// 右上
	BOTTOM_LEFT, // 左下
	BOTTOM_RIGHT, // 右下
};

/// @desc 图像偏移位置获取
/// @function sprite_get_offset_enum(w , h , offset_type)
/// @param		{float} w							- 图像的长
/// @param		{float} h							- 图像的宽
/// @param		{enum} offset_type					- 图像偏移枚举
/// @returns	{array[int]}						- 图像偏移坐标
function sprite_get_offset_enum(w , h , offset_type){
	if(offset_type == SPRITE_OFFSET.CUSTOM)	then	return([ 0 , 0 ]);
	switch(offset_type){
		case SPRITE_OFFSET.BOTTOM_LEFT:				return([ 0 , h ]);
		case SPRITE_OFFSET.BOTTOM_RIGHT:			return([ w , h ]);
		case SPRITE_OFFSET.TOP_LEFT:				return([ 0 , 0 ]);
		case SPRITE_OFFSET.TOP_RIGHT:				return([ w , 0 ]);
		case SPRITE_OFFSET.MIDDLE_BOTTOM:			return([ w / 2 , h ]);
		case SPRITE_OFFSET.MIDDLE_CENTER:			return([ w / 2 , h / 2 ]);
		case SPRITE_OFFSET.MIDDLE_LEFT:				return([ 0 , h / 2 ]);
		case SPRITE_OFFSET.MIDDLE_RIGHT:			return([ w , h / 2 ]);
		case SPRITE_OFFSET.MIDDLE_TOP:				return([ w / 2 , 0 ]);
		default:									return([ 0 , 0 ]);
	};
};

function kawase_blur_free_pair(surf_a, surf_b) {
	if (surface_exists(surf_a)) then surface_free(surf_a);
	if (surface_exists(surf_b)) then surface_free(surf_b);
}

function kawase_blur_downsample_fallback(sprite_id, subimg, dw, dh, offset_x, offset_y) {
	var surf_a = surface_create(dw, dh);
	var surf_b = surface_create(dw, dh);
	if (!surface_exists(surf_a) || !surface_exists(surf_b)) {
		kawase_blur_free_pair(surf_a, surf_b);
		return -1;
	};
	gpu_push_state();
	gpu_set_texfilter(true);
	gpu_set_blendmode(bm_normal);
	draw_set_alpha(1);
	surface_set_target(surf_a);
	draw_clear_alpha(c_black, 0);
	draw_sprite_stretched(sprite_id, subimg, 0, 0, dw, dh);
	surface_reset_target();
	var passes = pls_is_gxgames() ? 5 : 6;
	for (var i = 0; i < passes; i++) {
		var off = 1 + i;
		surface_set_target(surf_b);
		draw_clear_alpha(c_black, 0);
		draw_set_alpha(0.25);
		draw_surface(surf_a, -off, 0);
		draw_surface(surf_a, off, 0);
		draw_surface(surf_a, 0, -off);
		draw_surface(surf_a, 0, off);
		draw_set_alpha(1);
		surface_reset_target();
		var tmp = surf_a;
		surf_a = surf_b;
		surf_b = tmp;
	};
	var spr = sprite_create_from_surface(surf_a, 0, 0, dw, dh, false, false, offset_x, offset_y);
	kawase_blur_free_pair(surf_a, surf_b);
	gpu_pop_state();
	if (sprite_exists(spr)) then sprite_set_offset(spr, offset_x, offset_y);
	return sprite_exists(spr) ? spr : -1;
}

function kawase_blur_shader_pass(sprite_id, subimg, dw, dh, iterations, offset_x, offset_y) {
	var surf_src = surface_create(dw, dh);
	var surf_dst = surface_create(dw, dh);
	if (!surface_exists(surf_src) || !surface_exists(surf_dst)) {
		kawase_blur_free_pair(surf_src, surf_dst);
		return -1;
	};
	gpu_push_state();
	gpu_set_texfilter(true);
	gpu_set_blendmode(bm_normal);
	surface_set_target(surf_src);
	draw_clear_alpha(c_black, 0);
	draw_sprite_stretched(sprite_id, subimg, 0, 0, dw, dh);
	surface_reset_target();
	var ok = false;
	try {
		shader_set(shd_kawase_blur);
		var u_offset = shader_get_uniform(shd_kawase_blur, "offset");
		var u_texsize = shader_get_uniform(shd_kawase_blur, "tex_size");
		shader_set_uniform_f(u_texsize, dw, dh);
		for (var i = 1; i <= iterations; i++) {
			surface_set_target(surf_dst);
			draw_clear_alpha(c_black, 0);
			shader_set_uniform_f(u_offset, i * 1.0);
			draw_surface(surf_src, 0, 0);
			surface_reset_target();
			var temp = surf_src;
			surf_src = surf_dst;
			surf_dst = temp;
		};
		shader_reset();
		ok = true;
	} catch (shader_error) {
		delete(shader_error);
		try { shader_reset(); } catch (reset_error) { delete(reset_error); };
		ok = false;
	};
	var spr = -1;
	if (ok) then spr = sprite_create_from_surface(surf_src, 0, 0, dw, dh, false, false, offset_x, offset_y);
	kawase_blur_free_pair(surf_src, surf_dst);
	gpu_pop_state();
	if (sprite_exists(spr)) then sprite_set_offset(spr, offset_x, offset_y);
	return sprite_exists(spr) ? spr : -1;
}

/// @function kawase_blur_sprite(image_uri , image_count , subing , iterations , offset_type , custom_offset , [save_path])
/// @param		{string} image_uri					- 图像地址 (假如这里填的不是地址 , 则这里会被认为ref sprite)
/// @param		{real} image_count					- 图像分割数量 (如果是ref sprite则没用)
/// @param		{real} subimg						- 子图索引（0开始）
/// @param		{real} iterations					- 迭代次数(越大越模糊，建议 3~8)
/// @param		{enum} offset_type					- 图像偏移枚举 (SPRITE_OFFSET)
/// @param		{array[int]} custom_offset			- 自定义图像偏移坐标 (仅有offset_type为SPRITE_OFFSET.CUSTOM才会生效)
/// @param		{string} [save_path]				- 可选，保存 PNG 的文件路径(如 "blur.png"), 如果不保存则保存sprite索引
/// @returns	{ref}								- 新的精灵索引 , 失败返回 -1
function kawase_blur_sprite(image_uri, image_count , subimg , iterations, offset_type = SPRITE_OFFSET.TOP_LEFT , custom_offset = [0 , 0]  , save_path = undefined) {
	var sprite_id = -1;
	var owns_source_sprite = false;

	// GM 2024+ sprite_add returns "ref sprite", not "ref". Treat any live
	// sprite handle as a source; only strings go through sprite_add.
	if (is_string(image_uri)) {
		if (!file_exists(image_uri) && !(pls_is_html5() && (string_pos("blob:", image_uri) == 1 || string_pos("data:", image_uri) == 1 || string_pos("http", image_uri) == 1))) then return(-1);
		sprite_id = sprite_add(image_uri, image_count, false, false, 0, 0);
		owns_source_sprite = true;
	} else if (asset_sprite_valid(image_uri)) {
		sprite_id = image_uri;
	};

	if (!sprite_exists(sprite_id)) then return(-1);
	
    var w = (sprite_get_width(sprite_id));
    var h = (sprite_get_height(sprite_id));
    if (w <= 0 || h <= 0) {
		if(owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
		return(-1);
	};

	var max_dim = pls_is_gxgames() ? 480 : 1920;
	var blur_w = w;
	var blur_h = h;
	if (max(w, h) > max_dim) {
		var sc = max_dim / max(w, h);
		blur_w = max(8, round(w * sc));
		blur_h = max(8, round(h * sc));
	};
	var iter = max(1, iterations);
	if (pls_is_gxgames()) then iter = min(iter, 4);

	var offset;
	if (offset_type == SPRITE_OFFSET.CUSTOM) then offset = custom_offset;
	else offset = sprite_get_offset_enum(blur_w, blur_h, offset_type);
	var ox = is_array(offset) ? offset[0] : blur_w * 0.5;
	var oy = is_array(offset) ? offset[1] : blur_h * 0.5;

	var use_shader = false;
	try {
		use_shader = shaders_are_supported() && shader_is_compiled(shd_kawase_blur);
	} catch (shader_check_error) {
		delete(shader_check_error);
		use_shader = false;
	};

	var new_sprite = -1;
	if (use_shader) then new_sprite = kawase_blur_shader_pass(sprite_id, subimg, blur_w, blur_h, iter, ox, oy);
	if (!sprite_exists(new_sprite)) then new_sprite = kawase_blur_downsample_fallback(sprite_id, subimg, blur_w, blur_h, ox, oy);

	if (save_path != undefined && sprite_exists(new_sprite)) {
		sprite_save(new_sprite, 0, save_path);
		sprite_delete(new_sprite);
		if (owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
		return true;
	};

	if (owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
	return sprite_exists(new_sprite) ? new_sprite : -1;
};
