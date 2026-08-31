package com.gamemaker.ExtensionCore.ExtBridge;
import java.lang.String;
import java.nio.ByteBuffer;
import ${YYAndroidPackageName}.GMExtUtils;

public final class ICompressionBridge {
    static {
        // this is the extension lib name
        System.loadLibrary("ICompression");
        nativeRegister();
    }
    // this registers the native functions on the C++ layer
    private static native void nativeRegister();

    public static String __EXT_JAVA__GetExtensionOption(String extName, String optName)
    {
        return GMExtUtils.GetExtensionOption(extName, optName);
    }

    public static native double __EXT_JNI__unicode_zip_initialize();
    public static native double __EXT_JNI__unicode_zip_available();
    public static native String __EXT_JNI__unicode_zip_detect(String archive_path);
    public static native double __EXT_JNI__unicode_zip_extract(String archive_path, String output_directory, double overwrite, double clean_output);
    public static native double __EXT_JNI__unicode_zip_extract_password(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_compress(String source_path, String archive_path, double include_root, double overwrite);
    public static native double __EXT_JNI__unicode_zip_compress_password(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_compress_format(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_extract_async(String archive_path, String output_directory, double overwrite, double clean_output);
    public static native double __EXT_JNI__unicode_zip_extract_async_password(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_compress_async(String source_path, String archive_path, double include_root, double overwrite);
    public static native double __EXT_JNI__unicode_zip_compress_async_password(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_compress_async_format(ByteBuffer __arg_buffer, double __arg_buffer_length);
    public static native double __EXT_JNI__unicode_zip_task_status(double task_id);
    public static native double __EXT_JNI__unicode_zip_task_exit_code(double task_id);
    public static native String __EXT_JNI__unicode_zip_task_error(double task_id);
    public static native double __EXT_JNI__unicode_zip_task_cancel(double task_id);
    public static native double __EXT_JNI__unicode_zip_task_release(double task_id);
    public static native String __EXT_JNI__unicode_zip_last_error();
    public static native double __EXT_JNI__unicode_zip_shutdown();
}