// 生成于 2024-06-08 00:14:24（1028ms），面向 v2022+
/// @lint nullToAny true
// Feather disable all
#region metatype
globalvar gif_std_haxe_type_markerValue; gif_std_haxe_type_markerValue = [];
globalvar mt_gif_reader;
globalvar mt_gif_frame;
globalvar mt_gif_drawer;
globalvar mt_gif_raw_reader;
globalvar mt_format_gif_block;
globalvar mt_format_gif_extension;
globalvar mt_format_gif_application_extension;
globalvar mt_format_gif_version;
globalvar mt_format_gif_disposal_method;
globalvar mt_gif_std_haxe_class;
globalvar mt_gif_std_haxe_enum;
globalvar mt_gif_std_haxe_io_Bytes;
globalvar mt_gif_std_haxe_io_Output;
globalvar mt_gif_std_haxe_io_BytesOutput;
// 登记 Haxe 转写后的类型元数据。
///@desc 初始化 GIF 相关类型标记
///@returns {Undefined} 无
(function() {
mt_gif_reader = new gif_std_haxe_class(-1, "gif_reader");
mt_gif_frame = new gif_std_haxe_class(-1, "gif_frame");
mt_gif_drawer = new gif_std_haxe_class(-1, "gif_drawer");
mt_gif_raw_reader = new gif_std_haxe_class(-1, "gif_raw_reader");
mt_format_gif_block = new gif_std_haxe_enum(-1, "format_gif_block");
mt_format_gif_extension = new gif_std_haxe_enum(-1, "format_gif_extension");
mt_format_gif_application_extension = new gif_std_haxe_enum(-1, "format_gif_application_extension");
mt_format_gif_version = new gif_std_haxe_enum(-1, "format_gif_version");
mt_format_gif_disposal_method = new gif_std_haxe_enum(-1, "format_gif_disposal_method");
mt_gif_std_haxe_class = new gif_std_haxe_class(-1, "gif_std_haxe_class");
mt_gif_std_haxe_enum = new gif_std_haxe_class(-1, "gif_std_haxe_enum");
mt_gif_std_haxe_io_Bytes = new gif_std_haxe_class(-1, "gif_std_haxe_io_Bytes");
mt_gif_std_haxe_io_Output = new gif_std_haxe_class(-1, "gif_std_haxe_io_Output");
mt_gif_std_haxe_io_BytesOutput = new gif_std_haxe_class(-1, "gif_std_haxe_io_BytesOutput");
mt_gif_std_haxe_io_BytesOutput.superClass = mt_gif_std_haxe_io_Output;
})();
#endregion
enum gif_reader_action { none, meta, frame, gce, render, eof }
///@desc 把当前枚举值转成字符串
///@returns {String} 枚举文本
function gif_std_enum_toString() {
	return gif_std_Std_stringify(self);
}
///@desc 返回当前枚举值的序号
///@returns {Real} __enumIndex__
function gif_std_enum_getIndex() {
	return __enumIndex__;
}

#region gif_reader

///@desc 从缓冲增量读取 GIF 并合成精灵
///@param {Real} _buf 文件缓冲
///@param {Real} _xorig 原点 x
///@param {Real} _yorig 原点 y
///@param {Array} _frameDelays 帧延迟输出，可为 undefined
///@param {Array} _frameSprites 逐帧精灵输出，可为 undefined
///@returns {Struct} 读取器
function gif_reader(_buf, _xorig, _yorig, _frameDelays, _frameSprites) constructor {
	static frames = undefined; /// @is {array<gif_frame>}
	static fin_frame_count = undefined; /// @is {int}
	static width = undefined; /// @is {int}
	static height = undefined; /// @is {int}
	static loops = undefined; /// @is {int}
	static xorig = undefined; /// @is {int}
	static yorig = undefined; /// @is {int}
	static buffer = undefined; /// @is {buffer}
	static owns_buffer = undefined; /// @is {bool}
	static sprite = undefined; /// @is {sprite}
	static frame_delays = undefined; /// @is {array<int>}
	static frame_sprites = undefined; /// @is {array<sprite>}
	///@desc 释放各帧、自有缓冲和绘制器
	///@returns {Undefined} 无
	static destroy = function() {
		var __g = 0;
		var __g1 = self.frames;
		while (__g < array_length(__g1)) {
			var _frame = __g1[__g];
			__g++;
			_frame.destroy();
		}
		// 只有自己加载的缓冲才删除
		if (self.owns_buffer && self.buffer != -1) {
			buffer_delete(self.buffer);
			self.buffer = -1;
		}
		if (self.drawer != undefined) self.drawer.destroy();
	}
	static reader = undefined; /// @is {gif_raw_reader}
	static info = undefined; /// @is {GifData?}
	static gce = undefined; /// @is {format_gif_GraphicControlExtension}
	static global_color_table = undefined; /// @is {array<int>}
	static current_frame = undefined; /// @is {int}
	static set_delay = undefined; /// @is {bool}
	static drawer = undefined; /// @is {gif_drawer}
	///@desc 读取文件头并记下逻辑画面大小
	///@returns {Undefined} 无
	static start = function() {
		self.reader = new gif_raw_reader(self.buffer);
		self.info = self.reader.read(false);
		self.width = self.info.logicalScreenDescriptor.width;
		self.height = self.info.logicalScreenDescriptor.height;
		// 有全局调色板时先转成绘制用的整数颜色
		if (self.info.globalColorTable != undefined) self.global_color_table = gif_loader_tools_color_table_to_vector(self.info.globalColorTable, self.info.logicalScreenDescriptor.globalColorTableSize);
	}
	///@desc 把一帧像素写成表面缓冲并加入帧列表
	///@param {Struct} _f 原始帧
	///@returns {Undefined} 无
	static read_frame = function(_f) {
		var _gf = new gif_frame();
		var _transparentIndex = -1;
		if (self.gce != undefined) {
			_gf.delay = self.gce.delay;
			if (self.gce.hasTransparentColor) _transparentIndex = self.gce.transparentIndex;
			// 图形控制里的处置方式换成绘制器用的编号
			switch (self.gce.disposalMethod.__enumIndex__/* format_gif_disposal_method */) {
				case 2/* fill_background */: _gf.disposal_method = 1; break;
				case 3/* render_previous */: _gf.disposal_method = 2; break;
			}
		}
		_gf.x = _f.x;
		_gf.y = _f.y;
		_gf.width = _f.width;
		_gf.height = _f.height;
		var _colorTable = self.global_color_table;
		if (_f.colorTable != undefined) _colorTable = gif_loader_tools_color_table_to_vector(_f.colorTable, _f.localColorTableSize);
		var _fWidth = _f.width;
		var _fHeight = _f.height;
		var _sf = surface_create(_fWidth, _fHeight);
		var _pxData = _f.pixels.b;
		var _buf = buffer_create(_f.width * _f.height * 4, buffer_fixed, 1);
		for (var _i = 0, __g1 = array_length(_f.pixels.b); _i < __g1; _i++) {
			var _col = _pxData[_i];
			// 透明索引写成全 0，其余写成调色板颜色
			if (_col == _transparentIndex) buffer_write(_buf, buffer_s32, 0); else buffer_write(_buf, buffer_s32, _colorTable[_col]);
		}
		_gf.buffer = _buf;
		buffer_set_surface(_buf, _sf, 0);
		self.gce = undefined;
		array_add(self.frames, _gf);
		self.next_frame = _gf;
	}
	static last_action = undefined; /// @is {gif_reader_action}
	///@desc 返回最近一次推进的动作
	///@returns {Real} gif_reader_action
	static get_last_action = function() {
		return self.last_action;
	}
	///@desc 返回最近一次动作的名字
	///@returns {String} 动作名
	static get_last_action_name = function() {
		return gif_reader_get_action_name(self.last_action);
	}
	///@desc 返回已经绘制完成的帧数
	///@returns {Real} 帧数
	static get_frame_count = function() {
		return self.fin_frame_count;
	}
	///@desc 返回正在合成的精灵
	///@returns {Real} 精灵，尚未创建时为 -1
	static get_sprite = function() {
		return self.sprite;
	}
	static found_eof = undefined; /// @is {bool}
	static next_frame = undefined; /// @is {gif_frame}
	///@desc 推进一块或绘制一帧
	///@returns {Bool} 还能继续时为真
	static next = function() {
		// 已经读到文件尾
		if (self.found_eof) return false;
		var _frame = self.next_frame;
		if (_frame != undefined) {
			self.next_frame = undefined;
			if (self.drawer == undefined) self.drawer = new gif_drawer(self);
			self.drawer.draw(_frame);
			var _fdelay = _frame.delay;
			var _tmp = self.frame_delays;
			if (_tmp != undefined) array_add(_tmp, _fdelay);
			// 只在合成单精灵时，用第一段正延迟设置播放速度
			if (!self.set_delay && _fdelay > 0 && self.frame_sprites == undefined) {
				self.set_delay = true;
				sprite_set_speed(self.sprite, 100 / _fdelay, spritespeed_framespersecond);
			}
			self.last_action = gif_reader_action.render;
			self.fin_frame_count += 1;
			return true;
		}
		var _block = self.reader.read_next(self.info.blocks);
		switch (_block.__enumIndex__/* format_gif_block */) {
			case 0/* bframe */:
				self.read_frame(_block.frame);
				self.last_action = gif_reader_action.frame;
				break;
			case 1/* bextension */:
				var __g = _block.extension;
				switch (__g.__enumIndex__/* format_gif_extension */) {
					case 3/* eapplication_extension */:
						var __g1 = __g.ext;
						if (__g1.__enumIndex__/* format_gif_application_extension */ == 0/* aenetscape_looping */) {
							var _n = __g1.loops;
							self.loops = _n;
							self.last_action = gif_reader_action.meta;
						} else self.last_action = gif_reader_action.meta;
						break;
					case 0/* egraphic_control */:
						self.gce = __g.gce;
						self.last_action = gif_reader_action.gce;
						break;
					default: self.last_action = gif_reader_action.meta;
				}
				break;
			case 2/* beof */:
				self.last_action = gif_reader_action.eof;
				// 结束块之后不再推进
				self.found_eof = true;
				return false;
		}
		return true;
	}
	///@desc 在时限内连续推进
	///@param {Real} _timeoutMs 时限，毫秒
	///@returns {Bool} 时限到时是否还能继续
	static next_few = function(_timeoutMs) {
		var _till = current_time + _timeoutMs;
		var _cont;
		do {
			_cont = self.next();
		// 读完或超时就停
		} until (!(_cont && current_time < _till));
		return _cont;
	}
	///@desc 标记结束并释放读取器，留下精灵
	///@returns {Real} 合成出的精灵
	static finish = function() {
		self.found_eof = true;
		self.destroy();
		return self.sprite;
	}
	self.next_frame = undefined;
	self.found_eof = false;
	self.last_action = gif_reader_action.none;
	self.drawer = undefined;
	self.set_delay = false;
	self.current_frame = -1;
	self.global_color_table = undefined;
	self.gce = undefined;
	self.info = undefined;
	self.sprite = -1;
	self.owns_buffer = false;
	self.loops = -1;
	self.height = 0;
	self.width = 0;
	self.fin_frame_count = 0;
	self.frames = [];
	self.buffer = _buf;
	self.xorig = _xorig;
	self.yorig = _yorig;
	self.frame_delays = _frameDelays;
	self.frame_sprites = _frameSprites;
	static __class__ = mt_gif_reader;
}

