// ##### extgen :: Auto-generated file do not edit!! #####

package ${YYAndroidPackageName};
import ${YYAndroidPackageName}.GMExtWire.GMFunction;
import ${YYAndroidPackageName}.GMExtWire.GMValue;

public interface IAndroidFilesInterface {
    public String i_android_files_external_dir();
    public String i_android_files_internal_dir();
    public String i_android_files_logs_dir();
    public boolean i_android_files_mkdir(String path);
    public boolean i_android_files_exists(String path);
    public boolean i_android_files_is_dir(String path);
    public String i_android_files_list(String path);
    public boolean i_android_files_write_text(String path, String text);
    public boolean i_android_files_append_text(String path, String text);
    public String i_android_files_read_text(String path);
    public boolean i_android_files_copy(String source_path, String dest_path);
    public boolean i_android_files_delete(String path);
    public double i_android_files_size(String path);
    public boolean i_android_files_write_base64(String path, String data);
    public boolean i_android_files_append_base64(String path, String data);
    public String i_android_files_read_base64(String path);
    public String i_android_files_read_base64_range(String path, double offset, double size);
    public String i_android_files_error();
}