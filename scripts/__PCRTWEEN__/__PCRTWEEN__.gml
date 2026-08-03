/* began */

//
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

///
function __PCRTWEEN__() {
	/// 线性缓动（无缓动）
	static _linear = (function() { return(argument0); });
	
	/// EASE_TYPE.BOUNCE_OUT
	static _bounce_out = (function() {
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
		
		(function() { return(1 - (cos(pi * 0.5 * argument0))); }), // EASE_TYPE.SINE_IN (2)
		(function() { return(sin(pi * 0.5 * argument0)); }), // EASE_TYPE.SINE_OUT (3)
		(function() { return(-0.5 * ((cos(pi * argument0)) - 1)); }), // EASE_TYPE.SINE_IN_OUT (4)
		
		(function() { return(argument0 * argument0); }), // EASE_TYPE.QUAD_IN (5)
		(function() { var _t = (1 - argument0); return(1 - _t * _t); }), // EASE_TYPE.QUAD_OUT (6)
		(function() { if (argument0 < 0.5) then return(2 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t) * 0.5); }), // EASE_TYPE.QUAD_IN_OUT (7)
		
		(function() { return(argument0 * argument0 * argument0); }), // EASE_TYPE.CUBIC_IN (8)
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t); }), // EASE_TYPE.CUBIC_OUT (9)
		(function() { if (argument0 < 0.5) then return(4 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t) * 0.5); }), // EASE_TYPE.CUBIC_IN_OUT (10)
		
		(function() { return(argument0 * argument0 * argument0 * argument0); }), // EASE_TYPE.QUART_IN (11)
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t * _t); }), // EASE_TYPE.QUART_OUT (12)
		(function() { if (argument0 < 0.5) then return(8 * argument0 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t * _t) * 0.5); }), // EASE_TYPE.QUART_IN_OUT (13)
		
		(function() { return(argument0 * argument0 * argument0 * argument0 * argument0); }), // EASE_TYPE.QUINT_IN (14)
		(function() { var _t = (1 - argument0); return(1 - _t * _t * _t * _t * _t); }), // EASE_TYPE.QUINT_OUT (15)
		(function() { if (argument0 < 0.5) then return(16 * argument0 * argument0 * argument0 * argument0 * argument0); var _t = (-2 * argument0 + 2); return(1 - (_t * _t * _t * _t * _t) * 0.5); }), // EASE_TYPE.QUINT_IN_OUT (16)
		
		(function() { return((argument0 == 0) ? (0) : (power(2, (10 * (argument0 - 1))))); }), // EASE_TYPE.EXPO_IN (17)
		(function() { return((argument0 == 1) ? (1) : (1 - (power(2, (-10 * argument0))))); }), // EASE_TYPE.EXPO_OUT (18)
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); if (argument0 < 0.5) then return((power(2, (20 * argument0 - 10))) * 0.5); return((2 - (power(2, (-20 * argument0 + 10)))) * 0.5); }), // EASE_TYPE.EXPO_IN_OUT (19)
		
		(function() { return(1 - (sqrt(1 - (argument0 * argument0)))); }), // EASE_TYPE.CIRC_IN (20)
		(function() { var _t = (argument0 - 1); return(sqrt(1 - (_t * _t))); }), // EASE_TYPE.CIRC_OUT (21)
		(function() { if (argument0 < 0.5) then return((1 - (sqrt(1 - 4 * argument0 * argument0))) * 0.5); var _t = (-2 * argument0 + 2); return(((sqrt(1 - _t * _t)) + 1) * 0.5);  }), // EASE_TYPE.CIRC_IN_OUT (22)
		
		(function() { return(argument0 * argument0 * (2.70158 * argument0 - 1.70158)); }), // EASE_TYPE.BACK_IN (23) (c1=1.70158, c3(=2.70158)=c1+1)
		(function() { var _t = (argument0 - 1); return(_t * _t * (2.70158 * _t + 1.70158) + 1); }),  // EASE_TYPE.BACK_OUT (24) (c1=1.70158, c3(=2.70158)=c1+1)
        (function() { if (argument0 < 0.5) { var _t = (2 * argument0); return((_t * _t * (3.5949095 * _t - 2.5949095)) * 0.5); } else { var _t = (2 * argument0 - 2); return((_t * _t * (3.5949095 * _t + 2.5949095)) * 0.5 + 1); }; }), // EASE_TYPE.BACK_IN_OUT (25) (c1=1.70158, c2(=2.5949095)=c1*1.525, 3.5949095=2.5949095+1)
		
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); return((power(2, (10 * argument0 - 10))) * -1 * (sin((argument0 * 20 - 21.5) * pi / 3))); }), // EASE_TYPE.ELASTIC_IN (26) (c4=2*pi/3, argument0*20-21.5=(argument0*10-10.75)*2)
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); return((power(2, (-10 * argument0))) * (sin((argument0 * 20 - 1.5) * pi / 3)) + 1); }), // EASE_TYPE.ELASTIC_OUT (27) (c4=2*pi/3, argument0*20-1.5=(argument0*10-0.75)*2)
		(function() { if (argument0 == 0) then return(0); if (argument0 == 1) then return(1); if (argument0 < 0.5) then return(-0.5 * ((power(2, (20 * argument0 - 10))) * (sin((40 * argument0 - 22.25) * pi / 4.5)))); return(0.5 * ((power(2, (-20 * argument0 + 10))) * (sin((40 * argument0 - 22.25) * pi / 4.5))) + 1); }), // EASE_TYPE.ELASTIC_OUT (28) (c5=2*pi/4.5, 40*argument0-22.25=(20*argument0-11.125)*2)
		
		(method({ _bounce_out }, (function() { return(1 - (_bounce_out(1 - argument0))) }))), // EASE_TYPE.BOUNCE_IN (29) (n1=7.5625, d1=2.75)
		_bounce_out, // EASE_TYPE.BOUNCE_OUT (30) (n1=7.5625, d1=2.75)
		(method({ _bounce_out }, (function() { if (argument0 < 0.5) then return(0.5 - 0.5 * (_bounce_out(1 - 2 * argument0))); return(0.5 + 0.5 * (_bounce_out(2 * argument0 - 1))); }))), // EASE_TYPE.BOUNCE_IN_OUT (31) (n1=7.5625, d1=2.75, 0.5-0.5*(_bounce_out(1-2*argument0))=(1-(_bounce_out(1-2*argument0)))*0.5, 0.5+0.5*(_bounce_out(2*argument0-1))=(1+(_bounce_out(2*argument0-1)))*0.5)
		
		_linear, _linear // EASE_TYPE.BEZIER (32), EASE_TYPE.__SIZE__ (33)
	];
	
	// 实际用的
	static _ = (array_map(_easings, (function(_e, _i) {
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