///@desc 把读取动作枚举换成名字
///@param {Real} _action gif_reader_action
///@returns {String} 动作名，未知时没有返回值
function gif_reader_get_action_name(_action) {
	// 没有匹配的动作时函数不返回值
	switch (_action) {
		case gif_reader_action.none: return "None";
		case gif_reader_action.meta: return "Meta";
		case gif_reader_action.frame: return "Frame";
		case gif_reader_action.gce: return "GCE";
		case gif_reader_action.render: return "Render";
		case gif_reader_action.eof: return "EOF";
	}
}

///@desc 同步把 GIF 缓冲合成一个精灵
///@param {Real} _buf 文件缓冲
///@param {Real} _xorig 原点 x
///@param {Real} _yorig 原点 y
///@param {Array} _frameDelays 帧延迟输出
///@param {Array} _frameSprites 逐帧精灵输出
///@returns {Real} 精灵
function sprite_add_gif_buffer(_buf, _xorig, _yorig, _frameDelays, _frameSprites) {
	if (false) show_debug_message(argument[4]);
	var _gif = new gif_reader(_buf, _xorig, _yorig, _frameDelays, _frameSprites);
	_gif.start();
	// 一次读完所有块
	while (_gif.next()) { }
	return _gif.finish();
}

///@desc 开始分步读取 GIF 缓冲
///@param {Real} _buf 文件缓冲
///@param {Real} _xorig 原点 x
///@param {Real} _yorig 原点 y
///@param {Array} _frameDelays 帧延迟输出
///@param {Array} _frameSprites 逐帧精灵输出
///@returns {Struct} 已启动的读取器
function sprite_add_gif_buffer_start(_buf, _xorig, _yorig, _frameDelays, _frameSprites) {
	if (false) show_debug_message(argument[4]);
	var _gif = new gif_reader(_buf, _xorig, _yorig, _frameDelays, _frameSprites);
	_gif.start();
	return _gif;
}

///@desc 从路径同步加载 GIF 精灵并释放文件缓冲
///@param {String} _path1 文件路径
///@param {Real} _xorig 原点 x
///@param {Real} _yorig 原点 y
///@param {Array} _frameDelays 帧延迟输出
///@param {Array} _frameSprites 逐帧精灵输出
///@returns {Real} 精灵
function sprite_add_gif(_path1, _xorig, _yorig, _frameDelays, _frameSprites) {
	if (false) show_debug_message(argument[4]);
	var _buf = buffer_load(chart_file_readable_path(_path1));
	var _spr = sprite_add_gif_buffer(_buf, _xorig, _yorig, _frameDelays, _frameSprites);
	buffer_delete(_buf);
	return _spr;
}

///@desc 从路径开始分步读取，读取器负责释放缓冲
///@param {String} _path1 文件路径
///@param {Real} _xorig 原点 x
///@param {Real} _yorig 原点 y
///@param {Array} _frameDelays 帧延迟输出
///@param {Array} _frameSprites 逐帧精灵输出
///@returns {Struct} 读取器
function sprite_add_gif_start(_path1, _xorig, _yorig, _frameDelays, _frameSprites) {
	if (false) show_debug_message(argument[4]);
	var _buf = buffer_load(chart_file_readable_path(_path1));
	var _gif = sprite_add_gif_buffer_start(_buf, _xorig, _yorig, _frameDelays, _frameSprites);
	// 缓冲由读取器在 destroy 时删除
	_gif.owns_buffer = true;
	return _gif;
}

#endregion

#region gif_frame

