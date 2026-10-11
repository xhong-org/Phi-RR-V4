/// @description Stepwise loading with non-blocking ZIP extraction.
// Resolve the package and illustration first. Expensive default resources wait
// until the black cover has crossed the screen.
if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0
        && variable_global_exists("pls_probe_t0")
        && !(variable_global_exists("pls_probe_exit_sent") && global.pls_probe_exit_sent)
        && (get_timer() - global.pls_probe_t0) >= 240000000) {
        global.pls_probe_exit_sent = true;
        print($"[RPE Probe] loading wall timeout phase={phase} failed={failed}");
        game_end();
        exit;
};
if (variable_global_exists("loading_animation_load_start")
        && !global.loading_animation_load_start && phase == 2) exit;
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
        } else if (chart_path_ext(source_path) == ".zip" || chart_path_ext(source_path) == ".pez") {
                message = lang("loading.unicodeExtract");
                detail = source_path;
                ok = chart_session_zip_begin(source_path);
                if (ok) {
                        phase = 10;
                        phase_timer = 0;
                        exit;
                };
        } else {
                message = lang("loading.scanning");
                detail = source_path;
                ok = chart_session_begin_source(source_path);
        };

        if (!ok) {
                failed = true;
                var session_fail = chart_session_ensure();
                message = lang("loading.failed");
                var fail_detail = string_length(session_fail.error) ? session_fail.error : "Unsupported or invalid chart.";
                detail = string_length(session_fail.error) ? session_fail.error : lang("loading.unsupportedChart");
                chart_session_cleanup(true);
                phase = 99;
                chart_loading_animation_abort();
                if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0) {
                        global.pls_probe_exit_sent = true;
                        print($"[RPE Probe] chart load failed: {detail}");
                        game_end();
                        exit;
                };
                if (!pls_is_gx_remote()) then msgbox_warning_async(fail_detail, "Chart Loader" , [ msgbox_button("OK") ] , MSGBOX_BUTTON_ALIGN.RIGHT);
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

if (phase == 10) {
        var poll_result = chart_session_zip_poll();
        if (poll_result == 0) {
                var unzip_session = chart_session_ensure();
                message = lang("loading.extractingPackage");
                detail = $"{chart_path_file_name(source_path)} -> {unzip_session.extract_dir}";
                exit;
        };
        if (poll_result < 0) {
                failed = true;
                var zip_fail = chart_session_ensure();
                message = lang("loading.failed");
                var zip_detail = string_length(zip_fail.error) ? zip_fail.error : "Failed to extract chart package.";
                detail = string_length(zip_fail.error) ? zip_fail.error : lang("loading.extractFailed");
                chart_session_cleanup(true);
                phase = 99;
                chart_loading_animation_abort();
                if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0) {
                        global.pls_probe_exit_sent = true;
                        print($"[RPE Probe] chart load failed: {detail}");
                        game_end();
                        exit;
                };
                if (!pls_is_gx_remote()) then msgbox_warning_async(zip_detail, "Chart Loader" , [ msgbox_button("OK") ] , MSGBOX_BUTTON_ALIGN.RIGHT);
                pls_return_to_entry(detail);
                exit;
        };

        var zip_session = chart_session_ensure();
        if (!instance_exists(oRPELineTextureAudit)) {
                instance_create_depth(0, 0, 0, oRPELineTextureAudit);
        };
        message = langf("loading.formatDetected", zip_session.format_name);
        detail = zip_session.name + " / " + zip_session.level;
        phase = 2;
        phase_timer = 0;
        exit;
};

if (phase == 2) {
        var session2 = chart_session_ensure();
        chart_session_bind_paths();
        if (variable_global_exists("pls_convert_out") && is_string(global.pls_convert_out) && string_length(global.pls_convert_out)) {
                var convert_dir = global.pls_convert_out;
                global.pls_convert_out = "";
                var convert_ok = phi_convert_package(convert_dir);
                print(convert_ok ? "[ConvertPlay][PASS]" : "[ConvertPlay][FAIL]");
                if (variable_global_exists("pls_convert_only") && global.pls_convert_only) {
                        game_end(convert_ok ? 0 : 1);
                        exit;
                };
        };
        message = lang("loading.preparingRoom");
        detail = session2.format_name + " -> " + string(session2.play_room);
        if (session2.play_room < 0) {
                failed = true;
                message = lang("loading.unsupportedFormat");
                detail = session2.format_name;
                chart_session_fail(detail, true);
                phase = 99;
                chart_loading_animation_abort();
                if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0) {
                        global.pls_probe_exit_sent = true;
                        print($"[RPE Probe] chart load failed: {detail}");
                        game_end();
                        exit;
                };
                pls_return_to_entry(detail);
                exit;
        };
		chart_default_resources_load();
        if (variable_global_exists("pls_archive_test") && global.pls_archive_test
                && !instance_exists(oRPELineTextureAudit)) {
                instance_create_depth(0, 0, 0, oRPELineTextureAudit);
        };
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
        if (instance_exists(oLoadAnimator)) {
                var _animator = instance_find(oLoadAnimator, 0);
                _animator.target_room = session3.play_room;
        };
        // Enter the render room now so its lines and notes can be built under
        // the persistent loading overlay. The overlay decides when to reveal it.
        room_goto(session3.play_room);
};
