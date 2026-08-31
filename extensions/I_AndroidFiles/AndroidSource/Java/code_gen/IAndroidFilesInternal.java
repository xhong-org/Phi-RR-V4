// ##### extgen :: Auto-generated file do not edit!! #####

package ${YYAndroidPackageName};

import java.nio.ByteBuffer;
import java.util.*;
import ${YYAndroidPackageName}.GMExtWire;
import ${YYAndroidPackageName}.GMExtWire.GMFunction;
import ${YYAndroidPackageName}.GMExtWire.GMValue;

public abstract class IAndroidFilesInternal extends RunnerSocial implements IAndroidFilesInterface {

    public String __EXT_NATIVE__i_android_files_external_dir()
    {
        String __result = i_android_files_external_dir();
        return __result;
    }

    public String __EXT_NATIVE__i_android_files_internal_dir()
    {
        String __result = i_android_files_internal_dir();
        return __result;
    }

    public String __EXT_NATIVE__i_android_files_logs_dir()
    {
        String __result = i_android_files_logs_dir();
        return __result;
    }

    public double __EXT_NATIVE__i_android_files_mkdir(String path)
    {
        boolean __result = i_android_files_mkdir(path);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_exists(String path)
    {
        boolean __result = i_android_files_exists(path);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_is_dir(String path)
    {
        boolean __result = i_android_files_is_dir(path);
        return __result ? 1.0 : 0.0;
    }

    public String __EXT_NATIVE__i_android_files_list(String path)
    {
        String __result = i_android_files_list(path);
        return __result;
    }

    public double __EXT_NATIVE__i_android_files_write_text(String path, String text)
    {
        boolean __result = i_android_files_write_text(path, text);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_append_text(String path, String text)
    {
        boolean __result = i_android_files_append_text(path, text);
        return __result ? 1.0 : 0.0;
    }

    public String __EXT_NATIVE__i_android_files_read_text(String path)
    {
        String __result = i_android_files_read_text(path);
        return __result;
    }

    public double __EXT_NATIVE__i_android_files_copy(String source_path, String dest_path)
    {
        boolean __result = i_android_files_copy(source_path, dest_path);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_delete(String path)
    {
        boolean __result = i_android_files_delete(path);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_size(String path)
    {
        double __result = i_android_files_size(path);
        return __result;
    }

    public double __EXT_NATIVE__i_android_files_write_base64(String path, String data)
    {
        boolean __result = i_android_files_write_base64(path, data);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_files_append_base64(String path, String data)
    {
        boolean __result = i_android_files_append_base64(path, data);
        return __result ? 1.0 : 0.0;
    }

    public String __EXT_NATIVE__i_android_files_read_base64(String path)
    {
        String __result = i_android_files_read_base64(path);
        return __result;
    }

    public String __EXT_NATIVE__i_android_files_read_base64_range(String path, double offset, double size)
    {
        String __result = i_android_files_read_base64_range(path, offset, size);
        return __result;
    }

    public String __EXT_NATIVE__i_android_files_error()
    {
        String __result = i_android_files_error();
        return __result;
    }

}