///@desc 保存一帧的延迟、像素缓冲和处置方式
///@returns {Struct} 帧
function gif_frame() constructor {
	static delay = undefined; /// @is {int}
	static buffer = undefined; /// @is {buffer}
	/* static */x = undefined; /// @is {int}
	/* static */y = undefined; /// @is {int}
	static width = undefined; /// @is {int}
	static height = undefined; /// @is {int}
	static disposal_method = undefined; /// @is {int}
	///@desc 释放这一帧的像素缓冲
	///@returns {Undefined} 无
	static destroy = function() {
		if (self.buffer != -1) {
			buffer_delete(self.buffer);
			self.buffer = -1;
		}
	}
	self.disposal_method = 0;
	self.buffer = -1;
	self.delay = 0;
	static __class__ = mt_gif_frame;
}

#endregion

#region gif_loader_tools

///@desc 把 RGB 调色板收成绘制用的整数颜色
///@param {Struct} _pal 含字节数组 b 的调色板
///@param {Real} _num 颜色数量
///@returns {Array} 每项为 AABBGGRR
function gif_loader_tools_color_table_to_vector(_pal, _num) {
	var _r, _g, _b;
	var _p = 0;
	var _a = 255;
	var _vec = array_create(_num, undefined);
	for (var _i = 0; _i < _num; _i++) {
		_r = _pal.b[_p];
		_g = _pal.b[_p + 1];
		_b = _pal.b[_p + 2];
		var _val = ((((_a << 24) | (_b << 16)) | (_g << 8)) | _r);
		_vec[@_i] = _val;
		// 调色板按红、绿、蓝三字节排列
		_p += 3;
	}
	return _vec;
}

#endregion

#region gif_drawer

///@desc 按处置方式把各帧叠到一张画面上
///@param {Struct} _gif 读取器
///@returns {Struct} 绘制器
function gif_drawer(_gif) constructor {
	static restore_buf = undefined; /// @is {buffer}
	static surface = undefined; /// @is {surface}
	static gif = undefined; /// @is {gif_reader}
	///@desc 释放还原缓冲和合成表面
	///@returns {Undefined} 无
	static destroy = function() {
		if (self.restore_buf != -1) {
			buffer_delete(self.restore_buf);
			self.restore_buf = -1;
		}
		if (surface_exists(self.surface)) {
			surface_free(self.surface);
			self.surface = -1;
		}
	}
	///@desc 把一帧叠进画面并写回精灵
	///@param {Struct} _frame 帧
	///@returns {Undefined} 无
	static draw = function(_frame) {
		var _sprite1 = self.gif.sprite;
		if (!surface_exists(self.surface)) {
			var _sf = surface_create(self.gif.width, self.gif.height);
			surface_set_target(_sf);
			draw_clear_alpha(16777215, 0);
			if (_sprite1 != -1) draw_sprite(_sprite1, sprite_get_number(_sprite1) - 1, self.gif.xorig, self.gif.yorig);
			surface_reset_target();
			self.surface = _sf;
		}
		// 处置 2 要在覆盖前留下当前画面
		if (_frame.disposal_method == 2) {
			if (self.restore_buf == -1) self.restore_buf = buffer_create(self.gif.width * self.gif.height * 4, buffer_fixed, 1);
			buffer_get_surface(self.restore_buf, self.surface, 0);
		}
		var _frameSurf = surface_create(_frame.width, _frame.height);
		buffer_set_surface(_frame.buffer, _frameSurf, 0);
		surface_set_target(self.surface);
		draw_surface(_frameSurf, _frame.x, _frame.y);
		var __this = self.surface;
		surface_reset_target();
		surface_free(_frameSurf);
		// 需要逐帧精灵时每帧新建，否则往同一精灵追加子图
		if (self.gif.frame_sprites != undefined) {
			var _sf = self.surface;
			var _ox = self.gif.xorig;
			var _oy = self.gif.yorig;
			_sprite1 = sprite_create_from_surface(_sf, 0, 0, surface_get_width(_sf), surface_get_height(_sf), false, false, _ox, _oy);
			array_add(self.gif.frame_sprites, _sprite1);
			self.gif.sprite = _sprite1;
		} else if (_sprite1 == -1) {
			var _sf = self.surface;
			var _ox = self.gif.xorig;
			var _oy = self.gif.yorig;
			_sprite1 = sprite_create_from_surface(_sf, 0, 0, surface_get_width(_sf), surface_get_height(_sf), false, false, _ox, _oy);
			self.gif.sprite = _sprite1;
		} else {
			var _sf = self.surface;
			sprite_add_from_surface(_sprite1, _sf, 0, 0, surface_get_width(_sf), surface_get_height(_sf), false, false);
		}
		switch (_frame.disposal_method) {
			// 2 恢复覆盖前的画面，1 用白色减掉本帧矩形
			case 2: buffer_set_surface(self.restore_buf, self.surface, 0); break;
			case 1:
				surface_set_target(self.surface);
				var _mode = bm_subtract;
				gpu_set_blendmode(_mode);
				draw_sprite_stretched(gif_drawer_white32, 0, _frame.x, _frame.y, _frame.width, _frame.height);
				var _mode = bm_normal;
				gpu_set_blendmode(_mode);
				var __this = self.surface;
				surface_reset_target();
				break;
		}
	}
	self.surface = -1;
	self.restore_buf = -1;
	if (gif_drawer_white32 == -1) gif_drawer_init_white32();
	self.gif = _gif;
	static __class__ = mt_gif_drawer;
}

///@desc 创建处置背景时使用的 32 像素白块
///@returns {Undefined} 无
function gif_drawer_init_white32() {
	var _ws = surface_create(32, 32);
	surface_set_target(_ws);
	draw_clear(16777215);
	surface_reset_target();
	gif_drawer_white32 = sprite_create_from_surface(_ws, 0, 0, surface_get_width(_ws), surface_get_height(_ws), false, false, 0, 0);
	surface_free(_ws);
}

#endregion

#region gif_raw_reader

