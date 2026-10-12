///@desc 绘制开始：开始谱面合成
// 先丢掉上一帧残留的着色器，避免结束线、音符或这次清屏被它带着画。
// 此时还没绑谱面表面。先刷新再复位，避免把已经画到应用程序表面上的背景清掉。
pls_draw_flush();
shader_reset();
// 没有应用表面就无法合成。
if (!application_surface_is_enabled() || !surface_exists(application_surface)) then exit;
chart_view_refresh(room_width, room_height);
// 合成表面建不出来就停。
if (!chart_mask_surface_ensure()) then exit;
pls_draw_flush();
gpu_push_state();
surface_set_target(surface_id);
target_active = true;
chart_surface_active = true;
chart_mask_scissor_set();
gpu_set_blendmode(bm_normal);
draw_set_colour(c_white);
draw_set_alpha(1);
draw_clear_alpha(c_black, 0);
// 新建表面的第一帧可能丢掉清屏之后画的东西。先把插图画上，避免同帧合成是一块空黑。
if (surface_born) then chart_draw_background(false);
