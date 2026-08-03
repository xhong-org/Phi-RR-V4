/// @description 

// 璁＄畻鏃堕棿鍋忕Щ锛堝熀浜庣湡瀹炴椂闂磋€屼笉鏄抚鏁帮級

var time_offset = max((((get_timer() - _timer) / 1000000) * 60), 1);
_timer = get_timer();

// 鏇存柊绮掑瓙绯荤粺锛堣ˉ鍋夸綆甯х巼锛?
if (!game.paused) {
    part_type_sprite(_hitFX, effect, true, 0, 0);
    var steps = min(time_offset, 5); // 闄愬埗鏈€澶цˉ鍋挎鏁?
    repeat(steps) {
        part_system_update(p1);
    }
} else {
    part_type_sprite(_hitFX, effect, false, 0, 0);
}

// 缁樺埗绮掑瓙绯荤粺
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