///@desc 从缓冲解析 GIF 块
///@param {Real} _i 文件缓冲
///@returns {Struct} 原始读取器
function gif_raw_reader(_i) constructor {
	static i = undefined; /// @is {buffer}
	///@desc 从当前位置读出定长字符串
	///@param {Real} _len 字节数
	///@returns {String} 文本
	static read_string = function(_len) {
		var _buf = gif_raw_reader_read_string_tmp_buf;
		if (_buf == -1) {
			_buf = buffer_create(_len + 1, buffer_fixed, 1);
			gif_raw_reader_read_string_tmp_buf = _buf;
		// 临时缓冲不够时才扩大
		} else if (buffer_get_size(_buf) <= _len) {
			buffer_resize(_buf, _len + 1);
		}
		buffer_poke(_buf, gif_std_gml_io__Buffer_BufferImpl_readBuffer(self.i, _buf, 0, _len), buffer_u8, 0);
		buffer_seek(_buf, buffer_seek_start, 0);
		return buffer_read(_buf, buffer_string);
	}
	///@desc 读取文件头，可选一次读完所有块
	///@param {Bool} _instant 是否立刻读完
	///@returns {Struct} 版本、逻辑屏和块列表
	static read = function(_instant) {
		var _b = 71;
		// 头三个字节必须是 GIF
		if (buffer_read(self.i, buffer_u8) != _b) show_error("Invalid header", true);
		var _b = 73;
		if (buffer_read(self.i, buffer_u8) != _b) show_error("Invalid header", true);
		var _b = 70;
		if (buffer_read(self.i, buffer_u8) != _b) show_error("Invalid header", true);
		var _gifVer = self.read_string(3);
		var _version = format_gif_version_gif89a;
		switch (_gifVer) {
			case "87a": _version = format_gif_version_gif87a; break;
			case "89a": _version = format_gif_version_gif89a; break;
			// 既不是 87a 也不是 89a 时保留原版本串
			default: _version = format_gif_version_unknown(_gifVer);
		}
		var _width = buffer_read(self.i, buffer_u16);
		var _height = buffer_read(self.i, buffer_u16);
		var _packedField = buffer_read(self.i, buffer_u8);
		var _bgIndex = buffer_read(self.i, buffer_u8);
		var _pixelAspectRatio = buffer_read(self.i, buffer_u8);
		// 规范里 0 表示 1:1，其余按 (n+15)/64
		if (_pixelAspectRatio != 0) _pixelAspectRatio = (_pixelAspectRatio + 15) / 64; else _pixelAspectRatio = 1;
		var _lsd = {
			width: _width,
			height: _height,
			hasGlobalColorTable: (_packedField & 128) == 128,
			colorResolution: ((((_packedField & 112) & $FFFFFFFF) >> 4)),
			sorted: (_packedField & 8) == 8,
			globalColorTableSize: (2 << (_packedField & 7)),
			backgroundColorIndex: _bgIndex,
			pixelAspectRatio: _pixelAspectRatio
		}
		var _gct = undefined;
		if (_lsd.hasGlobalColorTable) _gct = self.read_color_table(_lsd.globalColorTableSize);
		var _blocks = [];
		// 立即模式一直读到结束块
		if (_instant) while (true) {
			var _b = self.read_block();
			array_add(_blocks, _b);
			if (_b == format_gif_block_beof) break;
		}
		return {
			version: _version,
			logicalScreenDescriptor: _lsd,
			globalColorTable: _gct,
			blocks: _blocks
		}
	}
	///@desc 再读一块并追加到块列表
	///@param {Array} _blocks 已有块
	///@returns {Struct} 新块
	static read_next = function(_blocks) {
		var _b = self.read_block();
		array_add(_blocks, _b);
		return _b;
	}
	///@desc 按块标识读取图像、扩展或结束块
	///@returns {Struct} GIF 块
	static read_block = function() {
		var _blockID = buffer_read(self.i, buffer_u8);
		switch (_blockID) {
			// 0x2C 图像，0x21 扩展，0x3B 结束
			case 44: return self.read_image();
			case 33: return self.read_extension();
			case 59: return format_gif_block_beof;
		}
		// 不认识的标识按结束处理
		return format_gif_block_beof;
	}
	///@desc 读取一帧图像描述和像素
	///@returns {Struct} 图像块
	static read_image = function() {
		var _x = buffer_read(self.i, buffer_u16);
		var _y = buffer_read(self.i, buffer_u16);
		var _width = buffer_read(self.i, buffer_u16);
		var _height = buffer_read(self.i, buffer_u16);
		var _packed = buffer_read(self.i, buffer_u8);
		var _localColorTable = (_packed & 128) == 128;
		var _interlaced = (_packed & 64) == 64;
		var _sorted = (_packed & 32) == 32;
		var _localColorTableSize = (2 << (_packed & 7));
		var _lct = undefined;
		// 局部调色板紧跟在图像描述后面
		if (_localColorTable) _lct = self.read_color_table(_localColorTableSize);
		var _frame = {
			x: _x,
			y: _y,
			width: _width,
			height: _height,
			localColorTable: _localColorTable,
			interlaced: _interlaced,
			sorted: _sorted,
			localColorTableSize: _localColorTableSize,
			pixels: self.read_pixels(_width, _height, _interlaced),
			colorTable: _lct
		}
		return format_gif_block_bframe(_frame);
	}
	///@desc 用 LZW 解出像素，交错帧再还原行序
	///@param {Real} _width 宽
	///@param {Real} _height 高
	///@param {Bool} _interlaced 是否交错
	///@returns {Struct} 像素字节
	static read_pixels = function(_width, _height, _interlaced) {
		var _input = self.i;
		var _pixelsCount = _width * _height;
		var _pixels = new gif_std_haxe_io_Bytes(array_create(_pixelsCount, 0));
		var _minCodeSize = buffer_read(_input, buffer_u8);
		var _blockSize = buffer_read(_input, buffer_u8) - 1;
		var _bits = buffer_read(_input, buffer_u8);
		var _bitsCount = 8;
		var _clearCode = (1 << _minCodeSize);
		var _eoiCode = _clearCode + 1;
		var _codeSize = _minCodeSize + 1;
		var _codeSizeLimit = (1 << _codeSize);
		var _codeMask = _codeSizeLimit - 1;
		var _baseDict = [];
		for (var _i = 0; _i < _clearCode; _i++) {
			_baseDict[@_i] = [_i];
		}
		var _dict = [];
		var _dictLen = _clearCode + 2;
		var _newRecord;
		var _i = 0;
		var _code = 0;
		var _last;
		while (_i < _pixelsCount) {
			_last = _code;
			while (_bitsCount < _codeSize) {
				if (_blockSize == 0) break;
				_bits |= (buffer_read(_input, buffer_u8) << _bitsCount);
				_bitsCount += 8;
				_blockSize--;
				if (_blockSize == 0) _blockSize = buffer_read(_input, buffer_u8);
			}
			_code = (_bits & _codeMask);
			_bits = _bits >> _codeSize;
			_bitsCount -= _codeSize;
			// 清除码重置字典和码长
			if (_code == _clearCode) {
				_dict = gif_std_gml_internal_ArrayImpl_copy(_baseDict);
				_dictLen = _clearCode + 2;
				_codeSize = _minCodeSize + 1;
				_codeSizeLimit = (1 << _codeSize);
				_codeMask = _codeSizeLimit - 1;
				continue;
			}
			// 结束码后还要跳过本子块剩余字节
			if (_code == _eoiCode) break;
			if (_code < _dictLen) {
				if (_last != _clearCode) {
					_newRecord = gif_std_gml_internal_ArrayImpl_copy(_dict[_last]);
					array_add(_newRecord, _dict[_code][0]);
					_dict[@_dictLen++] = _newRecord;
				}
			} else {
				if (_code != _dictLen) show_error("Invalid LZW code. Excepted: " + string(_dictLen) + ", got: " + string(_code), true);
				_newRecord = gif_std_gml_internal_ArrayImpl_copy(_dict[_last]);
				array_add(_newRecord, _newRecord[0]);
				_dict[@_dictLen++] = _newRecord;
			}
			_newRecord = _dict[_code];
			var __g = 0;
			while (__g < array_length(_newRecord)) {
				var _item = _newRecord[__g];
				__g++;
				_pixels.b[@_i++] = (_item & 255);
			}
			// 字典满当前码长且未到 12 位时加长
			if (_dictLen == _codeSizeLimit && _codeSize < 12) {
				_codeSize++;
				_codeSizeLimit = (1 << _codeSize);
				_codeMask = _codeSizeLimit - 1;
			}
		}
		while (_blockSize > 0) {
			buffer_read(_input, buffer_u8);
			_blockSize--;
			if (_blockSize == 0) _blockSize = buffer_read(_input, buffer_u8);
		}
		while (_i < _pixelsCount) {
			_pixels.b[@_i++] = 0;
		}
		// 交错存放按四趟行距写回正常行序
		if (_interlaced) {
			var _buffer1 = new gif_std_haxe_io_Bytes(array_create(_pixelsCount, 0));
			var _offset = self.deinterlace(_pixels, _buffer1, 8, 0, 0, _width, _height);
			_offset = self.deinterlace(_pixels, _buffer1, 8, 4, _offset, _width, _height);
			_offset = self.deinterlace(_pixels, _buffer1, 4, 2, _offset, _width, _height);
			_offset = self.deinterlace(_pixels, _buffer1, 2, 1, _offset, _width, _height);
			_pixels = _buffer1;
		}
		return _pixels;
	}
	///@desc 把交错像素的一趟拷到正常行
	///@param {Struct} _input 交错像素
	///@param {Struct} _output 正常像素
	///@param {Real} _step 行距
	///@param {Real} _y 起始行
	///@param {Real} _offset 源偏移
	///@param {Real} _width 宽
	///@param {Real} _height 高
	///@returns {Real} 下一趟的源偏移
	static deinterlace = function(_input, _output, _step, _y, _offset, _width, _height) {
		while (_y < _height) {
			array_copy(_output.b, _y * _width, _input.b, _offset, _width);
			_offset += _width;
			_y += _step;
		}
		return _offset;
	}
	///@desc 按扩展子类型读取图形控制、文本、注释或应用扩展
	///@returns {Struct} 扩展块
	static read_extension = function() {
		var _subId = buffer_read(self.i, buffer_u8);
		switch (_subId) {
			// 0xF9 图形控制，0x01 纯文本，0xFE 注释，0xFF 应用扩展
			case 249:
				if (buffer_read(self.i, buffer_u8) != 4) show_error("Incorrect Graphic Control Extension block size!", true);
				var _packed = buffer_read(self.i, buffer_u8);
				var _disposalMethod;
				switch ((_packed & 28) >> 2) {
					case 2: _disposalMethod = format_gif_disposal_method_fill_background; break;
					case 3: _disposalMethod = format_gif_disposal_method_render_previous; break;
					case 1: _disposalMethod = format_gif_disposal_method_no_action; break;
					case 0: _disposalMethod = format_gif_disposal_method_unspecified; break;
					default: _disposalMethod = format_gif_disposal_method_undefined_hx(((_packed & 28) >> 2));
				}
				var _delay = buffer_read(self.i, buffer_u16);
				var _gcx = {
					disposalMethod: _disposalMethod,
					userInput: (_packed & 2) == 2,
					hasTransparentColor: (_packed & 1) == 1,
					delay: _delay,
					transparentIndex: buffer_read(self.i, buffer_u8)
				}
				var _b = format_gif_block_bextension(format_gif_extension_egraphic_control(_gcx));
				buffer_read(self.i, buffer_u8);
				return _b;
			case 1:
				if (buffer_read(self.i, buffer_u8) != 12) show_error("Incorrect size of Plain Text Extension introducer block.", true);
				var _textGridX = buffer_read(self.i, buffer_u16);
				var _textGridY = buffer_read(self.i, buffer_u16);
				var _textGridWidth = buffer_read(self.i, buffer_u16);
				var _textGridHeight = buffer_read(self.i, buffer_u16);
				var _charCellWidth = buffer_read(self.i, buffer_u8);
				var _charCellHeight = buffer_read(self.i, buffer_u8);
				var _textForegroundColorIndex = buffer_read(self.i, buffer_u8);
				var _textBackgroundColorIndex = buffer_read(self.i, buffer_u8);
				var _buffer1 = new gif_std_haxe_io_BytesOutput();
				var _bytes = new gif_std_haxe_io_Bytes(array_create(255, 0));
				for (var _bdata = _bytes.b, _len = buffer_read(self.i, buffer_u8); _len != 0; _len = buffer_read(self.i, buffer_u8)) {
					for (var _k = 0; _k < _len; _k++) {
						_bdata[@_k] = buffer_read(self.i, buffer_u8);
					}
					_buffer1.writeBytes(_bytes, 0, _len);
				}
				_buffer1.flush();
				_bytes = new gif_std_haxe_io_Bytes(_buffer1.data);
				_buffer1.close();
				var __this = _bytes;
				var _ptx = {
					textGridX: _textGridX,
					textGridY: _textGridY,
					textGridWidth: _textGridWidth,
					textGridHeight: _textGridHeight,
					charCellWidth: _charCellWidth,
					charCellHeight: _charCellHeight,
					textForegroundColorIndex: _textForegroundColorIndex,
					textBackgroundColorIndex: _textBackgroundColorIndex,
					text: haxe_io__bytes_bytes_impl_get_string(__this.b, 0, array_length(__this.b))
				}
				return format_gif_block_bextension(format_gif_extension_etext(_ptx));
			case 254:
				var _buffer1 = new gif_std_haxe_io_BytesOutput();
				var _bytes = new gif_std_haxe_io_Bytes(array_create(255, 0));
				for (var _bdata = _bytes.b, _len = buffer_read(self.i, buffer_u8); _len != 0; _len = buffer_read(self.i, buffer_u8)) {
					for (var _k = 0; _k < _len; _k++) {
						_bdata[@_k] = buffer_read(self.i, buffer_u8);
					}
					_buffer1.writeBytes(_bytes, 0, _len);
				}
				_buffer1.flush();
				_bytes = new gif_std_haxe_io_Bytes(_buffer1.data);
				_buffer1.close();
				var __this = _bytes;
				return format_gif_block_bextension(format_gif_extension_ecomment(haxe_io__bytes_bytes_impl_get_string(__this.b, 0, array_length(__this.b))));
			case 255: return self.read_application_extension();
			default:
				var _buffer1 = new gif_std_haxe_io_BytesOutput();
				var _bytes = new gif_std_haxe_io_Bytes(array_create(255, 0));
				for (var _bdata = _bytes.b, _len = buffer_read(self.i, buffer_u8); _len != 0; _len = buffer_read(self.i, buffer_u8)) {
					for (var _k = 0; _k < _len; _k++) {
						_bdata[@_k] = buffer_read(self.i, buffer_u8);
					}
					_buffer1.writeBytes(_bytes, 0, _len);
				}
				_buffer1.flush();
				_bytes = new gif_std_haxe_io_Bytes(_buffer1.data);
				_buffer1.close();
				return format_gif_block_bextension(format_gif_extension_eunknown(_subId, _bytes));
		}
	}
	///@desc 读取应用扩展，识别 NETSCAPE 循环次数
	///@returns {Struct} 应用扩展块
	static read_application_extension = function() {
		if (buffer_read(self.i, buffer_u8) != 11) show_error("Incorrect size of Application Extension introducer block.", true);
		var _name = self.read_string(8);
		var _version = self.read_string(3);
		var _buffer1 = new gif_std_haxe_io_BytesOutput();
		var _bytes = new gif_std_haxe_io_Bytes(array_create(255, 0));
		for (var _bdata = _bytes.b, _len = buffer_read(self.i, buffer_u8); _len != 0; _len = buffer_read(self.i, buffer_u8)) {
			for (var _k = 0; _k < _len; _k++) {
				_bdata[@_k] = buffer_read(self.i, buffer_u8);
			}
			_buffer1.writeBytes(_bytes, 0, _len);
		}
		_buffer1.flush();
		_bytes = new gif_std_haxe_io_Bytes(_buffer1.data);
		_buffer1.close();
		var _data = _bytes;
		// NETSCAPE2.0 的子块 1 用小端保存循环次数
		if (_name == "NETSCAPE" && _version == "2.0" && _data.b[0] == 1) return format_gif_block_bextension(format_gif_extension_eapplication_extension(format_gif_application_extension_aenetscape_looping((_data.b[1] | (_data.b[2] << 8)))));
		return format_gif_block_bextension(format_gif_extension_eapplication_extension(format_gif_application_extension_aeunknown(_name, _version, _data)));
	}
	///@desc 读取 RGB 调色板字节
	///@param {Real} _size 颜色数量
	///@returns {Struct} 三倍长度的字节
	static read_color_table = function(_size) {
		_size *= 3;
		var _output = new gif_std_haxe_io_Bytes(array_create(_size, 0));
		for (var _c = 0; _c < _size; _c += 3) {
			var _v = buffer_read(self.i, buffer_u8);
			_output.b[@_c] = (_v & 255);
			var _v1 = buffer_read(self.i, buffer_u8);
			_output.b[@_c + 1] = (_v1 & 255);
			var _v2 = buffer_read(self.i, buffer_u8);
			_output.b[@_c + 2] = (_v2 & 255);
		}
		return _output;
	}
	self.i = _i;
	static __class__ = mt_gif_raw_reader;
}

