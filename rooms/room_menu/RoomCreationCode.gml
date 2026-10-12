// 菜单房间：按操作系统创建对应菜单对象。
var menu_object = oMenu_Windows;
// Android 与 GX.games 各自使用独立菜单。
if (os_type == os_android) then menu_object = oMenu_Android;
else if (os_type == os_gxgames) then menu_object = oMenu_GX;
instance_create_depth(0, 0, 0, menu_object);
