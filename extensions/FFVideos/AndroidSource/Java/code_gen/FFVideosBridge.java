package com.gamemaker.ExtensionCore.ExtBridge;
import java.lang.String;
import java.nio.ByteBuffer;
import ${YYAndroidPackageName}.GMExtUtils;

public final class FFVideosBridge {
    static {
        // this is the extension lib name
        System.loadLibrary("FFVideos");
        nativeRegister();
    }
    // this registers the native functions on the C++ layer
    private static native void nativeRegister();

    public static String __EXT_JAVA__GetExtensionOption(String extName, String optName)
    {
        return GMExtUtils.GetExtensionOption(extName, optName);
    }

    public static native double __EXT_JNI__ffvideos_initialize(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__ffvideos_open(String path);
    public static native double __EXT_JNI__ffvideos_close(double handle);
    public static native double __EXT_JNI__ffvideos_play(double handle);
    public static native double __EXT_JNI__ffvideos_pause(double handle);
    public static native double __EXT_JNI__ffvideos_seek(double handle, double position_ms);
    public static native double __EXT_JNI__ffvideos_prepare_frame(double handle, double position_ms, double timeout_ms);
    public static native double __EXT_JNI__ffvideos_set_volume(double handle, double volume);
    public static native double __EXT_JNI__ffvideos_set_loop(double handle, double enabled);
    public static native double __EXT_JNI__ffvideos_get_status(double handle);
    public static native double __EXT_JNI__ffvideos_get_duration(double handle);
    public static native double __EXT_JNI__ffvideos_get_position(double handle);
    public static native double __EXT_JNI__ffvideos_get_width(double handle);
    public static native double __EXT_JNI__ffvideos_get_height(double handle);
    public static native double __EXT_JNI__ffvideos_draw(double handle, double left, double top, double right, double bottom, double alpha, double dim);
    public static native String __EXT_JNI__ffvideos_get_error(double handle);
    public static native double __EXT_JNI__ffvideos_shutdown();
}