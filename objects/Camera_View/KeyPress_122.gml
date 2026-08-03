/// @description
// 你可以在此编辑器中写入代码 
if (variable_global_exists("render_mode") && global.render_mode) then exit;

var entering_fullscreen = !window_get_fullscreen();
if (entering_fullscreen) {
	window_set_showborder(false);
	window_set_fullscreen(true);
} else {
	window_set_fullscreen(false);
	window_set_showborder(true);
};
//if(window_get_fullscreen()){
//	surface_resize(application_surface , display_get_width() , display_get_height())	
//}else{
//	surface_resize(application_surface , window_get_width() , window_get_height());
//};
//display_set_gui_maximise(window_get_width() / 1366, window_get_height() / 768 , 0 , 0);

alarm[0] = 1;
