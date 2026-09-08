/// @description Stepwise loading so the UI can refresh between stages
if (done || failed) {
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || mouse_check_button_pressed(mb_left)) {
                if (failed) {
                        chart_loading_animation_abort();
                        pls_return_to_entry();
                };
        };
        exit;
};

phase_timer++;
// Allow one frame for first draw, then process.
if (phase == 0 && phase_timer < 2) {
        message = lang("loading.queued");
        detail = source_path;
        exit;
};

if (phase == 0) {
        message = lang("loading.resolving");
        detail = source_path;
        phase = 1;
        phase_timer = 0;
        exit;
};

if (phase == 1) {
        var ok = false;
        if (source_path == "__sample__") {
                message = lang("loading.sample");
                detail = working_directory + "chart/";
                ok = chart_session_load_sample();
        } else {
                message = lang("loading.extracting");
                detail = source_path;
                ok = chart_session_begin_source(source_path);
        };

        if (!ok) {
                failed = true;
                var session_fail = chart_session_ensure();
                message = lang("loading.failed");
                var fail_detail = string_length(session_fail.error) ? session_fail.error : "Unsupported or invalid chart.";
                detail = string_length(session_fail.error) ? session_fail.error : lang("loading.unsupportedChart");
                // chart_session_fail already cleans extract files/session memory.
                // Ensure cleanup even if older fail path didn't.
                chart_session_cleanup(true);
                phase = 99;
                chart_loading_animation_abort();
                if (!pls_is_gx_remote()) then msgbox_warning_async(fail_detail, "Chart Loader");
                pls_return_to_entry(detail);
                exit;
        };

        var session = chart_session_ensure();
        message = langf("loading.formatDetected", session.format_name);
        detail = session.name + " / " + session.level;
        phase = 2;
        phase_timer = 0;
        exit;
};

if (phase == 2) {
        var session2 = chart_session_ensure();
        chart_session_bind_paths();
        message = lang("loading.preparingRoom");
        detail = session2.format_name + " -> " + string(session2.play_room);
        if (session2.play_room < 0) {
                failed = true;
                message = lang("loading.unsupportedFormat");
                detail = session2.format_name;
                chart_session_fail(detail, true);
                phase = 99;
                chart_loading_animation_abort();
                pls_return_to_entry(detail);
                exit;
        };
		chart_default_resources_load();
        phase = 3;
        phase_timer = 0;
        exit;
};

if (phase == 3) {
		if (!chart_default_resources_ready()) {
			message = lang("loading.defaultResources");
			detail = langf("loading.hitSounds", string_format(chart_default_resources_progress() * 100, 0, 0));
			exit;
		};
        var session3 = chart_session_ensure();
        message = lang("loading.entering");
        detail = session3.name;
        done = true;
        room_goto(session3.play_room);
};