#endregion

#region gif_std.Std

///@desc 把值收成调试用字符串，数字去掉多余小数零
///@param {Any} _value 任意值
///@returns {String} 文本
function gif_std_Std_stringify(_value) {
	if (_value == undefined) return "null";
	if (is_string(_value)) return _value;
	var _n, _i, _s;
	if (is_struct(_value)) {
		var _e = _value[$"__enum__"];
		// 普通结构体没有枚举元数据
		if (_e == undefined) return string(_value);
		var _ects = _e.constructors;
		if (_ects != undefined) {
			_i = _value.__enumIndex__;
			if (_i >= 0 && _i < array_length(_ects)) _s = _ects[_i]; else _s = "?";
		} else {
			_s = instanceof(_value);
			// 去掉生成类名前缀，只留构造名
			if (string_copy(_s, 1, 3) == "mc_") _s = string_delete(_s, 1, 3);
			_n = string_length(_e.name);
			if (string_copy(_s, 1, _n) == _e.name) _s = string_delete(_s, 1, _n + 1);
		}
		_s += "(";
		var _fields = _value.__enumParams__;
		_n = array_length(_fields);
		for (_i = -1; ++_i < _n; _s += gif_std_Std_stringify(_value[$ _fields[_i]])) {
			if (_i > 0) _s += ", ";
		}
		return _s + ")";
	}
	if (is_real(_value)) {
		_s = string_format(_value, 0, 16);
		if (os_browser != browser_not_a_browser) {
			_n = string_length(_s);
			_i = _n;
			// 浏览器上按字符削掉尾部的 0
			while (_i > 0) {
				switch (string_ord_at(_s, _i)) {
					case 48:
						_i--;
						continue;
					case 46: _i--; break;
				}
				break;
			}
		} else {
			_n = string_byte_length(_s);
			_i = _n;
			// 原生平台按字节削掉尾部的 0
			while (_i > 0) {
				switch (string_byte_at(_s, _i)) {
					case 48:
						_i--;
						continue;
					case 46: _i--; break;
				}
				break;
			}
		}
		return string_copy(_s, 1, _i);
	}
	return string(_value);
}

