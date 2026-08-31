package ${YYAndroidPackageName};

import android.app.Activity;
import android.util.Base64;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.io.RandomAccessFile;
import java.nio.charset.Charset;

public class IAndroidFiles extends IAndroidFilesInternal {
    private static final String TAG = "IAndroidFiles";
    private static final Charset UTF8 = Charset.forName("UTF-8");
    private static final int COPY_BUFFER = 64 * 1024;
    private static final long READ_LIMIT = 32L * 1024L * 1024L;
    private static final int BASE64_FLAGS = Base64.NO_WRAP;

    private final Object lock = new Object();
    private String error = "";

    private void setError(String message) {
        synchronized (lock) {
            error = message != null ? message : "";
        }
        if (error.length() > 0) {
            Log.w(TAG, error);
        }
    }

    private void clearError() {
        synchronized (lock) {
            error = "";
        }
    }

    private Activity activity() {
        return RunnerActivity.CurrentActivity;
    }

    private static String slashDir(File file) {
        if (file == null) return "";
        String path = file.getAbsolutePath();
        if (path == null || path.length() == 0) return "";
        path = path.replace('\\', '/');
        if (!path.endsWith("/")) path += "/";
        return path;
    }

    private static File fileFromPath(String path) {
        if (path == null) return null;
        String trimmed = path.trim();
        if (trimmed.length() == 0) return null;
        return new File(trimmed.replace('\\', '/'));
    }

    private static String message(Exception exception) {
        String text = exception.getMessage();
        return text != null && text.length() > 0 ? text : exception.getClass().getSimpleName();
    }

    private boolean mkdirFile(File dir) {
        if (dir.exists()) {
            if (dir.isDirectory()) return true;
            setError("Path exists and is not a directory: " + dir.getAbsolutePath());
            return false;
        }
        if (dir.mkdirs() || dir.isDirectory()) return true;
        setError("mkdirs failed: " + dir.getAbsolutePath());
        return false;
    }

    private boolean ensureParent(File file) {
        File parent = file.getParentFile();
        if (parent == null) return true;
        if (parent.isDirectory()) return true;
        if (mkdirFile(parent)) return true;
        setError("Failed to create parent directory: " + parent.getAbsolutePath());
        return false;
    }

