///@desc 创建开场、游玩和结束共用的过场状态
if (!variable_instance_exists(id, "owner")) then owner = noone;
// 画在谱面合成遮罩之前，动画线才会被一起裁切。
depth = DEPTH.HEF + 2;

enum PLAY_TRANSITION_STATE {
	WAIT_MEDIA,
	INTRO_DELAY,
	INTRO,
	START_DELAY,
	PLAYING,
	OUTRO,
	EXIT_DELAY,
	SETTLEMENT,
	FINISHED
};

state = PLAY_TRANSITION_STATE.WAIT_MEDIA;
state_started_at = get_timer();
intro_delay = 100000;
animation_duration = 1000000;
play_delay = 500000;
exit_delay = 1000000;
progress = 0;
line_progress = 0;
mask_end_phase = 0;
mask_released = false;
end_cover_alpha = 0;
end_cover_span = 0;
end_phase_origin_s = 0;
render_started_frame = 0;
render_outro_started_frame = 0;
render_exit_delay_started_frame = 0;
transition_instances = [];
chart_instances_activation_requested = false;

///@desc 隐藏游玩对象，过场期间不重复停用判定线
///@returns {Undefined} 无
function play_transition_deactivate_gameplay() {
	// 已经藏过一次就返回。这里不停用判定线，二次停用会跳过线事件初始化。
	if (array_length(transition_instances) > 0) then return;
	chart_set_gameplay_visible(false);
	if (instance_exists(oEffect)) then with (oEffect) isDraw = false;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = false;
	transition_instances = [true];
}

///@desc 重新显示游玩对象和打击特效
///@returns {Undefined} 无
function play_transition_activate_gameplay() {
	chart_set_gameplay_visible(true);
	transition_instances = [];
	if (instance_exists(oEffect)) then with (oEffect) isDraw = true;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = true;
}

///@desc 按渲染器同步当前谱面的音符激活
///@returns {Undefined} 无
function play_transition_activate_chart_instances() {
    // 没有宿主渲染器就无法同步。
    if (!instance_exists(owner)) then return;
    if (owner.object_index == oRender_1) {
        rpe_sync_note_activation();
    } else if (owner.object_index == oRender_2) {
        pec_sync_note_activation();
    } else if (owner.object_index == oRender) {
        official_sync_note_activation();
    };
    chart_instances_activation_requested = true;
}

///@desc 标记仍被判定线绑定的 RPE 界面槽
///@returns {Undefined} 无
function play_transition_sync_bound_ui() {
	// 只有 RPE 渲染器有绑定界面。
	if (!instance_exists(owner) || owner.object_index != oRender_1) then return;
	if (!variable_instance_exists(owner, "play_transition_bound_ui")
		|| !is_struct(owner.play_transition_bound_ui)) then return;

	// 过场里判定线只是隐藏。遍历保留的线表，子线的 attachUI 才不会丢。
	var _render_owner = owner;
	if (variable_global_exists("game_1") && is_struct(game_1)
		&& is_array(game_1.line_list)) {
		var _lines = game_1.line_list;
		// 跳过没有界面绑定键的线。
		for (var _line_i = 0; _line_i < array_length(_lines); _line_i++) {
			var _line = _lines[_line_i];
			if (!instance_exists(_line) || !_line.is_attach_ui
				|| !is_string(_line.attach_ui_key) || !string_length(_line.attach_ui_key)
				|| !struct_exists(_render_owner.play_transition_bound_ui, _line.attach_ui_key)) then continue;
			_render_owner.play_transition_bound_ui[$ _line.attach_ui_key] = true;
		};
	};
}

///@desc 把过场进度写到宿主界面的位移和透明度
///@param {Real} _value 0 到 1 的进度
///@param {Bool} _outro 为真时按结束动画反向插值
///@returns {Undefined} 无
function play_transition_apply(_value, _outro = false) {
	// 宿主不在就无法写界面。
	if (!instance_exists(owner)) then return;
	var _p = clamp(_value, 0, 1);
	var _hidden = _outro ? _p : (1 - _p);
	play_transition_sync_bound_ui();
	owner.play_transition_active = true;
	owner.play_transition_pause_y = -max(1, 70 * global_scales) * _hidden;
	owner.play_transition_name_y = max(1, 60 * global_scales) * _hidden;
	owner.play_transition_level_y = max(1, 60 * global_scales) * _hidden;
	owner.play_transition_score_y = -max(1, 110 * global_scales) * _hidden;
	owner.play_transition_ui_alpha = _outro ? (1 - _p) : 1;
	owner.play_transition_bar_alpha = _outro ? 1 : _p;
	var _outro_bg_end = 0.5;
	// 录像且不录结算时，结束背景直接收到 0。
	if (variable_global_exists("render_mode") && global.render_mode && !render_wants_settlement()) {
		_outro_bg_end = 0;
	};
	owner.play_transition_bg_alpha = _outro ? lerp(1, _outro_bg_end, _p) : _p;
	line_progress = _outro ? (1 - _p) : _p;
}