#endregion

#region format.gif.block

/// @interface {format_gif_block}
///@desc GIF 块枚举基类
///@returns {Struct} 枚举基类
function mc_format_gif_block() constructor {
	/// @hint {array} format_gif_block:__enumParams__
	/// @hint {int} format_gif_block:__enumIndex__
	static getIndex = method(undefined, gif_std_enum_getIndex);
	static toString = method(undefined, gif_std_enum_toString);
	static __enum__ = mt_format_gif_block;
}

/// @implements {format_gif_block}
///@desc 图像帧块
///@returns {Struct} 枚举值
function mc_format_gif_block_bframe() : mc_format_gif_block() constructor {
	/// @hint {format_gif_Frame} :frame
	static __enumParams__ = ["frame"];
	static __enumIndex__ = 0;
}

///@desc 构造图像帧块
///@param {Struct} _frame 帧
///@returns {Struct} 块
function format_gif_block_bframe(_frame) {
	var _this = new mc_format_gif_block_bframe();
	_this.frame = _frame;
	return _this
}

/// @implements {format_gif_block}
///@desc 扩展块
///@returns {Struct} 枚举值
function mc_format_gif_block_bextension() : mc_format_gif_block() constructor {
	/// @hint {format_gif_extension} :extension
	static __enumParams__ = ["extension"];
	static __enumIndex__ = 1;
}

///@desc 构造扩展块
///@param {Struct} _extension 扩展
///@returns {Struct} 块
function format_gif_block_bextension(_extension) {
	var _this = new mc_format_gif_block_bextension();
	_this.extension = _extension;
	return _this
}

/// @implements {format_gif_block}
///@desc 文件结束块
///@returns {Struct} 枚举值
function mc_format_gif_block_beof() : mc_format_gif_block() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 2;
}
globalvar format_gif_block_beof; format_gif_block_beof = new mc_format_gif_block_beof(); /// @is {format_gif_block}

#endregion

#region format.gif.extension

/// @interface {format_gif_extension}
///@desc GIF 扩展枚举基类
///@returns {Struct} 枚举基类
function mc_format_gif_extension() constructor {
	/// @hint {array} format_gif_extension:__enumParams__
	/// @hint {int} format_gif_extension:__enumIndex__
	static getIndex = method(undefined, gif_std_enum_getIndex);
	static toString = method(undefined, gif_std_enum_toString);
	static __enum__ = mt_format_gif_extension;
}

/// @implements {format_gif_extension}
///@desc 图形控制扩展
///@returns {Struct} 枚举值
function mc_format_gif_extension_egraphic_control() : mc_format_gif_extension() constructor {
	/// @hint {format_gif_GraphicControlExtension} :gce
	static __enumParams__ = ["gce"];
	static __enumIndex__ = 0;
}

///@desc 构造图形控制扩展
///@param {Struct} _gce 图形控制数据
///@returns {Struct} 扩展
function format_gif_extension_egraphic_control(_gce) {
	var _this = new mc_format_gif_extension_egraphic_control();
	_this.gce = _gce;
	return _this
}

/// @implements {format_gif_extension}
///@desc 注释扩展
///@returns {Struct} 枚举值
function mc_format_gif_extension_ecomment() : mc_format_gif_extension() constructor {
	/// @hint {string} :text
	static __enumParams__ = ["text"];
	static __enumIndex__ = 1;
}

///@desc 构造注释扩展
///@param {String} _text 注释
///@returns {Struct} 扩展
function format_gif_extension_ecomment(_text) {
	var _this = new mc_format_gif_extension_ecomment();
	_this.text = _text;
	return _this
}

/// @implements {format_gif_extension}
///@desc 纯文本扩展
///@returns {Struct} 枚举值
function mc_format_gif_extension_etext() : mc_format_gif_extension() constructor {
	/// @hint {format_gif_PlainTextExtension} :pte
	static __enumParams__ = ["pte"];
	static __enumIndex__ = 2;
}

///@desc 构造纯文本扩展
///@param {Struct} _pte 纯文本数据
///@returns {Struct} 扩展
function format_gif_extension_etext(_pte) {
	var _this = new mc_format_gif_extension_etext();
	_this.pte = _pte;
	return _this
}

/// @implements {format_gif_extension}
///@desc 应用扩展
///@returns {Struct} 枚举值
function mc_format_gif_extension_eapplication_extension() : mc_format_gif_extension() constructor {
	/// @hint {format_gif_application_extension} :ext
	static __enumParams__ = ["ext"];
	static __enumIndex__ = 3;
}

///@desc 构造应用扩展
///@param {Struct} _ext 应用扩展数据
///@returns {Struct} 扩展
function format_gif_extension_eapplication_extension(_ext) {
	var _this = new mc_format_gif_extension_eapplication_extension();
	_this.ext = _ext;
	return _this
}

/// @implements {format_gif_extension}
///@desc 未知扩展
///@returns {Struct} 枚举值
function mc_format_gif_extension_eunknown() : mc_format_gif_extension() constructor {
	/// @hint {int} :id
	/// @hint {gif_std_haxe_io_Bytes} :data
	static __enumParams__ = ["id", "data"];
	static __enumIndex__ = 4;
}

