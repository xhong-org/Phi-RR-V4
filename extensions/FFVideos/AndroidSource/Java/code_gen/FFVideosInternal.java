package ${YYAndroidPackageName};
import static com.gamemaker.ExtensionCore.ExtBridge.FFVideosBridge.*;
import java.lang.String;
import java.nio.ByteBuffer;

public class FFVideosInternal extends RunnerSocial {
    public double __EXT_NATIVE__ffvideos_initialize(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__ffvideos_initialize(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__ffvideos_open(String path)
    {
        return __EXT_JNI__ffvideos_open(path);
    }
    public double __EXT_NATIVE__ffvideos_close(double handle)
    {
        return __EXT_JNI__ffvideos_close(handle);
    }
    public double __EXT_NATIVE__ffvideos_play(double handle)
    {
        return __EXT_JNI__ffvideos_play(handle);
    }
    public double __EXT_NATIVE__ffvideos_pause(double handle)
    {
        return __EXT_JNI__ffvideos_pause(handle);
    }
    public double __EXT_NATIVE__ffvideos_seek(double handle, double position_ms)
    {
        return __EXT_JNI__ffvideos_seek(handle, position_ms);
    }
    public double __EXT_NATIVE__ffvideos_prepare_frame(double handle, double position_ms, double timeout_ms)
    {
        return __EXT_JNI__ffvideos_prepare_frame(handle, position_ms, timeout_ms);
    }
    public double __EXT_NATIVE__ffvideos_set_volume(double handle, double volume)
    {
        return __EXT_JNI__ffvideos_set_volume(handle, volume);
    }
    public double __EXT_NATIVE__ffvideos_set_loop(double handle, double enabled)
    {
        return __EXT_JNI__ffvideos_set_loop(handle, enabled);
    }
    public double __EXT_NATIVE__ffvideos_get_status(double handle)
    {
        return __EXT_JNI__ffvideos_get_status(handle);
    }
    public double __EXT_NATIVE__ffvideos_get_duration(double handle)
    {
        return __EXT_JNI__ffvideos_get_duration(handle);
    }
    public double __EXT_NATIVE__ffvideos_get_position(double handle)
    {
        return __EXT_JNI__ffvideos_get_position(handle);
    }
    public double __EXT_NATIVE__ffvideos_get_width(double handle)
    {
        return __EXT_JNI__ffvideos_get_width(handle);
    }
    public double __EXT_NATIVE__ffvideos_get_height(double handle)
    {
        return __EXT_JNI__ffvideos_get_height(handle);
    }
    public double __EXT_NATIVE__ffvideos_draw(double handle, double left, double top, double right, double bottom, double alpha, double dim)
    {
        return __EXT_JNI__ffvideos_draw(handle, left, top, right, bottom, alpha, dim);
    }
    public String __EXT_NATIVE__ffvideos_get_error(double handle)
    {
        return __EXT_JNI__ffvideos_get_error(handle);
    }
    public double __EXT_NATIVE__ffvideos_shutdown()
    {
        return __EXT_JNI__ffvideos_shutdown();
    }
}