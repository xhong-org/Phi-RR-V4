/// @description Stepwise loading so the UI can refresh between stages
if (done || failed) {
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || mouse_check_button_pressed(mb_left)) {
                if (failed) then room_goto(room_menu);
        };
        exit;
};

phase_timer++;
// Allow one frame for first draw, then process.
if (phase == 0 && phase_timer < 2) {
        message = "Queued chart package";
        detail = source_path;
        exit;
};

if (phase == 0) {
        message = "Resolving source";
        detail = source_path;
        phase = 1;
        phase_timer = 0;
        exit;
};

if (phase == 1) {
        var ok = false;
        if (source_path == "__sample__") {
                message = "Loading sample chart";
                detail = working_directory + "chart/";
                ok = chart_session_load_sample();
        } else {
                message = "Extracting / scanning package";
                detail = source_path;
                ok = chart_session_begin_source(source_path);
        };

        if (!ok) {
                failed = true;
                var session_fail = chart_session_ensure();
                message = "Load failed";
                detail = string_length(session_fail.error) ? session_fail.error : "Unsupported or invalid chart.";
                // chart_session_fail already cleans extract files/session memory.
                // Ensure cleanup even if older fail path didn't.
                chart_session_cleanup(true);
                msgbox_warning_async(detail, "Chart Loader");
                phase = 99;
                // Return to menu after failure.
                room_goto(room_menu);
                exit;
        };

        var session = chart_session_ensure();
        message = "Format detected: " + session.format_name;
        detail = session.name + " / " + session.level;
        phase = 2;
        phase_timer = 0;
        exit;
};

if (phase == 2) {
        var session2 = chart_session_ensure();
        chart_session_bind_paths();
        message = "Preparing play room";
        detail = session2.format_name + " -> " + string(session2.play_room);
        if (session2.play_room < 0) {
                failed = true;
                message = "Unsupported format";
                detail = session2.format_name;
                chart_session_fail(detail, true);
                phase = 99;
                room_goto(room_menu);
                exit;
        };
		chart_default_resources_load();
        phase = 3;
        phase_timer = 0;
        exit;
};

if (phase == 3) {
		if (!chart_default_resources_ready()) {
			message = "Loading default chart resources";
			detail = "Hit sounds " + string_format(chart_default_resources_progress() * 100, 0, 0) + "%";
			exit;
		};
        var session3 = chart_session_ensure();
        message = "Entering play room";
        detail = session3.name;
        done = true;
        room_goto(session3.play_room);
};
