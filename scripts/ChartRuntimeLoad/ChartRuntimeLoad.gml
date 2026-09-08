/// @desc Shared loading-frame create / freeze / thaw for Official, PEC, and RPE.
/// Create + full init first, then freeze. Activate is deferred one event,
/// so thaw force-init runs the next frame before oPlayTransition / m_play().

#macro CHART_LINE_CREATE_BUDGET_US 8000

function chart_lines_hide_created(_inst) {
	if (instance_exists(_inst)
		&& variable_global_exists("loading_animation_active")
		&& global.loading_animation_active) {
		_inst.visible = false;
	};
}

function chart_note_activate(_inst) {
	instance_activate_object(_inst);
	if (instance_exists(_inst)) then _inst.visible = true;
}

function chart_lines_freeze_object(_object) {
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	instance_deactivate_object(_object);
}

function chart_load_flags_reset() {
	_chart_lines_building = false;
	_chart_lines_thaw_pending = false;
	_chart_lines_frozen = false;
}

function chart_load_mark_ready(_frozen) {
	_chart_lines_building = false;
	_chart_lines_frozen = _frozen;
	chart_idle_behind_loading();
	global.loading_render_ready = true;
	chart_blur_bind_game(false);
	if (pls_is_gxgames()) then chart_loading_animation_finish();
}

function chart_load_begin_play(_sync_notes) {
	if (!instance_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
	instance_activate_object(oRPEEffect);
	instance_activate_object(oEffect);
	instance_activate_object(oEffectNew);
	_sync_notes();
	if (!instance_exists(oPlayTransition)) then instance_create_depth(0, 0, -999999, oPlayTransition, { owner: id });
}

/// @returns {Bool} true if the caller Step should exit this frame
function chart_load_step(_line_object, _pump, _finish, _thaw_force, _sync_notes) {
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

function chart_load_draw_suppressed() {
	if (variable_instance_exists(id, "_chart_lines_building") && _chart_lines_building) then return true;
	if (variable_instance_exists(id, "_chart_lines_thaw_pending") && _chart_lines_thaw_pending) then return true;
	if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return true;
	return false;
}
