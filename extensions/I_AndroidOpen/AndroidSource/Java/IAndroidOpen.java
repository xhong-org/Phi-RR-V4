package ${YYAndroidPackageName};

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.OpenableColumns;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class IAndroidOpen extends IAndroidOpenInternal {
    public static final int STATUS_IDLE = 0;
    public static final int STATUS_PICKING = 1;
    public static final int STATUS_OK = 2;
    public static final int STATUS_CANCELLED = 3;
    public static final int STATUS_ERROR = 4;

    private static final int REQUEST_OPEN = 0x49414F50;

    private final Object lock = new Object();
    private int status = STATUS_IDLE;
    private String path = "";
    private String name = "";
    private String error = "";

    @Override
    public boolean i_android_open_pick(String filter) {
        final Activity activity = RunnerActivity.CurrentActivity;
        if (activity == null) {
            synchronized (lock) {
                status = STATUS_ERROR;
                path = "";
                name = "";
                error = "Android activity is unavailable.";
            }
            return false;
        }

        synchronized (lock) {
            if (status == STATUS_PICKING) return false;
            status = STATUS_PICKING;
            path = "";
            name = "";
            error = "";
        }

        final String mime = mimeFromFilter(filter);
        activity.runOnUiThread(() -> {
            try {
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType(mime);
                intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[] {
                    "application/zip",
                    "application/x-zip-compressed",
                    "application/octet-stream",
                    "*/*"
                });
                if (Build.VERSION.SDK_INT >= 18) {
                    intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false);
                }
                activity.startActivityForResult(intent, REQUEST_OPEN);
            } catch (Exception exception) {
                synchronized (lock) {
                    status = STATUS_ERROR;
                    error = exception.getMessage() != null ? exception.getMessage() : "Failed to open the system picker.";
                }
            }
        });
        return true;
    }

    @Override
    public boolean i_android_open_busy() {
        synchronized (lock) {
            return status == STATUS_PICKING;
        }
    }

    @Override
    public int i_android_open_status() {
        synchronized (lock) {
            return status;
        }
    }

    @Override
    public String i_android_open_path() {
        synchronized (lock) {
            return path != null ? path : "";
        }
    }

    @Override
    public String i_android_open_name() {
        synchronized (lock) {
            return name != null ? name : "";
        }
    }

    @Override
    public String i_android_open_error() {
        synchronized (lock) {
            return error != null ? error : "";
        }
    }

    @Override
    public void i_android_open_reset() {
        synchronized (lock) {
            status = STATUS_IDLE;
            path = "";
            name = "";
            error = "";
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST_OPEN) return;
        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            synchronized (lock) {
                status = STATUS_CANCELLED;
                path = "";
                name = "";
                error = "No file selected.";
            }
            return;
        }

        final Uri uri = data.getData();
        final Activity activity = RunnerActivity.CurrentActivity;
        if (activity == null) {
            synchronized (lock) {
                status = STATUS_ERROR;
                error = "Android activity is unavailable.";
            }
            return;
        }

        try {
            String displayName = queryDisplayName(activity, uri);
            if (displayName == null || displayName.length() == 0) displayName = "chart.zip";
            displayName = sanitizeName(displayName);
            File imports = new File(activity.getFilesDir(), "imports");
            if (!imports.exists() && !imports.mkdirs()) {
                synchronized (lock) {
                    status = STATUS_ERROR;
                    error = "Failed to create the imports directory.";
                }
                return;
            }
            File outFile = new File(imports, displayName);
            try (InputStream input = activity.getContentResolver().openInputStream(uri);
                 FileOutputStream output = new FileOutputStream(outFile, false)) {
                if (input == null) {
                    synchronized (lock) {
                        status = STATUS_ERROR;
                        error = "Failed to open the selected document.";
                    }
                    return;
                }
                byte[] buffer = new byte[1024 * 64];
                int read;
                while ((read = input.read(buffer)) >= 0) {
                    output.write(buffer, 0, read);
                }
            }
            synchronized (lock) {
                status = STATUS_OK;
                name = displayName;
                path = outFile.getAbsolutePath();
                error = "";
            }
        } catch (Exception exception) {
            synchronized (lock) {
                status = STATUS_ERROR;
                path = "";
                name = "";
                error = exception.getMessage() != null ? exception.getMessage() : "Failed to copy the selected document.";
            }
        }
    }

    private static String mimeFromFilter(String filter) {
        if (filter == null || filter.length() == 0) return "*/*";
        String lower = filter.toLowerCase();
        if (lower.contains("/")) return filter;
        return "*/*";
    }

    private static String queryDisplayName(Activity activity, Uri uri) {
        Cursor cursor = activity.getContentResolver().query(uri, new String[] { OpenableColumns.DISPLAY_NAME }, null, null, null);
        if (cursor == null) return null;
        try {
            if (!cursor.moveToFirst()) return null;
            int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
            if (index < 0) return null;
            return cursor.getString(index);
        } finally {
            cursor.close();
        }
    }

    private static String sanitizeName(String displayName) {
        String name = displayName.replace('\\', '_').replace('/', '_').replace(':', '_');
        if (name.length() == 0) return "chart.zip";
        return name;
    }
}
