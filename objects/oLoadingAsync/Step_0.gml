/// @description Stepwise loading with non-blocking ZIP extraction.
if (done || failed) {
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || mouse_check_button_pressed(mb_left)) {
                if (failed) then room_goto(room_menu);
        };
        exit;
};

phase_timer++;
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
        } else if (chart_path_ext(source_path) == ".zip" || chart_path_ext(source_path) == ".pez") {
                message = "Starting Unicode archive extraction";
                detail = source_path;
                ok = chart_session_zip_begin(source_path);
                if (ok) {
                        phase = 10;
                        phase_timer = 0;
                        exit;
                };
        } else {
                message = "Scanning source";
                detail = source_path;
                ok = chart_session_begin_source(source_path);
        };

        if (!ok) {
                failed = true;
                var session_fail = chart_session_ensure();
                message = "Load failed";
                detail = string_length(session_fail.error) ? session_fail.error : "Unsupported or invalid chart.";
                chart_session_cleanup(true);
                MsgBox_Warning(detail, "Chart Loader");
                phase = 99;
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

if (phase == 10) {
        var poll_result = chart_session_zip_poll();
        if (poll_result == 0) {
                message = "Extracting package";
                detail = source_path;
                exit;
        };
        if (poll_result < 0) {
                failed = true;
                var zip_fail = chart_session_ensure();
                message = "Load failed";
                detail = string_length(zip_fail.error) ? zip_fail.error : "Failed to extract chart package.";
                chart_session_cleanup(true);
                MsgBox_Warning(detail, "Chart Loader");
                phase = 99;
                room_goto(room_menu);
                exit;
        };

        var zip_session = chart_session_ensure();
        if (!instance_exists(oRPELineTextureAudit)) {
                instance_create_depth(0, 0, 0, oRPELineTextureAudit);
        };
        message = "Format detected: " + zip_session.format_name;
        detail = zip_session.name + " / " + zip_session.level;
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