///@desc 推进结束阶段，并在遮罩释放后切换黑边
///@param {Real} _elapsed 本阶段已经过的时间
///@param {Real} _duration 本阶段时长
///@returns {Real} 0 继续，1 进入下一小段，2 结束阶段完成
function play_transition_step_end_phase(_elapsed, _duration) {
	var _dur = max(0.000001, _duration);
	progress = clamp(_elapsed / _dur, 0, 1);
	var _eased = Easings.InOutExpo(progress);
	// 没有谱面遮罩时只做界面退场。
	if (!chart_mask_enabled()) {
		mask_released = false;
		end_cover_alpha = 0;
		end_cover_span = 0;
		play_transition_apply(_eased, true);
		owner.chart_exit_alpha = 1 - _eased;
		// 这一小段还没走完就继续等。
		if (progress < 1) then return 0;
		play_transition_apply(1, true);
		owner.chart_exit_alpha = 0;
		line_progress = 0;
		return 2;
	};
	// 第一段退界面并释放遮罩。
	if (mask_end_phase <= 0) {
		mask_released = false;
		end_cover_alpha = 0;
		end_cover_span = 0;
		play_transition_apply(_eased, true);
		owner.play_transition_bg_alpha = 1;
		owner.chart_exit_alpha = 1 - _eased;
		if (progress < 1) then return 0;
		line_progress = 0;
		mask_end_phase = 1;
		mask_released = true;
		depth = -12200;
		end_cover_alpha = 0.6;
		end_cover_span = 0;
		owner.play_transition_bg_alpha = 0;
		return 1;
	};
	// 第二段把遮罩黑边淡出。
	if (mask_end_phase == 1) {
		mask_released = true;
		line_progress = 0;
		play_transition_apply(1, true);
		owner.play_transition_bg_alpha = 0;
		owner.chart_exit_alpha = 0;
		end_cover_span = 1;
		end_cover_alpha = lerp(0.6, 0, _eased);
		if (progress < 1) then return 0;
		mask_end_phase = 2;
		end_cover_alpha = 0;
		end_cover_span = 1;
		return 1;
	};
	mask_released = true;
	line_progress = 0;
	play_transition_apply(1, true);
	owner.play_transition_bg_alpha = 0;
	owner.chart_exit_alpha = 0;
	end_cover_span = 1;
	end_cover_alpha = lerp(0, 0.3, _eased);
	if (progress < 1) then return 0;
	end_cover_alpha = 0.3;
	return 2;
}

///@desc 清掉结束遮罩并重新播放开场
///@returns {Undefined} 无
function play_transition_restart_intro() {
	// 结算重试会留下结束遮罩，这里必须清掉。开场压暗只在遮罩还被握住时发生。
	mask_end_phase = 0;
	mask_released = false;
	end_cover_alpha = 0;
	end_cover_span = 0;
	end_phase_origin_s = 0;
	depth = DEPTH.HEF + 2;
	progress = 0;
	line_progress = 0;
	state = PLAY_TRANSITION_STATE.INTRO;
	state_started_at = get_timer();
	play_transition_deactivate_gameplay();
	play_transition_apply(0);
}

///@desc 暂停播放并进入结束过场
///@returns {Undefined} 无
function play_transition_begin_exit() {
	// 已经在结束或更后面就不再开始。
	if (state >= PLAY_TRANSITION_STATE.OUTRO) then return;
	game.paused = true;
	m_pause();
	play_transition_deactivate_gameplay();
	state = PLAY_TRANSITION_STATE.OUTRO;
	state_started_at = get_timer();
}

///@desc 拆掉播放并回到入口或结束游戏
///@returns {Undefined} 无
function play_transition_finish_exit() {
	// 宿主没了就无法排队退出。
	if (!instance_exists(owner)) then return;
	owner.chart_exit_queued = true;
	chart_playback_teardown_for_menu();
	state = PLAY_TRANSITION_STATE.FINISHED;
	if (variable_global_exists("pls_environment_run") && global.pls_environment_run) then game_end();
	else pls_return_to_entry();
}

play_transition_apply(0);
if (variable_global_exists("game") && is_struct(game)) then game.paused = true;
play_transition_deactivate_gameplay();
if (instance_exists(oLoadAnimator)) then chart_loading_animation_finish();
