///@desc 绘制：按真实帧间隔推进并画出旧版打击粒子
// 关闭绘制时直接退出。
if(!isDraw) then exit;

// 用计时器换成约 60 帧的步数，至少推进一步。
var time_offset = max((((get_timer() - _timer) / 1000000) * 60), 1);
_timer = get_timer();

// 未暂停才动画；暂停时停在当前子图。
if (!game.paused) {
    part_type_sprite(_hitFX, effect, true, 0, 0);
    var steps = min(time_offset, 5); // 单帧最多补 5 步，避免卡顿后粒子暴冲
    repeat(steps) {
        part_system_update(p1);
    }
} else {
    part_type_sprite(_hitFX, effect, false, 0, 0);
}

part_system_drawit(p1);


/*
var time_offset = (max( (((get_timer() - _timer) / 1000000) * 60) , 1));
_timer = (get_timer());

//BYD_COLOR_FUNC;
//else{
//	image_blend = #ffeca0;
//	part_type_color1(_hitFX, image_blend);
//	part_type_color1(part,image_blend);
//};

//part_type_color1(_hitFX, image_blend);
//part_type_color1(part,image_blend);

if(!(game.paused)){
	//depth = DEPTH.HIT_FX;
	part_type_sprite(_hitFX,effect,true,0,0);
	repeat(time_offset){
		part_system_update(p1);	
	};

}else{
	part_type_sprite(_hitFX,effect,false,0,0);
};
part_system_drawit(p1);
*/
