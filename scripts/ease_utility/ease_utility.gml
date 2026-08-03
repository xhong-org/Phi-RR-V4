// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

/* 保证此段代码仅被执行一次 */
if (variable_global_get(_GMFILE_)) then return;
else variable_global_set(_GMFILE_, true);
/* 正文 */

// Ease常量
enum EASE {
	NULL, // Nothing
	LINEAR, // Linear
	SINE_IN, // InSine
	SINE_OUT, // OutSine
	SINE_IN_OUT, // InOutSine
	QUAD_IN, // InQuad
	QUAD_OUT, // OutQuad
	QUAD_IN_OUT, // InOutQuad
	CUBIC_IN, // InCubic
	CUBIC_OUT, // OutCubic
	CUBIC_IN_OUT, // InOutCubic
	QUART_IN, // InQuart
	QUART_OUT, // OutQuart
	QUART_IN_OUT, // InOutQuart
	QUINT_IN, // InQuint
	QUINT_OUT, // OutQuint
	QUINT_IN_OUT, // InOutQuint
	EXPO_IN, // InExpo
	EXPO_OUT, // OutExpo
	EXPO_IN_OUT, // InOutExpo
	CIRC_IN, // InCirc
	CIRC_OUT, // OutCirc
	CITC_IN_OUT, // InOutCirc
	BACK_IN, // InBack
	BACK_OUT, // OutBack
	BACK_IN_OUT, // InOutBack
	ELASTIC_IN, // InElastic
	ELASTIC_OUT, // OutElastic
	ELASTIC_IN_OUT, // InOutElastic
	BOUNCE_IN, // InBounce
	BOUNCE_OUT, // OutBounce
	BOUNCE_IN_OUT, // InOutBounce
	// CUBIC_BEZIER = 128
};

// Ease Utility
/// @desc 缓动函数, 自定义参数随时间变化的速率.
globalvar Easings;
Easings = (new(function() constructor {
	/* 核心::Ease函数 */
	// Linear 线性 无缓动效果
	/// @desc          Linear
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static Linear = (function(_posx) {
		// static _channel = ((animcurve_get_channel(BezierLibary, "Linear")));
		// return(animcurve_channel_evaluate(_channel, _posx));
		return ((_posx));
	});
	// Sinusoidal 正弦渐变 正弦曲线的缓动(sin(t))
	/// @desc          Sine.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InSine = (function(_posx) {
		// return (((-cos(((_posx * pi) / 2))) + 1));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Sine.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutSine = (function(_posx) {
		// return (((-0.5) * (cos((_posx * pi)) - 1)));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Sine.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutSine = (function(_posx) {
		// return ((sin(((_posx * pi) / 2))));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Quadratic 二次渐变 二次方的缓动(t^2)
	/// @desc          Quad.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InQuad = (function(_posx) {
		// return ((_posx * _posx));
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quad.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutQuad = (function(_posx) {
		/* _posx *= (2);
		if (_posx < 1) then return (((0.5 * _posx) * _posx));
		_posx -= (1);
		return (((-0.5) * ((_posx * (_posx - 2)) - 1))); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quad.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutQuad = (function(_posx) {
		// return (((-_posx) * (_posx - 2)));
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Cubic 三次方 三次方的缓动(t^3)
	/// @desc          Cubic.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Cubic.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Cubic.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Quartic 四次方 四次方的缓动(t^4)
	/// @desc          Quart.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quart.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quart.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Quintic 五次方 五次方的缓动(t^5)
	/// @desc          Quint.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InQuint = (function(_posx) {
		// return (((((_posx * _posx) * _posx) * _posx) * _posx));
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quint.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutQuint = (function(_posx) {
		/* _posx *= (2);
		if (_posx < 1) then return ((((((0.5 * _posx) * _posx) * _posx) * _posx) * _posx));
		_posx -= (2);
		return ((0.5 * (((((_posx * _posx) * _posx) * _posx) * _posx) + 2))); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Quint.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutQuint = (function(_posx) {
		/* _posx -= (1);
		return ((((((_posx * _posx) * _posx) * _posx) * _posx) + 1)); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Exponential 指数渐变 指数曲线的缓动(2^t)
	/// @desc          Expo.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InExpo = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Expo.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutExpo = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Expo.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutExpo = function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	};
	// Circular 圆形曲线 圆形曲线的缓动(sqrt(1-t^2))
	/// @desc          Circ.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Circ.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Circ.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Back 超过范围的三次方缓动((s+1)t^3-st^2)
	/// @desc          Back.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Back.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Back.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Elastic 指数衰减正弦曲线 指数衰减的正弦曲线缓动
	/// @desc          Elastic.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Elastic.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Elastic.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// Bounce 指数衰减的反弹缓动
	/// @desc          Bounce.In
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Bounce.In-Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static InOutBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc          Bounce.Out
	/// @arg    {Real} posx 及时检查位置(从0到1)
	/// @return {Real}
	static OutBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	/// @desc 错误
	static Error = (function() {
		return(NaN);
	});
	
	/* 核心::函数 */
	/// @desc 缓动列表
	static List = [ Error, Linear, InSine, OutSine, InOutSine, InQuad, OutQuad, InOutQuad, InCubic, OutCubic, InOutCubic, InQuart, OutQuart, InOutQuart, InQuint, OutQuint, InOutQuint, InExpo, OutExpo, InOutExpo, InCirc, OutCirc, InOutCirc, InBack, OutBack, InOutBack, InElastic, OutElastic, InOutElastic, InBounce, OutBounce, InOutBounce ];
	
	print($"Len: {array_length(List)} | 24Ease: {List[min(24 , array_length(List))]}");
	
	/// @desc                       检测是否为有效缓动
	/// @arg    {Constant.EaseType} easeType
	/// @return {Bool}
	static Exists = (method(self, (function(_ease_type) {
		return(bool((_ease_type >= 0) || (_ease_type < (array_length(List)))));
	})));
	
	/// @desc                       寻址
	/// @arg    {Constant.EaseType} easeType
	/// @return {Function.Ease}
	static Address = (method(self, (function(_ease_type) {
		// 返回寻址结果
		if (!Exists(_ease_type)) then return(Error);
		return(array_get(List, _ease_type));
	})));
})());
