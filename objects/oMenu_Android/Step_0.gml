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
                        last_error = "No file selected.";
                        status_text = "Cancelled.";
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
                if (!string_length(last_error)) then last_error = "No file selected.";
                status_text = (pick_status == ANDROID_OPEN_STATUS.CANCELLED) ? "Cancelled." : "Open failed.";
                detail_text = last_error;
                i_android_open_reset();
        } else {
                status_text = "Waiting for system file picker...";
        };
};

var mx = mouse_x;
var my = mouse_y;
hover_open = (mx >= btn_open.x && mx <= btn_open.x + btn_open.w && my >= btn_open.y && my <= btn_open.y + btn_open.h);
hover_sample = (mx >= btn_sample.x && mx <= btn_sample.x + btn_sample.w && my >= btn_sample.y && my <= btn_sample.y + btn_sample.h);

if (picking) then exit;
if (!mouse_check_button_pressed(mb_left)) then exit;

if (hover_open) {
        if (!extension_exists("I_AndroidOpen")) {
                last_error = "I_AndroidOpen is not available in this build.";
                status_text = "Open failed.";
                detail_text = last_error;
        } else if (i_android_open_pick("application/zip")) {
                picking = true;
                last_error = "";
                status_text = "Waiting for system file picker...";
                detail_text = "Select a .zip or .pez chart package.";
        } else {
                last_error = i_android_open_error();
                if (!string_length(last_error)) then last_error = "Failed to open the system picker.";
                status_text = "Open failed.";
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
