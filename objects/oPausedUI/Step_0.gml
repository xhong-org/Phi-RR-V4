if (!instance_exists(owner)) {
        instance_destroy();
        exit;
};
paused_ui_refresh_layout();
if (!paused_ui_can_control()) then exit;

gui_width = max(1, room_width);
gui_height = max(1, room_height);
ui_scale = max(0.5, min(gui_width / 1366, gui_height / 768));
button_y = gui_height * 0.5;
var spacing = min(gui_width * 0.18, 170 * ui_scale);
button_x[0] = gui_width * 0.5 - spacing;
button_x[1] = gui_width * 0.5;
button_x[2] = gui_width * 0.5 + spacing;

if (retry_waiting) {
        if (get_timer() - retry_started_at >= retry_delay) {
                var completed_mode = retry_mode;
                retry_waiting = false;
                retry_mode = 0;
                action_queued = false;
                if (completed_mode == 1) {
			if (instance_exists(oPlayTransition)) {
				var transition = instance_find(oPlayTransition, 0);
				transition.state = PLAY_TRANSITION_STATE.INTRO;
				transition.state_started_at = get_timer();
				transition.progress = 0;
				transition.play_transition_deactivate_gameplay();
				transition.play_transition_apply(0);
				print("[PausedUI] Retry prepare animation started");
			} else {
				m_play();
				game.Math.now(0);
				game.paused = false;
			};
                } else {
                        m_resume();
                        array_set(game.__time, 4, get_timer());
                        game.Math.ptime();
                        print("[PausedUI] Resume playback started");
                };
		if (completed_mode != 1) then game.paused = false;
        };
        exit;
};

if (game.paused && !was_paused) then opened_at = get_timer();
was_paused = game.paused;

var mouse_gui_x = mouse_x;
var mouse_gui_y = mouse_y;
var button_pressed = mouse_check_button_pressed(mb_left);

if (!game.paused) {
		if (button_pressed && point_in_rectangle(mouse_gui_x, mouse_gui_y,
				pause_button_x - pause_button_radius, pause_button_y - pause_button_radius,
				pause_button_x + pause_button_radius, pause_button_y + pause_button_radius)) {
                var click_now = get_timer();
                if (click_now > pause_click_deadline) then pause_click_count = 0;
                pause_click_count++;
                pause_click_deadline = click_now + 1000000;
                if (pause_click_count >= 2) {
                        pause_click_count = 0;
                        paused_ui_pause();
                };
        } else if (keyboard_check_pressed(vk_escape)) {
                paused_ui_pause();
        };
        exit;
};

var draw_scale = 0.9 * ui_scale;
for (var i = 0; i < 3; i++) {
        var sprite = button_sprite[i];
        var half_width = max(40 * ui_scale, sprite_get_width(sprite) * draw_scale * 0.7);
        var half_height = max(40 * ui_scale, sprite_get_height(sprite) * draw_scale * 0.7);
        button_hover[i] = point_in_rectangle(mouse_gui_x, mouse_gui_y,
                button_x[i] - half_width, button_y - half_height,
                button_x[i] + half_width, button_y + half_height);
};

if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter)) {
        paused_ui_resume();
        exit;
};
if (keyboard_check_pressed(ord("R"))) {
        paused_ui_retry();
        exit;
};

if (button_pressed) {
        if (button_hover[0]) then paused_ui_back();
        else if (button_hover[1]) then paused_ui_retry();
        else if (button_hover[2]) then paused_ui_resume();
};
