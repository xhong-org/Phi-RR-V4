// v2.3.0 的脚本资产已更改，更多说明见
// https://help.yoyogames.com/hc/en-us/articles/360005277377

/* 保证此段代码仅被执行一次 */
if (variable_global_get(_GMFILE_)) then return;
else variable_global_set(_GMFILE_, true);
/* 正文 */

// Ease常量
enum EASE {
	NULL, // 无
	LINEAR, // 线性
	SINE_IN, // 正弦缓入
	SINE_OUT, // 正弦缓出
	SINE_IN_OUT, // 正弦缓入缓出
	QUAD_IN, // 二次缓入
	QUAD_OUT, // 二次缓出
	QUAD_IN_OUT, // 二次缓入缓出
	CUBIC_IN, // 三次缓入
	CUBIC_OUT, // 三次缓出
	CUBIC_IN_OUT, // 三次缓入缓出
	QUART_IN, // 四次缓入
	QUART_OUT, // 四次缓出
	QUART_IN_OUT, // 四次缓入缓出
	QUINT_IN, // 五次缓入
	QUINT_OUT, // 五次缓出
	QUINT_IN_OUT, // 五次缓入缓出
	EXPO_IN, // 指数缓入
	EXPO_OUT, // 指数缓出
	EXPO_IN_OUT, // 指数缓入缓出
	CIRC_IN, // 圆形缓入
	CIRC_OUT, // 圆形缓出
	CITC_IN_OUT, // 圆形缓入缓出
	BACK_IN, // 回退缓入
	BACK_OUT, // 回退缓出
	BACK_IN_OUT, // 回退缓入缓出
	ELASTIC_IN, // 弹性缓入
	ELASTIC_OUT, // 弹性缓出
	ELASTIC_IN_OUT, // 弹性缓入缓出
	BOUNCE_IN, // 弹跳缓入
	BOUNCE_OUT, // 弹跳缓出
	BOUNCE_IN_OUT, // 弹跳缓入缓出
	// CUBIC_BEZIER = 128
};

// 缓动工具，自定义数值随时间变化的速率
globalvar Easings;
///@desc 构造缓动函数表
///@returns {Struct} 缓动工具实例
Easings = (new(function() constructor {
	/* 核心：缓动函数 */
	// 线性，无缓动
	///@desc 线性缓动，进度保持不变
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static Linear = (function(_posx) {
		// static _channel = ((animcurve_get_channel(BezierLibary, "Linear")));
		// return(animcurve_channel_evaluate(_channel, _posx));
		return ((_posx));
	});
	// 正弦渐变，按正弦曲线缓动
	///@desc 正弦缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InSine = (function(_posx) {
		// return (((-cos(((_posx * pi) / 2))) + 1));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 正弦缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutSine = (function(_posx) {
		// return (((-0.5) * (cos((_posx * pi)) - 1)));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 正弦缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutSine = (function(_posx) {
		// return ((sin(((_posx * pi) / 2))));
		static _channel = ((animcurve_get_channel(ac_easings, "Sine.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 二次渐变，按二次方缓动
	///@desc 二次缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InQuad = (function(_posx) {
		// return ((_posx * _posx));
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 二次缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutQuad = (function(_posx) {
		/* _posx *= (2);
		if (_posx < 1) then return (((0.5 * _posx) * _posx));
		_posx -= (1);
		return (((-0.5) * ((_posx * (_posx - 2)) - 1))); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 二次缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutQuad = (function(_posx) {
		// return (((-_posx) * (_posx - 2)));
		static _channel = ((animcurve_get_channel(ac_easings, "Quad.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 三次方缓动
	///@desc 三次缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 三次缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 三次缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutCubic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Cubic.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 四次方缓动
	///@desc 四次缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 四次缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 四次缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutQuart = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Quart.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 五次方缓动
	///@desc 五次缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InQuint = (function(_posx) {
		// return (((((_posx * _posx) * _posx) * _posx) * _posx));
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 五次缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutQuint = (function(_posx) {
		/* _posx *= (2);
		if (_posx < 1) then return ((((((0.5 * _posx) * _posx) * _posx) * _posx) * _posx));
		_posx -= (2);
		return ((0.5 * (((((_posx * _posx) * _posx) * _posx) * _posx) + 2))); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 五次缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutQuint = (function(_posx) {
		/* _posx -= (1);
		return ((((((_posx * _posx) * _posx) * _posx) * _posx) + 1)); */
		static _channel = ((animcurve_get_channel(ac_easings, "Quint.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 指数渐变，按指数曲线缓动
	///@desc 指数缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InExpo = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 指数缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutExpo = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 指数缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutExpo = function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Expo.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	};
	// 圆形曲线缓动
	///@desc 圆形缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 圆形缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 圆形缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutCirc = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Circ.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 回退，会略微超出起止范围
	///@desc 回退缓入，开始时略微反向
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 回退缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 回退缓出，结束时略微越过终点
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutBack = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Back.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 弹性，指数衰减的正弦曲线
	///@desc 弹性缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 弹性缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 弹性缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutElastic = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Elastic.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	// 弹跳，逐段衰减的反弹
	///@desc 弹跳缓入
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.In")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 弹跳缓入缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static InOutBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.In-Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 弹跳缓出
	///@param {Real} _posx 归一化时间，范围 0 到 1
	///@returns {Real} 缓动后的进度
	static OutBounce = (function(_posx) {
		static _channel = ((animcurve_get_channel(BezierLibary, "Bounce.Out")));
		return(animcurve_channel_evaluate(_channel, _posx));
	});
	///@desc 无效缓动时返回非数
	///@returns {Real} 非数
	static Error = (function() {
		return(NaN);
	});
	
	/* 核心::函数 */
	/// @desc 缓动列表
	static List = [ Error, Linear, InSine, OutSine, InOutSine, InQuad, OutQuad, InOutQuad, InCubic, OutCubic, InOutCubic, InQuart, OutQuart, InOutQuart, InQuint, OutQuint, InOutQuint, InExpo, OutExpo, InOutExpo, InCirc, OutCirc, InOutCirc, InBack, OutBack, InOutBack, InElastic, OutElastic, InOutElastic, InBounce, OutBounce, InOutBounce ];
	
	print($"Len: {array_length(List)} | 24Ease: {List[min(24 , array_length(List))]}");
	
	///@desc 检测缓动编号是否落在列表范围内
	///@param {Real} _ease_type 缓动编号
	///@returns {Bool} 编号可用时为真
	static Exists = (method(self, (function(_ease_type) {
		return(bool((_ease_type >= 0) || (_ease_type < (array_length(List)))));
	})));
	
	///@desc 按编号取出缓动函数，无效时返回错误函数
	///@param {Real} _ease_type 缓动编号
	///@returns {Any} 缓动函数
	static Address = (method(self, (function(_ease_type) {
		// 返回寻址结果
		if (!Exists(_ease_type)) then return(Error);
		return(array_get(List, _ease_type));
	})));
})());