///@desc 构造未知扩展
///@param {Real} _id 扩展标识
///@param {Struct} _data 原始字节
///@returns {Struct} 扩展
function format_gif_extension_eunknown(_id, _data) {
	var _this = new mc_format_gif_extension_eunknown();
	_this.id = _id;
	_this.data = _data;
	return _this
}

#endregion

#region format.gif.application_extension

/// @interface {format_gif_application_extension}
///@desc 应用扩展枚举基类
///@returns {Struct} 枚举基类
function mc_format_gif_application_extension() constructor {
	/// @hint {array} format_gif_application_extension:__enumParams__
	/// @hint {int} format_gif_application_extension:__enumIndex__
	static getIndex = method(undefined, gif_std_enum_getIndex);
	static toString = method(undefined, gif_std_enum_toString);
	static __enum__ = mt_format_gif_application_extension;
}

/// @implements {format_gif_application_extension}
///@desc NETSCAPE 循环次数
///@returns {Struct} 枚举值
function mc_format_gif_application_extension_aenetscape_looping() : mc_format_gif_application_extension() constructor {
	/// @hint {int} :loops
	static __enumParams__ = ["loops"];
	static __enumIndex__ = 0;
}

///@desc 构造 NETSCAPE 循环扩展
///@param {Real} _loops 循环次数
///@returns {Struct} 应用扩展
function format_gif_application_extension_aenetscape_looping(_loops) {
	var _this = new mc_format_gif_application_extension_aenetscape_looping();
	_this.loops = _loops;
	return _this
}

/// @implements {format_gif_application_extension}
///@desc 未知应用扩展
///@returns {Struct} 枚举值
function mc_format_gif_application_extension_aeunknown() : mc_format_gif_application_extension() constructor {
	/// @hint {string} :name
	/// @hint {string} :version
	/// @hint {gif_std_haxe_io_Bytes} :data
	static __enumParams__ = ["name", "version", "data"];
	static __enumIndex__ = 1;
}

///@desc 构造未知应用扩展
///@param {String} _name 应用名
///@param {String} _version 版本
///@param {Struct} _data 原始字节
///@returns {Struct} 应用扩展
function format_gif_application_extension_aeunknown(_name, _version, _data) {
	var _this = new mc_format_gif_application_extension_aeunknown();
	_this.name = _name;
	_this.version = _version;
	_this.data = _data;
	return _this
}

#endregion

#region format.gif.version

/// @interface {format_gif_version}
///@desc GIF 版本枚举基类
///@returns {Struct} 枚举基类
function mc_format_gif_version() constructor {
	/// @hint {array} format_gif_version:__enumParams__
	/// @hint {int} format_gif_version:__enumIndex__
	static getIndex = method(undefined, gif_std_enum_getIndex);
	static toString = method(undefined, gif_std_enum_toString);
	static __enum__ = mt_format_gif_version;
}

/// @implements {format_gif_version}
///@desc GIF87a 版本
///@returns {Struct} 枚举值
function mc_format_gif_version_gif87a() : mc_format_gif_version() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 0;
}
globalvar format_gif_version_gif87a; format_gif_version_gif87a = new mc_format_gif_version_gif87a(); /// @is {format_gif_version}

/// @implements {format_gif_version}
///@desc GIF89a 版本
///@returns {Struct} 枚举值
function mc_format_gif_version_gif89a() : mc_format_gif_version() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 1;
}
globalvar format_gif_version_gif89a; format_gif_version_gif89a = new mc_format_gif_version_gif89a(); /// @is {format_gif_version}

/// @implements {format_gif_version}
///@desc 未知 GIF 版本
///@returns {Struct} 枚举值
function mc_format_gif_version_unknown() : mc_format_gif_version() constructor {
	/// @hint {string} :version
	static __enumParams__ = ["version"];
	static __enumIndex__ = 2;
}

///@desc 构造未知版本
///@param {String} _version 版本串
///@returns {Struct} 版本
function format_gif_version_unknown(_version) {
	var _this = new mc_format_gif_version_unknown();
	_this.version = _version;
	return _this
}

#endregion

#region format.gif.disposal_method

/// @interface {format_gif_disposal_method}
///@desc 帧处置方式枚举基类
///@returns {Struct} 枚举基类
function mc_format_gif_disposal_method() constructor {
	/// @hint {array} format_gif_disposal_method:__enumParams__
	/// @hint {int} format_gif_disposal_method:__enumIndex__
	static getIndex = method(undefined, gif_std_enum_getIndex);
	static toString = method(undefined, gif_std_enum_toString);
	static __enum__ = mt_format_gif_disposal_method;
}

/// @implements {format_gif_disposal_method}
///@desc 未指定处置
///@returns {Struct} 枚举值
function mc_format_gif_disposal_method_unspecified() : mc_format_gif_disposal_method() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 0;
}
globalvar format_gif_disposal_method_unspecified; format_gif_disposal_method_unspecified = new mc_format_gif_disposal_method_unspecified(); /// @is {format_gif_disposal_method}

/// @implements {format_gif_disposal_method}
///@desc 不处置，留下本帧
///@returns {Struct} 枚举值
function mc_format_gif_disposal_method_no_action() : mc_format_gif_disposal_method() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 1;
}
globalvar format_gif_disposal_method_no_action; format_gif_disposal_method_no_action = new mc_format_gif_disposal_method_no_action(); /// @is {format_gif_disposal_method}

/// @implements {format_gif_disposal_method}
///@desc 用背景盖住本帧
///@returns {Struct} 枚举值
function mc_format_gif_disposal_method_fill_background() : mc_format_gif_disposal_method() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 2;
}
globalvar format_gif_disposal_method_fill_background; format_gif_disposal_method_fill_background = new mc_format_gif_disposal_method_fill_background(); /// @is {format_gif_disposal_method}

/// @implements {format_gif_disposal_method}
///@desc 恢复到绘制本帧之前
///@returns {Struct} 枚举值
function mc_format_gif_disposal_method_render_previous() : mc_format_gif_disposal_method() constructor {
	static __enumParams__ = [];
	static __enumIndex__ = 3;
}
globalvar format_gif_disposal_method_render_previous; format_gif_disposal_method_render_previous = new mc_format_gif_disposal_method_render_previous(); /// @is {format_gif_disposal_method}

/// @implements {format_gif_disposal_method}
///@desc 规范未定义的处置序号
///@returns {Struct} 枚举值
function mc_format_gif_disposal_method_undefined_hx() : mc_format_gif_disposal_method() constructor {
	/// @hint {int} :index
	static __enumParams__ = ["index"];
	static __enumIndex__ = 4;
}

///@desc 构造未定义的处置方式
///@param {Real} _index 原始序号
///@returns {Struct} 处置方式
function format_gif_disposal_method_undefined_hx(_index) {
	var _this = new mc_format_gif_disposal_method_undefined_hx();
	_this.index = _index;
	return _this
}

#endregion

#region gif_std.haxe.class

///@desc 登记一个 Haxe 类的元数据
///@param {Real} _id 类型序号
///@param {String} _name 类型名
///@returns {Struct} 类元数据
function gif_std_haxe_class(_id, _name) constructor {
	static superClass = undefined; /// @is {haxe_class<any>}
	static marker = undefined; /// @is {any}
	static index = undefined; /// @is {int}
	static name = undefined; /// @is {string}
	self.superClass = undefined;
	self.marker = gif_std_haxe_type_markerValue;
	self.index = _id;
	self.name = _name;
	static __class__ = "class";
}