    private boolean deleteRecursive(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (int i = 0; i < children.length; i++) {
                    if (!deleteRecursive(children[i])) return false;
                }
            }
        }
        return file.delete() || !file.exists();
    }

    private boolean writeText(String path, String text, boolean append) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("write path is empty.");
            return false;
        }
        if (file.isDirectory()) {
            setError("write path is a directory: " + file.getAbsolutePath());
            return false;
        }
        if (!ensureParent(file)) return false;
        if (text == null) text = "";
        try (FileOutputStream stream = new FileOutputStream(file, append);
             OutputStreamWriter writer = new OutputStreamWriter(stream, UTF8)) {
            writer.write(text);
            writer.flush();
            stream.flush();
            stream.getFD().sync();
        } catch (Exception exception) {
            setError((append ? "append" : "write") + " failed: " + message(exception));
            return false;
        }
        if (!file.exists()) {
            setError("write did not create: " + file.getAbsolutePath());
            return false;
        }
        clearError();
        return true;
    }

    private boolean writeBytes(String path, byte[] data, boolean append) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("write path is empty.");
            return false;
        }
        if (file.isDirectory()) {
            setError("write path is a directory: " + file.getAbsolutePath());
            return false;
        }
        if (!ensureParent(file)) return false;
        try (FileOutputStream stream = new FileOutputStream(file, append)) {
            if (data != null && data.length > 0) {
                stream.write(data);
            }
            stream.flush();
            stream.getFD().sync();
        } catch (Exception exception) {
            setError((append ? "append" : "write") + " failed: " + message(exception));
            return false;
        }
        if (!file.exists()) {
            setError("write did not create: " + file.getAbsolutePath());
            return false;
        }
        clearError();
        return true;
    }

    private byte[] decodeBase64(String data) {
        if (data == null || data.length() == 0) return new byte[0];
        long maxChars = (READ_LIMIT * 4L) / 3L + 16L;
        if ((long) data.length() > maxChars) {
            throw new IllegalArgumentException("base64 payload too large (" + data.length() + " chars)");
        }
        return Base64.decode(data, Base64.DEFAULT);
    }

    @Override
    public String i_android_files_external_dir() {
        Activity activity = activity();
        if (activity == null) {
            setError("Android activity is unavailable.");
            return "";
        }
        File dir = activity.getExternalFilesDir(null);
        if (dir == null) {
            setError("getExternalFilesDir returned null.");
            return "";
        }
        if (!mkdirFile(dir)) return "";
        clearError();
        String path = slashDir(dir);
        Log.i(TAG, "external dir: " + path);
        return path;
    }

    @Override
    public String i_android_files_internal_dir() {
        Activity activity = activity();
        if (activity == null) {
            setError("Android activity is unavailable.");
            return "";
        }
        File dir = activity.getFilesDir();
        if (dir == null) {
            setError("getFilesDir returned null.");
            return "";
        }
        if (!mkdirFile(dir)) return "";
        clearError();
        String path = slashDir(dir);
        Log.i(TAG, "internal dir: " + path);
        return path;
    }

    @Override
    public String i_android_files_logs_dir() {
        Activity activity = activity();
        if (activity == null) {
            setError("Android activity is unavailable.");
            return "";
        }

        File logs = activity.getExternalFilesDir("logs");
        if (logs != null && mkdirFile(logs)) {
            clearError();
            String path = slashDir(logs);
            Log.i(TAG, "logs dir: " + path);
            return path;
        }

        String externalFail = error;
        File internalBase = activity.getFilesDir();
        File internalLogs = internalBase != null ? new File(internalBase, "logs") : null;
        if (internalLogs != null && mkdirFile(internalLogs)) {
            String path = slashDir(internalLogs);
            Log.w(TAG, "external logs unavailable (" + externalFail + "), using internal: " + path);
            clearError();
            return path;
        }

        setError("Failed to create logs directory. external=" + externalFail + " internal=" + error);
        return "";
    }

    @Override
    public boolean i_android_files_mkdir(String path) {
        File dir = fileFromPath(path);
        if (dir == null) {
            setError("mkdir path is empty.");
            return false;
        }
        if (!mkdirFile(dir)) return false;
        clearError();
        return true;
    }

    @Override
    public boolean i_android_files_exists(String path) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("exists path is empty.");
            return false;
        }
        clearError();
        return file.exists();
    }

    @Override
    public boolean i_android_files_is_dir(String path) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("is_dir path is empty.");
            return false;
        }
        clearError();
        return file.isDirectory();
    }

    private void collectFiles(File dir, StringBuilder out) {
        File[] children = dir.listFiles();
        if (children == null) return;
        for (int i = 0; i < children.length; i++) {
            File child = children[i];
            if (child.isDirectory()) {
                collectFiles(child, out);
                continue;
            }
            if (out.length() > 0) out.append('\n');
            out.append(child.getAbsolutePath().replace('\\', '/'));
        }
    }

    @Override
    public String i_android_files_list(String path) {
        File dir = fileFromPath(path);
        if (dir == null) {
            setError("list path is empty.");
            return "";
        }
        if (!dir.exists()) {
            setError("list path does not exist: " + dir.getAbsolutePath());
            return "";
        }
        if (!dir.isDirectory()) {
            clearError();
            return dir.getAbsolutePath().replace('\\', '/');
        }
        StringBuilder out = new StringBuilder();
        collectFiles(dir, out);
        clearError();
        Log.i(TAG, "list " + dir.getAbsolutePath() + " bytes=" + out.length());
        return out.toString();
    }

    @Override
    public boolean i_android_files_write_text(String path, String text) {
        return writeText(path, text, false);
    }

    @Override
    public boolean i_android_files_append_text(String path, String text) {
        return writeText(path, text, true);
    }

    @Override
    public String i_android_files_read_text(String path) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("read path is empty.");
            return "";
        }
        if (!file.exists()) {
            setError("read path does not exist: " + file.getAbsolutePath());
            return "";
        }
        if (file.isDirectory()) {
            setError("read path is a directory: " + file.getAbsolutePath());
            return "";
        }
        long length = file.length();
        if (length > READ_LIMIT) {
            setError("file too large to read: " + file.getAbsolutePath() + " (" + length + " bytes)");
            return "";
        }
        int size = (int) length;
        try (FileInputStream stream = new FileInputStream(file)) {
            byte[] data = new byte[size];
            int offset = 0;
            while (offset < data.length) {
                int read = stream.read(data, offset, data.length - offset);
                if (read < 0) break;
                offset += read;
            }
            clearError();
            return new String(data, 0, offset, UTF8);
        } catch (Exception exception) {
            setError("read failed: " + message(exception));
            return "";
        }
    }

    @Override
    public boolean i_android_files_copy(String source_path, String dest_path) {
        File source = fileFromPath(source_path);
        File dest = fileFromPath(dest_path);
        if (source == null || dest == null) {
            setError("copy source or dest path is empty.");
            return false;
        }
        if (!source.exists()) {
            setError("copy source does not exist: " + source.getAbsolutePath());
            return false;
        }
        if (source.isDirectory()) {
            setError("copy source is a directory: " + source.getAbsolutePath());
            return false;
        }
        if (dest.isDirectory()) {
            dest = new File(dest, source.getName());
        }
        try {
            if (source.getCanonicalFile().equals(dest.getCanonicalFile())) {
                clearError();
                return true;
            }
        } catch (Exception ignored) {
        }
        if (!ensureParent(dest)) return false;
        try (InputStream input = new FileInputStream(source);
             FileOutputStream output = new FileOutputStream(dest, false)) {
            byte[] buffer = new byte[COPY_BUFFER];
            int read;
            while ((read = input.read(buffer)) >= 0) {
                output.write(buffer, 0, read);
            }
            output.flush();
            output.getFD().sync();
        } catch (Exception exception) {
            setError("copy failed: " + message(exception));
            return false;
        }
        if (!dest.exists()) {
            setError("copy did not create: " + dest.getAbsolutePath());
            return false;
        }
        clearError();
        return true;
    }

    @Override
    public boolean i_android_files_delete(String path) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("delete path is empty.");
            return false;
        }
        if (!file.exists()) {
            clearError();
            return true;
        }
        if (!deleteRecursive(file)) {
            setError("delete failed: " + file.getAbsolutePath());
            return false;
        }
        clearError();
        return true;
    }

    @Override
    public double i_android_files_size(String path) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("size path is empty.");
            return -1;
        }
        if (!file.exists()) {
            setError("size path does not exist: " + file.getAbsolutePath());
            return -1;
        }
        if (file.isDirectory()) {
            setError("size path is a directory: " + file.getAbsolutePath());
            return -1;
        }
        clearError();
        return (double) file.length();
    }

    @Override
    public boolean i_android_files_write_base64(String path, String data) {
        try {
            return writeBytes(path, decodeBase64(data), false);
        } catch (Exception exception) {
            setError("base64 write failed: " + message(exception));
            return false;
        }
    }

    @Override
    public boolean i_android_files_append_base64(String path, String data) {
        try {
            return writeBytes(path, decodeBase64(data), true);
        } catch (Exception exception) {
            setError("base64 append failed: " + message(exception));
            return false;
        }
    }

    @Override
    public String i_android_files_read_base64(String path) {
        return i_android_files_read_base64_range(path, 0, -1);
    }

    @Override
    public String i_android_files_read_base64_range(String path, double offset, double size) {
        File file = fileFromPath(path);
        if (file == null) {
            setError("read path is empty.");
            return "";
        }
        if (!file.exists()) {
            setError("read path does not exist: " + file.getAbsolutePath());
            return "";
        }
        if (file.isDirectory()) {
            setError("read path is a directory: " + file.getAbsolutePath());
            return "";
        }

        long fileSize = file.length();
        long start = offset > 0 ? (long) offset : 0L;
        if (start > fileSize) start = fileSize;
        long count;
        if (size < 0) {
            count = fileSize - start;
        } else {
            count = (long) size;
            if (start + count > fileSize) count = fileSize - start;
        }
        if (count < 0) count = 0;
        if (count > READ_LIMIT) {
            setError("file too large to read: " + file.getAbsolutePath() + " (" + count + " bytes)");
            return "";
        }
        if (count == 0) {
            clearError();
            return "";
        }

        byte[] data = new byte[(int) count];
        try (RandomAccessFile raf = new RandomAccessFile(file, "r")) {
            raf.seek(start);
            int filled = 0;
            while (filled < data.length) {
                int read = raf.read(data, filled, data.length - filled);
                if (read < 0) break;
                filled += read;
            }
            clearError();
            return Base64.encodeToString(data, 0, filled, BASE64_FLAGS);
        } catch (Exception exception) {
            setError("read failed: " + message(exception));
            return "";
        }
    }

    @Override
    public String i_android_files_error() {
        synchronized (lock) {
            return error != null ? error : "";
        }
    }
}
