///@desc 绘制：就地画还活着的打击特效，不另建绘制列表
if(!isDraw) then exit;

var realT = (game.__time[1]);
var pack = skin_active() ? skin_runtime() : undefined;
var skin_on = is_struct(pack);
var hide_particles = skin_on && bool(pack.info.hideParticles);

// 按原顺序绘制，过期项就地删掉。
for(var i = 0 ; i < array_length(effect_events) ; i ++){
	var effect_event = (effect_events[i]),
		age = (realT - effect_event.time);
	var max_age = 1;
	if (skin_on) then max_age = max(hide_particles ? 0.05 : 1, real(pack.info.hitFxDuration));

	// 超过寿命就删掉并回退下标，避免跳过下一项。
	if(age > max_age){
		array_delete(effect_events , i , 1);
		i --;
		continue;
	};

	// 有皮肤时走皮肤打击图，可选择不画粒子。
	if (skin_on) {
		var fx_col = skin_hitfx_color(pack, effect_event.col);
		skin_draw_hitfx(pack, effect_event.x, effect_event.y, age, fx_col, skin_hitfx_game_scale(pack));
		if (!hide_particles) {
			skin_draw_preview_particles(effect_event.x, effect_event.y, age, fx_col, global_scales,
				effect_event.rot, effect_event.scales, effect_event.rx, effect_event.ry);
		};
		continue;
	};

	var subimage = (clamp(age * 60 , 0 , 30)),
		progress = (clamp(age , 0 , 1));

	draw_sprite_ext(effect , subimage , effect_event.x , effect_event.y , global_scales , global_scales , 0 , effect_event.col , subimage < 30);

	// 四颗粒子沿随机方向飞出，距离和缩放是进度的拟合曲线。
	for(var port = 0 ; port < 4 ; port ++){
		var dist = (((850.3997391752 * progress + 6236.3848902154) * progress + 80.3542231806) * progress)
			/ ((6570.5817658876 * progress + 495.7977913926) * progress + 1.0),
			dx = (dist * dcos(effect_event.rot[port])),
			dy = (dist * dsin(effect_event.rot[port])),
			size_t = (progress >= 0.25 ? (0.25 - progress * 0.29999) : progress),
			draw_scale = (((0.20783014 * size_t - 1.65243926) * size_t + 1.6398785) * size_t + 0.49884492),
			particle_scale = (effect_event.scales[port] * global_scales * draw_scale);

		draw_sprite_ext(
			spr_pixel_1,
			0,
			effect_event.x + dx * effect_event.rx * global_scales,
			effect_event.y + dy * effect_event.ry * global_scales,
			particle_scale,
			particle_scale,
			0,
			effect_event.col,
			(30 - subimage) / 30
		);
	};
};
