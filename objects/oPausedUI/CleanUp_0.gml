/// @description Free the baked Saira countdown sprites. The font stays cached.
if (variable_instance_exists(id, "countdown_sprites") && is_array(countdown_sprites)) {
    for (var _digit_i = 0; _digit_i < array_length(countdown_sprites); _digit_i++) {
        if (sprite_exists(countdown_sprites[_digit_i])) then sprite_delete(countdown_sprites[_digit_i]);
        countdown_sprites[_digit_i] = -1;
    };
};
