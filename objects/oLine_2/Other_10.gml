///@desc 用户事件 0：事件初始化
line_time = 0;
_counts = [0 , 0 , 0 , 0];

_x = (room_width / 2);
_y = (room_height / 2);
_a = 0;
_r = 0;
_s = 0;

var name = (struct_get_names(self.events));

// 速度事件不改缓动表；其余通道把缓动号映射成运行时索引。
for(var i = 0 ; i < array_length(name) ; i ++){
    var _events = (self.events[$ name[i]]);
    
    // 速度不走这张缓动表。
    if(name[i] == "speedEvents") then continue;
        
    var index = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, pointer_null, 17, 16, pointer_null, 19, 18, 22, 21, 20, 23, 25, 24, pointer_null, 27, 26, 28 ];
    
    for(var l = 0 ; l < array_length(_events) ; l ++){
        var _event = (_events[l]);
        // 第一条事件作为初始位置、透明度和旋转。
        if(l == 0){
            switch (name[i]) {
            	case "moveEvents":
                    _x = (number(_event.value[0] , 0));
                    _y = (number(_event.value[1] , 0));
                break;
            
                case "alphaEvents":
                    _a = (number(_event.value , 0));
                break;
            
                case "rotateEvents":
                    _r = (number(_event.value , 0));
                break;    
            };
        };
        
        //if(_events.startT)
        struct_set(self.events[$ name[i]][l] , "easingType" , index[_event.easingType]);
    };
};