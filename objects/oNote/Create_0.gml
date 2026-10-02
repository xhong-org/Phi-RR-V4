/// @description Cache immutable values before entering the note hot path.
depth = DEPTH.NOTE;
inition = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

_is_hold = (self.type == 3);
_step_user_count = (_is_hold ? 2 : 1);
_judge_user_count = (_is_hold ? 6 : 5);
_beat_per_second = (self.bpm / 1.875);
_seconds_per_beat = (1 / _beat_per_second);
if (!is_real(self.line_id)) then self.line_id = 0;
if (!is_array(game.line_list) || self.line_id < 0 || self.line_id >= array_length(game.line_list)) {
        show_debug_message($"[oNote] invalid line_id={self.line_id}, lines={is_array(game.line_list) ? array_length(game.line_list) : -1}");
        instance_destroy();
        exit;
};
_line_ref = (game.line_list[self.line_id]);
_last_global_scales = -1;
_now_seconds = 0;
_now_beat = 0;

event_user(0);

canDraw = false;
hl = self._hl;

var late_ms = _is_hold ? 161 : ((self.type == 2 || self.type == 4) ? 160 : 201);
lateHitTime = (late_ms * 0.001 * _beat_per_second);
