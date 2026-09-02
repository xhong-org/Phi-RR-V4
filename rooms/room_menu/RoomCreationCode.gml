// menu room
var menu_object = oMenu_Windows;
if (os_type == os_android) then menu_object = oMenu_Android;
else if (os_type == os_gxgames) then menu_object = oMenu_GX;
instance_create_depth(0, 0, 0, menu_object);
