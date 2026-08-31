package ${YYAndroidPackageName};
import static com.gamemaker.ExtensionCore.ExtBridge.ICompressionBridge.*;
import java.lang.String;
import java.nio.ByteBuffer;

public class ICompressionInternal extends RunnerSocial {
    public double __EXT_NATIVE__unicode_zip_initialize()
    {
        return __EXT_JNI__unicode_zip_initialize();
    }
    public double __EXT_NATIVE__unicode_zip_available()
    {
        return __EXT_JNI__unicode_zip_available();
    }
    public String __EXT_NATIVE__unicode_zip_detect(String archive_path)
    {
        return __EXT_JNI__unicode_zip_detect(archive_path);
    }
    public double __EXT_NATIVE__unicode_zip_extract(String archive_path, String output_directory, double overwrite, double clean_output)
    {
        return __EXT_JNI__unicode_zip_extract(archive_path, output_directory, overwrite, clean_output);
    }
    public double __EXT_NATIVE__unicode_zip_extract_password(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_extract_password(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_compress(String source_path, String archive_path, double include_root, double overwrite)
    {
        return __EXT_JNI__unicode_zip_compress(source_path, archive_path, include_root, overwrite);
    }
    public double __EXT_NATIVE__unicode_zip_compress_password(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_compress_password(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_compress_format(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_compress_format(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_extract_async(String archive_path, String output_directory, double overwrite, double clean_output)
    {
        return __EXT_JNI__unicode_zip_extract_async(archive_path, output_directory, overwrite, clean_output);
    }
    public double __EXT_NATIVE__unicode_zip_extract_async_password(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_extract_async_password(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_compress_async(String source_path, String archive_path, double include_root, double overwrite)
    {
        return __EXT_JNI__unicode_zip_compress_async(source_path, archive_path, include_root, overwrite);
    }
    public double __EXT_NATIVE__unicode_zip_compress_async_password(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_compress_async_password(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_compress_async_format(ByteBuffer __arg_buffer, double __arg_buffer_length)
    {
        return __EXT_JNI__unicode_zip_compress_async_format(__arg_buffer, __arg_buffer_length);
    }
    public double __EXT_NATIVE__unicode_zip_task_status(double task_id)
    {
        return __EXT_JNI__unicode_zip_task_status(task_id);
    }
    public double __EXT_NATIVE__unicode_zip_task_exit_code(double task_id)
    {
        return __EXT_JNI__unicode_zip_task_exit_code(task_id);
    }
    public String __EXT_NATIVE__unicode_zip_task_error(double task_id)
    {
        return __EXT_JNI__unicode_zip_task_error(task_id);
    }
    public double __EXT_NATIVE__unicode_zip_task_cancel(double task_id)
    {
        return __EXT_JNI__unicode_zip_task_cancel(task_id);
    }
    public double __EXT_NATIVE__unicode_zip_task_release(double task_id)
    {
        return __EXT_JNI__unicode_zip_task_release(task_id);
    }
    public String __EXT_NATIVE__unicode_zip_last_error()
    {
        return __EXT_JNI__unicode_zip_last_error();
    }
    public double __EXT_NATIVE__unicode_zip_shutdown()
    {
        return __EXT_JNI__unicode_zip_shutdown();
    }
}