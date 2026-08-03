/// @desc Resize-dependent gameplay refresh
//show_debug_message("THIS-CV");

if (!variable_instance_exists(id, "start_width") || !is_real(start_width) || start_width <= 0) {
        start_width = max(1, room_width);
};
if (!variable_instance_exists(id, "start_height") || !is_real(start_height) || start_height <= 0) {
        start_height = max(1, room_height);
};

if (instance_exists(oNote)) {
        with (oNote) {
                event_user(1);
                event_user(2);
                event_user(8);
        };
};

if (instance_exists(oLine)) {
        with (oLine) {
                event_user(2);
        };
};

// Keep scale authoritative on resize callbacks as well.
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
};
