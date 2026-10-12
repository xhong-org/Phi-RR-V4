///@desc 全部 Step 之后锁住非 Hold 音符，避免暂停时继续漂移
if (!variable_global_exists("game") || !is_struct(game)) then exit;

// 暂停时记下第一次坐标并每帧写回。
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
// 恢复后清掉锁定标记。
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
