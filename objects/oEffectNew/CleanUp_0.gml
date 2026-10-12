///@desc 清理：清空特效队列并拆掉全局入口
effect_events = [];
eff_create = (
///@desc 清理后禁用特效入口，避免销毁后仍被调用
///@returns {Bool} 恒为 false
function(){ return(false); });