#endregion

#region gif_std.haxe.enum

///@desc 登记一个 Haxe 枚举的元数据
///@param {Real} _id 类型序号
///@param {String} _name 类型名
///@param {Array} _constructors 构造名
///@param {Array} _functions 构造函数
///@returns {Struct} 枚举元数据
function gif_std_haxe_enum(_id, _name, _constructors, _functions) constructor {
	static constructors = undefined; /// @is {array<string>}
	static functions = undefined; /// @is {array<function>}
	static marker = undefined; /// @is {any}
	static index = undefined; /// @is {int}
	static name = undefined; /// @is {string}
	if (false) show_debug_message(argument[3]);
	self.marker = gif_std_haxe_type_markerValue;
	self.index = _id;
	self.name = _name;
	self.constructors = _constructors;
	self.functions = _functions;
	static __class__ = "enum";
}

#endregion

#region gif_std.gml.NativeTypeHelper

///@desc 判断值是不是数值类型
///@param {Any} _v 任意值
///@returns {Bool} 实数、布尔或整数时为真
function gif_std_gml_NativeTypeHelper_isNumber(_v) {
	return (is_real(_v) || is_bool(_v) || is_int32(_v)) || is_int64(_v);
}

#endregion

#region gif_std.gml.internal.ArrayImpl

///@desc 复制数组，空数组返回新的空数组
///@param {Array} _arr 源数组
///@returns {Array} 副本
function gif_std_gml_internal_ArrayImpl_copy(_arr) {
	var _out;
	var _len = array_length(_arr);
	// 长度为 0 时 array_create 不能用来复制
	if (_len > 0) {
		_out = array_create(_len, 0);
		array_copy(_out, 0, _arr, 0, _len);
	} else _out = [];
	return _out;
}

#endregion

#region gif_std.gml.io._Buffer.BufferImpl

///@desc 从源缓冲拷贝一段到目标缓冲
///@param {Real} _src 源缓冲
///@param {Real} _dst 目标缓冲
///@param {Real} _dstPos 目标起点
///@param {Real} _len 请求长度
///@returns {Real} 实际写入的字节数
function gif_std_gml_io__Buffer_BufferImpl_readBuffer(_src, _dst, _dstPos, _len) {
	var _srcPos = buffer_tell(_src);
	var _srcLen = min(_len, buffer_get_size(_src) - _srcPos);
	var _dstLen = min(_srcLen, buffer_get_size(_dst) - _dstPos);
	// 源已经没有剩余字节
	if (_srcLen < 0) return 0;
	// 目标放不下时仍把源指针按请求长度前移
	if (_dstLen < 0) {
		buffer_seek(_src, buffer_seek_relative, _srcLen);
		return 0;
	}
	buffer_copy(_src, _srcPos, _dstLen, _dst, _dstPos);
	buffer_seek(_src, buffer_seek_relative, _srcLen);
	return _dstLen;
}

#endregion

#region gif_std.haxe.io.Bytes

///@desc 包一层字节数组
///@param {Array} _b 字节
///@returns {Struct} 字节对象
function gif_std_haxe_io_Bytes(_b) constructor {
	static b = undefined; /// @is {haxe_io_BytesData}
	self.b = _b;
	static __class__ = mt_gif_std_haxe_io_Bytes;
}

#endregion

#region haxe.io._bytes.bytes_impl

///@desc 从字节数组读出以 0 结尾的字符串
///@param {Array} _d 字节
///@param {Real} _pos 起点
///@param {Real} _len 长度
///@returns {String} 文本
function haxe_io__bytes_bytes_impl_get_string(_d, _pos, _len) {
	var _b = haxe_io__bytes_bytes_impl_buffer;
	buffer_seek(_b, buffer_seek_start, 0);
	while (--_len >= 0) {
		buffer_write(_b, buffer_u8, _d[_pos++]);
	}
	buffer_write(_b, buffer_u8, 0);
	buffer_seek(_b, buffer_seek_start, 0);
	return buffer_read(_b, buffer_string);
}

#endregion

#region gif_std.haxe.io.Output

///@desc 初始化输出缓冲的长度和位置
///@returns {Undefined} 无
function gif_std_haxe_io_Output_new() {
	self.dataLen = 32;
	self.dataPos = 0;
	self.data = array_create(32, 0);
}

///@desc 可增长的字节输出
///@returns {Struct} 输出对象
function gif_std_haxe_io_Output() constructor {
	static data = undefined; /// @is {haxe_io_BytesData}
	static dataPos = undefined; /// @is {int}
	static dataLen = undefined; /// @is {int}
	static flush = method(undefined, gif_std_haxe_io_Output_flush);
	static close = method(undefined, gif_std_haxe_io_Output_close);
	static writeBytes = method(undefined, gif_std_haxe_io_Output_writeBytes);
	method(self, gif_std_haxe_io_Output_new)();
	static __class__ = mt_gif_std_haxe_io_Output;
}

///@desc 刷新输出，当前为空操作
///@returns {Undefined} 无
function gif_std_haxe_io_Output_flush() {
	
}

///@desc 关闭输出，当前为空操作
///@returns {Undefined} 无
function gif_std_haxe_io_Output_close() {
	
}

///@desc 把一段字节写入输出，空间不够时成倍扩容
///@param {Struct} _b 字节对象
///@param {Real} _pos 源起点
///@param {Real} _len 长度
///@returns {Real} 写入长度
function gif_std_haxe_io_Output_writeBytes(_b, _pos, _len) {
	var _bd = _b.b;
	var _p0 = self.dataPos;
	var _p1 = _p0 + _len;
	var _d = self.data;
	var _dlen = self.dataLen;
	// 容量不够时成倍扩大，并再多留一倍
	if (_p1 > _dlen) {
		do {
			_dlen *= 2;
		} until (_p1 <= _dlen);
		_dlen *= 2;
		_d[@_dlen - 1] = 0;
		self.dataLen = _dlen;
	}
	array_copy(_d, _p0, _bd, _pos, _len);
	self.dataPos = _p1;
	return _len;
}

#endregion

#region gif_std.haxe.io.BytesOutput

///@desc 字节输出，继承输出的写入方法
///@returns {Struct} 字节输出
function gif_std_haxe_io_BytesOutput() constructor {
	static data = undefined; /// @is {haxe_io_BytesData}
	static dataPos = undefined; /// @is {int}
	static dataLen = undefined; /// @is {int}
	static flush = method(undefined, gif_std_haxe_io_Output_flush);
	static close = method(undefined, gif_std_haxe_io_Output_close);
	static writeBytes = method(undefined, gif_std_haxe_io_Output_writeBytes);
	method(self, gif_std_haxe_io_Output_new)();
	static __class__ = mt_gif_std_haxe_io_BytesOutput;
}

#endregion

// gif_drawer 处置背景用的白块。
globalvar gif_drawer_white32; /// @is {sprite}
gif_drawer_white32 = -1;
// gif_raw_reader 读字符串用的临时缓冲。
globalvar gif_raw_reader_read_string_tmp_buf; /// @is {buffer}
gif_raw_reader_read_string_tmp_buf = -1;
// 字节转字符串用的共享缓冲。
globalvar haxe_io__bytes_bytes_impl_buffer; /// @is {buffer}
haxe_io__bytes_bytes_impl_buffer = buffer_create(128, buffer_grow, 1);


/// @typedef {array<int>} haxe_io_BytesData
/// @typedef {any} format_gif_PlainTextExtension
/// @typedef {any} format_gif_GraphicControlExtension
/// @typedef {any} format_gif_Frame
/// @typedef {any} GifData