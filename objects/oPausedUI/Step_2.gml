///@desc 全部 Step 之后锁住非 Hold 音符，避免暂停时继续漂移
if (!variable_global_exists("game") || !is_struct(game)) then exit;

// 暂停时记下第一次坐标并每帧写回。
if (game.paused) {
        { var _actors_157 = chart_actor_list(oNote); for (var _actor_i_157 = 0; _actor_i_157 < array_length(_actors_157); _actor_i_157++) with (_actors_157[_actor_i_157]) {
                if (!_is_hold) {
                        if (!chart_actor_var_exists(id, "_pause_lock_active") || !_pause_lock_active) {
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
        } };
        { var _actors_1097 = chart_actor_list(oNote_1); for (var _actor_i_1097 = 0; _actor_i_1097 < array_length(_actors_1097); _actor_i_1097++) with (_actors_1097[_actor_i_1097]) {
                if (!_is_hold) {
                        if (!chart_actor_var_exists(id, "_pause_lock_active") || !_pause_lock_active) {
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
        } };
        { var _actors_2039 = chart_actor_list(oNote_2); for (var _actor_i_2039 = 0; _actor_i_2039 < array_length(_actors_2039); _actor_i_2039++) with (_actors_2039[_actor_i_2039]) {
                if (type != 2) {
                        if (!chart_actor_var_exists(id, "_pause_lock_active") || !_pause_lock_active) {
                                _pause_lock_x = x;
                                _pause_lock_y = y;
                                _pause_lock_angle = image_angle;
                                _pause_lock_active = true;
                        };
                        x = _pause_lock_x;
                        y = _pause_lock_y;
                        image_angle = _pause_lock_angle;
                };
        } };
// 恢复后清掉锁定标记。
} else {
        { var _actors_2652 = chart_actor_list(oNote); for (var _actor_i_2652 = 0; _actor_i_2652 < array_length(_actors_2652); _actor_i_2652++) with (_actors_2652[_actor_i_2652]) {
                if (chart_actor_var_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        } };
        { var _actors_2791 = chart_actor_list(oNote_1); for (var _actor_i_2791 = 0; _actor_i_2791 < array_length(_actors_2791); _actor_i_2791++) with (_actors_2791[_actor_i_2791]) {
                if (chart_actor_var_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        } };
        { var _actors_2932 = chart_actor_list(oNote_2); for (var _actor_i_2932 = 0; _actor_i_2932 < array_length(_actors_2932); _actor_i_2932++) with (_actors_2932[_actor_i_2932]) {
                if (chart_actor_var_exists(id, "_pause_lock_active")) then _pause_lock_active = false;
        } };
};
