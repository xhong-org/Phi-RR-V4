/// @description Android menu interactions (I_AndroidOpen, no get_open_filename)
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        event_user(0);
};

if (picking && extension_exists("I_AndroidOpen")) {
        var pick_status = i_android_open_status();
        if (pick_status == ANDROID_OPEN_STATUS.OK) {
                picking = false;
                var path = i_android_open_path();
                i_android_open_reset();
                if (!string_length(path)) {
                        last_error = lang("menu.noFile");
                        status_text = lang("menu.cancelled");
                        detail_text = last_error;
                } else {
                        pending_path = path;
                        var session = chart_session_ensure();
                        session.source_path = path;
                        session.ready = false;
                        session.error = "";
                        session.status = "Queued";
                        session.detail = path;
                        room_goto(room_loading);
                };
                exit;
        } else if (pick_status == ANDROID_OPEN_STATUS.CANCELLED || pick_status == ANDROID_OPEN_STATUS.ERROR) {
                picking = false;
                last_error = i_android_open_error();
                if (!string_length(last_error)) then last_error = lang("menu.noFile");
                status_text = (pick_status == ANDROID_OPEN_STATUS.CANCELLED) ? lang("menu.cancelled") : lang("menu.openFailed");
                detail_text = last_error;
                i_android_open_reset();
        } else {
                status_text = lang("android.waitingPicker");
        };
};

if (settings_gui_blocking()) {
        hover_open = false;
        hover_sample = false;
        hover_settings = false;
        exit;
};

var mx = mouse_x;
var my = mouse_y;
hover_open = (mx >= btn_open.x && mx <= btn_open.x + btn_open.w && my >= btn_open.y && my <= btn_open.y + btn_open.h);
hover_sample = (mx >= btn_sample.x && mx <= btn_sample.x + btn_sample.w && my >= btn_sample.y && my <= btn_sample.y + btn_sample.h);
hover_settings = settings_menu_button_hit(mx, my);

if (picking) then exit;
if (!mouse_check_button_pressed(mb_left)) then exit;

if (hover_settings) {
        settings_gui_open();
} else if (hover_open) {
        var pick_started = false;
        if (!extension_exists("I_AndroidOpen")) {
                last_error = lang("android.pickerUnavailable");
        } else {
                pick_started = i_android_open_pick("application/zip");
                if (!pick_started) then last_error = i_android_open_error();
        };
        if (pick_started) {
                picking = true;
                last_error = "";
                status_text = lang("android.waitingPicker");
                detail_text = lang("android.pickDetail");
        } else {
                if (!string_length(last_error)) then last_error = lang("android.pickerFailed");
                status_text = lang("menu.openFailed");
                detail_text = last_error;
        };
} else if (hover_sample) {
        var session_sample = chart_session_ensure();
        session_sample.source_path = "__sample__";
        session_sample.ready = false;
        session_sample.error = "";
        session_sample.status = "Queued";
        session_sample.detail = "sample";
        room_goto(room_loading);
};
