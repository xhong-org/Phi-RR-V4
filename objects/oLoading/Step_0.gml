///@desc 步进：分阶段加载，让界面能在阶段之间刷新
// 结束或失败后只等按键返回。
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
// 先留一帧给出画面，再开始处理。
if (phase == 0 && phase_timer < 2) {
        message = lang("loading.queued");
        detail = source_path;
        exit;
};

// 阶段 0：进入解析。
if (phase == 0) {
        message = lang("loading.resolving");
        detail = source_path;
        phase = 1;
        phase_timer = 0;
        exit;
};

// 阶段 1：示例谱或解压来源。
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

        // 解析失败就清理并退回入口。
        if (!ok) {
                failed = true;
                var session_fail = chart_session_ensure();
                message = lang("loading.failed");
                var fail_detail = string_length(session_fail.error) ? session_fail.error : "Unsupported or invalid chart.";
                detail = string_length(session_fail.error) ? session_fail.error : lang("loading.unsupportedChart");
                // chart_session_fail 已经清理解压文件和会话内存。
                // 旧失败路径没清时这里再保一次。
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

// 阶段 2：绑定路径并确认目标房间。
if (phase == 2) {
        var session2 = chart_session_ensure();
        chart_session_bind_paths();
        message = lang("loading.preparingRoom");
        detail = session2.format_name + " -> " + string(session2.play_room);
        // 没有可进入的房间。
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

// 阶段 3：默认资源就绪后进入游玩房间。
if (phase == 3) {
		// 打击音等默认资源还在加载就留在这一阶段。
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
