/// @description Restore non-Hold note coordinates after all Step events.
if (!variable_global_exists("game") || !is_struct(game)) then exit;

if (game.paused) {
        with (oNote) {
                if (!_is_hold) {
                        if (!variable_instance_exists(id, "_pause_lock_active") || !_pause_lock_active) {
                                _pause_lock_x = x;
                                _pause_lock_y = y;
                                _pause_lock_angle = image_angle;
                                _pause_lock_bad_x = _bad_x;
                                _pause_lock_bad_y = _bad_y;
                                _pause_lock_bad_angle = _bad_angle;
                                _pause_lock_active = true;
                        };
                        x = _pause_lock_x;
                        y = _pause_lock_y;
                        image_angle = _pause_lock_angle;
                        _bad_x = _pause_lock_bad_x;
                        _bad_y = _pause_lock_bad_y;
                        _bad_angle = _pause_lock_bad_angle;
                };
        };
        with (oNote_1) {
                if (!_is_hold) {
                        if (!variable_instance_exists(id, "_pause_lock_active") || !_pause_lock_active) {
                                _pause_lock_x = x;
                                _pause_lock_y = y;
                                _pause_lock_angle = image_angle;
                                _pause_lock_bad_x = _bad_x;
                                _pause_lock_bad_y = _bad_y;
                                _pause_lock_bad_angle = _bad_angle;
                                _pause_lock_active = true;
                        };
                        x = _pause_lock_x;
                        y = _pause_lock_y;
                        image_angle = _pause_lock_angle;
                        _bad_x = _pause_lock_bad_x;
                        _bad_y = _pause_lock_bad_y;
                        _bad_angle = _pause_lock_bad_angle;
                };
        };
        with (oNote_2) {
                if (type != 2) {
                        if (!variable_instance_exists(id, "_pause_lock_active") || !_pause_lock_active) {
                                _pause_lock_x = x;
                                _pause_lock_y = y;
                                _pause_lock_angle = image_angle;
                                _pause_lock_active = true;
                        };
                        x = _pause_lock_x;
                        y = _pause_lock_y;
                        image_angle = _pause_lock_angle;
                };
        };
} else {
        with (oNote) {
                if (variable_instance_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        };
        with (oNote_1) {
                if (variable_instance_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        };
        with (oNote_2) {
                if (variable_instance_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        };
};
