/// @description 

// 

var time_offset = max((((get_timer() - _timer) / 1000000) * 60), 1);
_timer = get_timer();

// 
if (!game.paused) {
    part_type_sprite(_hitFX, effect, true, 0, 0);
    var steps = min(time_offset, 5); // 
    repeat(steps) {
        part_system_update(p1);
    }
} else {
    part_type_sprite(_hitFX, effect, false, 0, 0);
}

// 
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
