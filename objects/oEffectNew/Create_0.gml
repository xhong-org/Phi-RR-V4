///@desc 打击特效渲染初始化
depth = DEPTH.HEF;
globalvar eff_create;
effect_events = [];
eff_create = (function(xx , yy , color , time = undefined){
	if(!game.settings.enableHitEffect) then return(false);
	with(oEffectNew){
		var rot = [],
			scales = [];
		repeat(4){
			array_add(rot , (random_range(0 , 360)));
			array_add(scales , (random_range(17 , 19)));
		};
		
		array_add(
			effect_events,
			{
				"x" : xx,
				"y" : yy,
				"rot" : rot,
				"time" : (is_undefined(time) ? game.__time[1] : time),
				"col" : color,
				"rx" : random_range(225 , 350),
				"ry" : random_range(225 , 350),
				"scales" : scales
			}
		);
	};
});

