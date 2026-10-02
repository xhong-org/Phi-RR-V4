///@desc 打击特效渲染初始化
// PhiZone hit effects sit at z 7. DEPTH.HEF (-11000) falls inside invis [8, 16)
// and the chart's lum/grayscale band is only [7, 7.01), so the burst never returns.
depth = (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) ? chart_layer_depth(7) : DEPTH.HEF;
isDraw = true;
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

