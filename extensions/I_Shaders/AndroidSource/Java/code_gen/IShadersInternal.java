package ${YYAndroidPackageName};
import static com.gamemaker.ExtensionCore.ExtBridge.IShadersBridge.*;
import java.lang.String;
import java.nio.ByteBuffer;

public class IShadersInternal extends RunnerSocial {
    public double __EXT_NATIVE__rpe_hlsl_initialize(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__rpe_hlsl_initialize(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__rpe_hlsl_state()
    {
        return __EXT_JNI__rpe_hlsl_state();
    }
    public double __EXT_NATIVE__rpe_hlsl_compile(String source, String source_name)
    {
        return __EXT_JNI__rpe_hlsl_compile(source, source_name);
    }
    public String __EXT_NATIVE__rpe_glsl_translate(String source, String source_name)
    {
        return __EXT_JNI__rpe_glsl_translate(source, source_name);
    }
    public double __EXT_NATIVE__rpe_hlsl_set_uniform_component(double handle, String uniform_name, double component, double value)
    {
        return __EXT_JNI__rpe_hlsl_set_uniform_component(handle, uniform_name, component, value);
    }
    public double __EXT_NATIVE__rpe_hlsl_begin(double handle)
    {
        return __EXT_JNI__rpe_hlsl_begin(handle);
    }
    public double __EXT_NATIVE__rpe_hlsl_draw(double handle, double uv_left, double uv_top, double uv_right, double uv_bottom)
    {
        return __EXT_JNI__rpe_hlsl_draw(handle, uv_left, uv_top, uv_right, uv_bottom);
    }
    public double __EXT_NATIVE__rpe_hlsl_target_width()
    {
        return __EXT_JNI__rpe_hlsl_target_width();
    }
    public double __EXT_NATIVE__rpe_hlsl_target_height()
    {
        return __EXT_JNI__rpe_hlsl_target_height();
    }
    public double __EXT_NATIVE__rpe_hlsl_end()
    {
        return __EXT_JNI__rpe_hlsl_end();
    }
    public double __EXT_NATIVE__rpe_hlsl_release(double handle)
    {
        return __EXT_JNI__rpe_hlsl_release(handle);
    }
    public double __EXT_NATIVE__rpe_hlsl_shutdown()
    {
        return __EXT_JNI__rpe_hlsl_shutdown();
    }
    public String __EXT_NATIVE__rpe_hlsl_get_error()
    {
        return __EXT_JNI__rpe_hlsl_get_error();
    }
}