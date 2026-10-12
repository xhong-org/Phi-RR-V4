// Official、PEC、RPE 共用的加载帧：先完整创建再冻结。
// 激活会推迟一个事件，强制解冻因此发生在下一帧，早于 oPlayTransition 和 m_play()。

#macro CHART_LINE_CREATE_BUDGET_US 8000

///@desc 加载动画期间先隐藏刚创建的判定线
///@param {Id.Instance} _inst 判定线实例
///@returns {Undefined} 无
function chart_lines_hide_created(_inst) {
	if (instance_exists(_inst)
		&& variable_global_exists("loading_animation_active")
		&& global.loading_animation_active) {
		_inst.visible = false;
	};
}

///@desc 激活音符并重新显示
///@param {Id.Instance} _inst 音符实例
///@returns {Undefined} 无
function chart_note_activate(_inst) {
	instance_activate_object(_inst);
	if (instance_exists(_inst)) then _inst.visible = true;
}

///@desc 冻结指定对象，渲染模式除外
///@param {Any} _object 要冻结的对象
///@returns {Undefined} 无
function chart_lines_freeze_object(_object) {
	// 渲染模式必须保持对象激活
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	instance_deactivate_object(_object);
}

///@desc 清掉分帧建线、待解冻和已冻结标记
///@returns {Undefined} 无
function chart_load_flags_reset() {
	_chart_lines_building = false;
	_chart_lines_thaw_pending = false;
	_chart_lines_frozen = false;
}

///@desc 标记谱面加载完成，并按需要保持冻结
///@param {Bool} _frozen 完成后是否仍处于冻结
///@returns {Undefined} 无
function chart_load_mark_ready(_frozen) {
	_chart_lines_building = false;
	_chart_lines_frozen = _frozen;
	chart_idle_behind_loading();
	// 大噪域还没收完时不放行，加载界面会停在停留阶段。
	official_block_notify_load_ready();
}

///@desc 创建遮罩和过场，并同步音符
///@param {Any} _sync_notes 同步音符的回调
///@returns {Undefined} 无
function chart_load_begin_play(_sync_notes) {
	if (!instance_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
	instance_activate_object(oRPEEffect);
	instance_activate_object(oEffect);
	instance_activate_object(oEffectNew);
	_sync_notes();
	if (!instance_exists(oPlayTransition)) then instance_create_depth(0, 0, -999999, oPlayTransition, { owner: id });
}

///@desc 推进分帧加载、解冻或开始游玩
///@param {Any} _line_object 判定线对象
///@param {Any} _pump 继续创建一批判定线的回调
///@param {Any} _finish 创建结束回调
///@param {Any} _thaw_force 强制解冻并补初始化的回调
///@param {Any} _sync_notes 同步音符的回调
///@returns {Bool} 调用方本帧应当退出时为真
function chart_load_step(_line_object, _pump, _finish, _thaw_force, _sync_notes) {
	// 待解冻、加载动画结束或仍在建线时，本帧都交给这里处理
	if (variable_instance_exists(id, "_chart_lines_thaw_pending") && _chart_lines_thaw_pending) {
		_thaw_force();
		chart_load_begin_play(_sync_notes);
		_chart_lines_thaw_pending = false;
		return true;
	};
	if (variable_global_exists("loading_animator_finished") && global.loading_animator_finished) {
		if (!instance_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
		if (variable_instance_exists(id, "_chart_lines_frozen") && _chart_lines_frozen) {
			instance_activate_object(_line_object);
			_chart_lines_thaw_pending = true;
			_chart_lines_frozen = false;
			global.loading_animator_finished = false;
			return true;
		};
		chart_load_begin_play(_sync_notes);
		global.loading_animator_finished = false;
		return true;
	};
	if (variable_instance_exists(id, "_chart_lines_building") && _chart_lines_building) {
		if (_pump()) {
			_finish();
			chart_load_mark_ready(!(variable_global_exists("render_mode") && global.render_mode));
		};
		return true;
	};
	return false;
}

///@desc 判断本帧是否应跳过谱面绘制
///@returns {Bool} 仍在建线、待解冻或加载动画中时为真
function chart_load_draw_suppressed() {
	// 建线、待解冻或加载动画期间都跳过绘制
	if (variable_instance_exists(id, "_chart_lines_building") && _chart_lines_building) then return true;
	if (variable_instance_exists(id, "_chart_lines_thaw_pending") && _chart_lines_thaw_pending) then return true;
	if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return true;
	return false;
}
