///@desc ????????? Z ????????????? Z ? 7
if (!variable_instance_exists(id, "hit_effect_layer_z")) then hit_effect_layer_z = 7;
depth = (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) ? chart_layer_depth(hit_effect_layer_z) : DEPTH.HEF;
isDraw = true;
globalvar eff_create;
effect_events = [];
eff_create = (
///@desc 登记一次打击特效
///@param {Real} xx 世界坐标 x
///@param {Real} yy 世界坐标 y
///@param {Real} color 颜色
///@param {Real} time 触发时间，缺省用当前谱面时间
///@returns {Bool} 关闭特效时返回 false，成功入队时无返回值
function(xx , yy , color , time = undefined, z = undefined){
	// 设置关掉打击特效就不再入队。
	if(!game.settings.enableHitEffect) then return(false);
	var renderer = chart_hit_effect_renderer(oEffectNew, z);
	with(renderer){
		var rot = [],
			scales = [];
		// 四颗粒子各自随机朝向和尺寸。
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

