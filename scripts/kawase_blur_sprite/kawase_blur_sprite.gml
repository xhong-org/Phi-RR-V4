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
	var sprite_id,
		owns_source_sprite = false;
	
	if(string(typeof(image_uri)) == "ref") then sprite_id = image_uri;
	elif(string(typeof(image_uri)) == "string"){
		if(!file_exists(image_uri)) then return(-1);
		sprite_id = (sprite_add(image_uri , image_count , false , false , 0 , 0));
		owns_source_sprite = true;
	};
	
	if(!sprite_exists(sprite_id)) then return(-1);
	
    var w = (sprite_get_width(sprite_id));
    var h = (sprite_get_height(sprite_id));
    if (w <= 0 || h <= 0) {
		if(owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
		return(-1);
	};
    
    // Two surface?
    var surf_src = (surface_create(w, h));
    var surf_dst = (surface_create(w, h));
    if (!surface_exists(surf_src) || !surface_exists(surf_dst)) {
        if (surface_exists(surf_src)) then surface_free(surf_src);
        if (surface_exists(surf_dst)) then surface_free(surf_dst);
		if(owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
        return(-1);
    }
    
    // 1. Sprite -> Surface !
    surface_set_target(surf_src);
    draw_clear_alpha(c_black, 0);
    draw_sprite(sprite_id, subimg, 0, 0);
    surface_reset_target();
    
    // 2. Kawase Blur Foreach
    shader_set(shd_kawase_blur);
    var u_offset = (shader_get_uniform(shd_kawase_blur, "offset"));
    var u_texsize = (shader_get_uniform(shd_kawase_blur, "tex_size"));
    shader_set_uniform_f(u_texsize, w, h);
    
    for (var i = 1 ; i <= iterations ; i ++) {
        surface_set_target(surf_dst);
        draw_clear_alpha(c_black, 0);
        shader_set_uniform_f(u_offset, i * 1.0);
        draw_surface(surf_src, 0, 0);
        surface_reset_target();
        
        // Surface1 <-> Surface2
        var temp = surf_src;
        surf_src = surf_dst;
        surf_dst = temp;
    };
    shader_reset();
    
    // result <- surf_src
    // 3. Save as
    if (save_path != undefined) {
        surface_save(surf_src, save_path);
		
		// Clean
		surface_free(surf_src);
		surface_free(surf_dst);
		if(owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
		return(true);
    };
    
    // 4. Surface -> Create Ref Sprite id
	var offset; 
	if(offset_type == SPRITE_OFFSET.CUSTOM) then offset = custom_offset;
	else offset = (sprite_get_offset_enum(w , h , offset_type));
	
    var new_sprite = (sprite_create_from_surface(surf_src, 0, 0, w, h, false, false, offset[0] , offset[1]));
    
	//sprite_set_offset(new_sprite , offset[0] , offset[1]);
	
    // 5. Final Clean
    surface_free(surf_src);
    surface_free(surf_dst);
	if(owns_source_sprite && sprite_exists(sprite_id)) then sprite_delete(sprite_id);
    
    return (new_sprite);
};
