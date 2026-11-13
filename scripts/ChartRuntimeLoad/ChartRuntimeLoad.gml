// Official、PEC、RPE 共用的加载帧：先完整创建再冻结。
// 激活会推迟一个事件，强制解冻因此发生在下一帧，早于 oPlayTransition 和 m_play()。

#macro CHART_LINE_CREATE_BUDGET_US 8000

///@desc 解锁后的静止谱面从黑屏渐入；完成后由过场状态机开始原开场动画
function chart_unlock_fade_draw() {
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	if (!instance_exists(oPlayTransition)) then return;
	var _transition = instance_find(oPlayTransition, 0);
	if (_transition.state != PLAY_TRANSITION_STATE.UNLOCK_FADE) then return;
	if (_transition.unlock_fade_started_at < 0) {
		_transition.unlock_fade_started_at = get_timer();
		_transition.state_started_at = _transition.unlock_fade_started_at;
	};
	var _elapsed = max(0, get_timer() - _transition.unlock_fade_started_at);
	var _cover_alpha = 1 - clamp(_elapsed / _transition.unlock_fade_duration, 0, 1);
	if (_cover_alpha <= 0) then return;
	var _colour = draw_get_colour();
	var _alpha = draw_get_alpha();
	gpu_push_state();
	chart_hud_draw_prepare();
	draw_set_colour(c_black);
	draw_set_alpha(_cover_alpha);
	draw_rectangle(0, 0, room_width, room_height, false);
	pls_draw_flush();
	gpu_pop_state();
	draw_set_colour(_colour);
	draw_set_alpha(_alpha);
}

///@desc 解锁视频结束后的加载阶段只推进资源，不呈现谱面或加载界面
function chart_loading_silent() {
	if (!instance_exists(oLoadAnimator)) then return false;
	var _loader = instance_find(oLoadAnimator, 0);
	return variable_instance_exists(_loader, "mode") && _loader.mode == "silent";
}

///@desc 加载动画期间先隐藏刚创建的判定线
///@param {Id.Instance} _inst 判定线实例
///@returns {Undefined} 无
function chart_lines_hide_created(_inst) {
	if (chart_actor_exists(_inst)
		&& variable_global_exists("loading_animation_active")
		&& global.loading_animation_active) {
		_inst.visible = false;
	};
}

///@desc 激活音符并重新显示
///@param {Id.Instance} _inst 音符实例
///@returns {Undefined} 无
function chart_note_activate(_inst) {
	chart_actor_activate(_inst);
	if (!chart_actor_exists(_inst)) then return;
	if (!chart_autoplay_active()) {
		with (_inst) {
			if (chart_actor_var_exists(id, "kb_record") && is_struct(kb_record)
				&& kb_record.owner == game[$ "keyboard_judge"] && kb_record.closed && hit_status != TYPE.BAD) {
				chart_actor_deactivate(self);
				return;
			}
			chart_kb_register_note();
		}
	}
	if (chart_actor_exists(_inst)) _inst.visible = true;
}

///@desc 冻结指定对象，渲染模式除外
///@param {Any} _object 要冻结的对象
///@returns {Undefined} 无
function chart_lines_freeze_object(_object) {
	// 渲染模式必须保持对象激活
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	chart_actor_deactivate(_object);
}

///@desc 清掉分帧建线、待解冻和已冻结标记
///@returns {Undefined} 无
function chart_load_flags_reset() {
	chart_kb_reset();
	global.chart_layer_layout = undefined;
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
	if (!chart_actor_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
	chart_actor_activate(oRPEEffect);
	chart_actor_activate(oEffect);
	chart_actor_activate(oEffectNew);
	_sync_notes();
	if (!chart_actor_exists(oPlayTransition)) then instance_create_depth(0, 0, -999999, oPlayTransition, { owner: id });
}

///@desc 推进分帧加载、解冻或开始游玩
///@param {Any} _line_object 判定线对象
///@param {Any} _pump 继续创建一批判定线的回调
///@param {Any} _finish 创建结束回调
///@param {Any} _thaw_force 强制解冻并补初始化的回调
///@param {Any} _sync_notes 同步音符的回调
///@returns {Bool} 调用方本帧应当退出时为真
function chart_load_step(_line_object, _pump, _finish, _thaw_force, _sync_notes) {
	// GX 的加载动画可能先于 YYC 分帧建线结束；先完成创建再放行播放。
	if (pls_is_gxgames() && chart_actor_var_exists(id, "_chart_lines_building") && _chart_lines_building) {
		if (_pump()) {
			_finish();
			chart_load_mark_ready(!(variable_global_exists("render_mode") && global.render_mode));
		};
		return true;
	};
	// 待解冻、加载动画结束或仍在建线时，本帧都交给这里处理
	if (chart_actor_var_exists(id, "_chart_lines_thaw_pending") && _chart_lines_thaw_pending) {
		_thaw_force();
		chart_load_begin_play(_sync_notes);
		_chart_lines_thaw_pending = false;
		return true;
	};
	if (variable_global_exists("loading_animator_finished") && global.loading_animator_finished) {
		if (!chart_actor_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
		if (chart_actor_var_exists(id, "_chart_lines_frozen") && _chart_lines_frozen) {
			chart_actor_activate(_line_object);
			_chart_lines_thaw_pending = true;
			_chart_lines_frozen = false;
			global.loading_animator_finished = false;
			return true;
		};
		chart_load_begin_play(_sync_notes);
		global.loading_animator_finished = false;
		return true;
	};
	if (chart_actor_var_exists(id, "_chart_lines_building") && _chart_lines_building) {
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
	if (chart_actor_var_exists(id, "_chart_lines_building") && _chart_lines_building) then return true;
	if (chart_actor_var_exists(id, "_chart_lines_thaw_pending") && _chart_lines_thaw_pending) then return true;
	if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return true;
	return false;
}
