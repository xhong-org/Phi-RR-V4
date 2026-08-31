package com.gamemaker.ExtensionCore.ExtBridge;
import java.lang.String;
import java.nio.ByteBuffer;
import ${YYAndroidPackageName}.GMExtUtils;

public final class IShadersBridge {
    static {
        // this is the extension lib name
        System.loadLibrary("IShaders");
        nativeRegister();
    }
    // this registers the native functions on the C++ layer
    private static native void nativeRegister();

    public static String __EXT_JAVA__GetExtensionOption(String extName, String optName)
    {
        return GMExtUtils.GetExtensionOption(extName, optName);
    }

    public static native double __EXT_JNI__rpe_hlsl_initialize(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__rpe_hlsl_state();
    public static native double __EXT_JNI__rpe_hlsl_compile(String source, String source_name);
    public static native String __EXT_JNI__rpe_glsl_translate(String source, String source_name);
    public static native double __EXT_JNI__rpe_hlsl_set_uniform_component(double handle, String uniform_name, double component, double value);
    public static native double __EXT_JNI__rpe_hlsl_begin(double handle);
    public static native double __EXT_JNI__rpe_hlsl_draw(double handle, double uv_left, double uv_top, double uv_right, double uv_bottom);
    public static native double __EXT_JNI__rpe_hlsl_target_width();
    public static native double __EXT_JNI__rpe_hlsl_target_height();
    public static native double __EXT_JNI__rpe_hlsl_end();
    public static native double __EXT_JNI__rpe_hlsl_release(double handle);
    public static native double __EXT_JNI__rpe_hlsl_shutdown();
    public static native String __EXT_JNI__rpe_hlsl_get_error();
}