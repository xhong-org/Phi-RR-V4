/// @desc Android GML wrapper for the pointer-packed initialize call. Other ffvideos_android_* functions come from FFVideos.ext.

function ffvideos_android_initialize() {
        var __args_buffer = __ext_core_get_args_buffer();
        buffer_write(__args_buffer, buffer_u64, int64(pointer_null));
        buffer_write(__args_buffer, buffer_u64, int64(pointer_null));
        return __ffvideos_android_initialize(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));
}
