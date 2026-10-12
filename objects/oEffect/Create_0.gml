///@desc 创建：旧版打击粒子系统，图层模式时放在 PhiZone z 7

// 图层模式用谱面 z 7，否则用打击特效深度。
depth = (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) ? chart_layer_depth(7) : DEPTH.HEF;
note_scale = 1;
image_blend = #ffeca0;
// Part System 粒子系统
p1 = part_system_create_layer("Instances",false);//part_system_create();
part_system_automatic_draw(p1,false);
part_system_automatic_update(p1,false);
part_system_depth(p1, depth);
//part_system_layer()

//depth = DEPTH.HIT_FX;

_hitFX = (part_type_create());
part_type_sprite(_hitFX,effect,true,0,0);
part_type_size(_hitFX , note_scale , note_scale , 0 , 0);
part_type_color1(_hitFX, image_blend);
part_type_subimage(_hitFX,0);
part_type_alpha3(_hitFX,0.7,0.7,0);

_spd = 50;
_hitTK = 0;
_scale = 3;
_scale_ins = 0.45;//((0.08 + ((__settings[$ "Notes_Size"] - 1) * 0.05)) * 2);

// HitEffect Part 打击特效粒子
part = part_type_create();
part_type_sprite(part,spr_pixel_1,0,0,0);
part_type_size(part,(_scale - 1) * note_scale , (_scale + 2) * note_scale , (_scale_ins * note_scale),0);
//part_type_scale(part,_scale,_scale);
part_type_color1(part,image_blend);
part_type_direction(part,0,360,0,0);
part_type_alpha3(part,0.7,0.7,0);
part_type_speed(part , (_spd - 15) * note_scale , (_spd * note_scale) , (-3.2 * note_scale) , 0 );



//part_

// 粒子和打击图都活 30 帧。
part_type_life(part,30,30);
part_type_life(_hitFX,30,30);

_timer = (get_timer());
isDraw = true;