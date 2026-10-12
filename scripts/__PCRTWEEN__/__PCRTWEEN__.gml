/* began */

// 谱面事件使用的缓动类型
enum EASE_TYPE {
	IDK,
	LINEAR,
	SINE_IN, SINE_OUT, SINE_IN_OUT,
	QUAD_IN, QUAD_OUT, QUAD_IN_OUT,
	CUBIC_IN, CUBIC_OUT, CUBIC_IN_OUT,
	QUART_IN, QUART_OUT, QUART_IN_OUT,
	QUINT_IN, QUINT_OUT, QUINT_IN_OUT,
	EXPO_IN, EXPO_OUT, EXPO_IN_OUT,
	CIRC_IN, CIRC_OUT, CIRC_IN_OUT,
	BACK_IN, BACK_OUT, BACK_IN_OUT,
	ELASTIC_IN, ELASTIC_OUT, ELASTIC_IN_OUT,
	BOUNCE_IN, BOUNCE_OUT, BOUNCE_IN_OUT,
	BEZIER,
	__SIZE__
};

///@desc 生成各缓动类型的预采样表
///@returns {Array} 下标对应缓动类型，每项为采样或空
function __PCRTWEEN__() {
	///@desc 线性缓动，原样返回进度
	///@returns {Real} 输入进度
	static _linear = (function() { return(argument0); });
	
	///@desc 用四段抛物线做弹跳缓出
	///@returns {Real} 缓动值
	static _bounce_out = (function() {
		// 时间越靠后，抛物线段越短
		if (argument0 < 1 / 2.75) {
			return(7.5625 * argument0 * argument0);
		} elif (argument0 < 2 / 2.75) {
			var _t = (argument0 - 1.5 / 2.75);
			return(7.5625 * _t * _t + 0.75);
		} elif (argument0 < 2.5 / 2.75) {
			var _t = (argument0 - 2.25 / 2.75);
			return(7.5625 * _t * _t + 0.9375);
		} else {
			var _t = (argument0 - 2.625 / 2.75);
			return(7.5625 * _t * _t + 0.984375);
		};
    }); // EASE_TYPE.BOUNCE_OUT (n1=7.5625, d1=2.75)
	
	// 缓动数组
	static _easings = [
		_linear, _linear, // EASE_TYPE.IDK (0), EASE_TYPE.LINEAR (1)
		
		///@desc 正弦缓入
		///@returns {Real} 缓动值
		(function() { return(1 - (cos(pi * 0.5 * argument0))); }), // EASE_TYPE.SINE_IN (2)
		///@desc 正弦缓出
		///@returns {Real} 缓动值
		(function() { return(sin(pi * 0.5 * argument0)); }), // EASE_TYPE.SINE_OUT (3)
		///@desc 正弦缓入缓出
		///@returns {Real} 缓动值
		(function() { return(-0.5 * ((cos(pi * argument0)) - 1)); }), // EASE_TYPE.SINE_IN_OUT (4)
		
		///@desc 二次缓入
		///@returns {Real} 缓动值
		(function() { return(argument0 * argument0); }), // EASE_TYPE.QUAD_IN (5)
		///@desc 二次缓出
		///@returns {Real} 缓动值
		(function() { var _t = (1 - argument0); return(1 - _t * _t); }), // EASE_TYPE.QUAD_OUT (6)
		// 前半加速，后半反向收束
		///@desc 二次缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 < 0.5) then return(2 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t) * 0.5); }), // EASE_TYPE.QUAD_IN_OUT (7)
		
		///@desc 三次缓入
		///@returns {Real} 缓动值
		(function() { return(argument0 * argument0 * argument0); }), // EASE_TYPE.CUBIC_IN (8)
		///@desc 三次缓出
		///@returns {Real} 缓动值
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t); }), // EASE_TYPE.CUBIC_OUT (9)
		// 以一半为界切换两次三次曲线
		///@desc 三次缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 < 0.5) then return(4 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t) * 0.5); }), // EASE_TYPE.CUBIC_IN_OUT (10)
		
		///@desc 四次缓入
		///@returns {Real} 缓动值
		(function() { return(argument0 * argument0 * argument0 * argument0); }), // EASE_TYPE.QUART_IN (11)
		///@desc 四次缓出
		///@returns {Real} 缓动值
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t * _t); }), // EASE_TYPE.QUART_OUT (12)
		// 以一半为界切换两次四次曲线
		///@desc 四次缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 < 0.5) then return(8 * argument0 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t * _t) * 0.5); }), // EASE_TYPE.QUART_IN_OUT (13)
		
		///@desc 五次缓入
		///@returns {Real} 缓动值
		(function() { return(argument0 * argument0 * argument0 * argument0 * argument0); }), // EASE_TYPE.QUINT_IN (14)
		///@desc 五次缓出
		///@returns {Real} 缓动值
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t * _t * _t); }), // EASE_TYPE.QUINT_OUT (15)
		// 以一半为界切换两次五次曲线
		///@desc 五次缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 < 0.5) then return(16 * argument0 * argument0 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t * _t * _t) * 0.5); }), // EASE_TYPE.QUINT_IN_OUT (16)
		
		// 起点固定为 0，其余按指数上升
		///@desc 指数缓入
		///@returns {Real} 缓动值
		(function() { return((argument0 == 0) ? (0) : (power(2, (10 * (argument0 - 1))))); }), // EASE_TYPE.EXPO_IN (17)
		// 终点固定为 1，其余按指数靠近
		///@desc 指数缓出
		///@returns {Real} 缓动值
		(function() { return((argument0 == 1) ? (1) : (1 - (power(2, (-10 * argument0))))); }), // EASE_TYPE.EXPO_OUT (18)
		// 两端取极值，中间对半切换指数
		///@desc 指数缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); if (argument0 < 0.5) then return((power(2, (20 * argument0 - 10))) * 0.5); return((2 - (power(2, (-20 * argument0 + 10)))) * 0.5); }), // EASE_TYPE.EXPO_IN_OUT (19)
		
		///@desc 圆形缓入
		///@returns {Real} 缓动值
		(function() { return(1 - (sqrt(1 - (argument0 * argument0)))); }), // EASE_TYPE.CIRC_IN (20)
		///@desc 圆形缓出
		///@returns {Real} 缓动值
		(function() { var _t = (argument0 - 1); return(sqrt(1 - (_t * _t))); }), // EASE_TYPE.CIRC_OUT (21)
		// 以一半为界拼两段圆弧
		///@desc 圆形缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 < 0.5) then return((1 - (sqrt(1 - 4 * argument0 * argument0))) * 0.5); var _t = (-2 * argument0 + 2); return(((sqrt(1 - _t * _t)) + 1) * 0.5);  }), // EASE_TYPE.CIRC_IN_OUT (22)
		
		///@desc 回退缓入
		///@returns {Real} 缓动值
		(function() { return(argument0 * argument0 * (2.70158 * argument0 - 1.70158)); }), // EASE_TYPE.BACK_IN (23) (c1=1.70158, c3(=2.70158)=c1+1)
		///@desc 回退缓出
		///@returns {Real} 缓动值
		(function() { var _t = (argument0 - 1); return(_t * _t * (2.70158 * _t + 1.70158) + 1); }),  // EASE_TYPE.BACK_OUT (24) (c1=1.70158, c3(=2.70158)=c1+1)
		// 前后半段各自做一次回退
		///@desc 回退缓入缓出
		///@returns {Real} 缓动值
        (function() { if (argument0 < 0.5) { var _t = (2 * argument0); return((_t * _t * (3.5949095 * _t - 2.5949095)) * 0.5); } else { var _t = (2 * argument0 - 2); return((_t * _t * (3.5949095 * _t + 2.5949095)) * 0.5 + 1); }; }), // EASE_TYPE.BACK_IN_OUT (25) (c1=1.70158, c2(=2.5949095)=c1*1.525, 3.5949095=2.5949095+1)
		
		// 两端取极值，中间为衰减正弦
		///@desc 弹性缓入
		///@returns {Real} 缓动值
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); return((power(2, (10 * argument0 - 10))) * -1 * (sin((argument0 * 20 - 21.5) * pi / 3))); }), // EASE_TYPE.ELASTIC_IN (26) (c4=2*pi/3, argument0*20-21.5=(argument0*10-10.75)*2)
		// 两端取极值，靠近终点时振荡
		///@desc 弹性缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); return((power(2, (-10 * argument0))) * (sin((argument0 * 20 - 1.5) * pi / 3)) + 1); }), // EASE_TYPE.ELASTIC_OUT (27) (c4=2*pi/3, argument0*20-1.5=(argument0*10-0.75)*2)
		// 前半为缓入，后半为缓出
		///@desc 弹性缓入缓出
		///@returns {Real} 缓动值
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); if (argument0 < 0.5) then return(-0.5 * ((power(2, (20 * argument0 - 10))) * (sin((40 * argument0 - 22.25) * pi / 4.5)))); return(0.5 * ((power(2, (-20 * argument0 + 10))) * (sin((40 * argument0 - 22.25) * pi / 4.5))) + 1); }), // EASE_TYPE.ELASTIC_OUT (28) (c5=2*pi/4.5, 40*argument0-22.25=(20*argument0-11.125)*2)
		
		///@desc 弹跳缓入，由缓出镜像得到
		///@returns {Real} 缓动值
		(method({ _bounce_out }, (function() { return(1 - (_bounce_out(1 - argument0))) }))), // EASE_TYPE.BOUNCE_IN (29) (n1=7.5625, d1=2.75)
		_bounce_out, // EASE_TYPE.BOUNCE_OUT (30) (n1=7.5625, d1=2.75)
		// 前半镜像缓出，后半直接缓出
		///@desc 弹跳缓入缓出
		///@returns {Real} 缓动值
		(method({ _bounce_out }, (function() { if (argument0 < 0.5) then return(0.5 - 0.5 * (_bounce_out(1 - 2 * argument0))); return(0.5 + 0.5 * (_bounce_out(2 * argument0 - 1))); }))), // EASE_TYPE.BOUNCE_IN_OUT (31) (n1=7.5625, d1=2.75, 0.5-0.5*(_bounce_out(1-2*argument0))=(1-(_bounce_out(1-2*argument0)))*0.5, 0.5+0.5*(_bounce_out(2*argument0-1))=(1+(_bounce_out(2*argument0-1)))*0.5)
		
		_linear, _linear // EASE_TYPE.BEZIER (32), EASE_TYPE.__SIZE__ (33)
	];
	
	// 实际用的
	///@desc 把缓动函数预采样成一百零一个点
	///@param {Any} _e 缓动函数
	///@param {Real} _i 缓动类型下标
	///@returns {Any} 采样数组；线性或贝塞尔段为空
	static _ = (array_map(_easings, (function(_e, _i) {
		// 线性端点和贝塞尔没有曲线表
		if ((_i <= EASE_TYPE.LINEAR) || (_i >= EASE_TYPE.BEZIER)) then return(undefined);
		var _r = (array_create(101));
		var _j = 0; repeat(101) {
			_r[@ _j] = (_e(_j * 0.01));
		_j ++; };
		return(_r);
	})));
	
	// 文本。
	return(_);
};

/* ended */