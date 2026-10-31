package ${YYAndroidPackageName};

import android.app.Activity;
import android.os.Build;
import android.util.Log;
import android.view.Display;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

/** Display queries run at most once a second; window changes stay on the UI thread. */
final class AndroidDisplay {
    private volatile boolean needsApply = true;
    private int lastDisplayId = -1;
    private int lastModeId = -1;
    private float lastRate;

    void invalidate() {
        needsApply = true;
    }

    double refreshRate() {
        Activity activity = RunnerActivity.CurrentActivity;
        if (activity == null) return 0;
        View view = activity.findViewById(R.id.demogl);
        Display display = view == null ? null : view.getDisplay();
        if (display == null) return 0;

        try {
            float rate = display.getRefreshRate();
            int modeId = 0;
            if (Build.VERSION.SDK_INT >= 23) {
                Display.Mode current = display.getMode();
                modeId = current.getModeId();
                rate = current.getRefreshRate();
                // A faster mode at another resolution would resize every chart surface.
                for (Display.Mode mode : display.getSupportedModes()) {
                    if (mode.getPhysicalWidth() == current.getPhysicalWidth()
                        && mode.getPhysicalHeight() == current.getPhysicalHeight()
                        && mode.getRefreshRate() > rate) {
                        rate = mode.getRefreshRate();
                        modeId = mode.getModeId();
                    }
                }
            }
            if (Float.isNaN(rate) || Float.isInfinite(rate) || rate <= 0) return 0;

            if (needsApply || display.getDisplayId() != lastDisplayId
                || modeId != lastModeId || Math.abs(rate - lastRate) > 0.01f) {
                needsApply = false;
                lastDisplayId = display.getDisplayId();
                lastModeId = modeId;
                lastRate = rate;
                final float requestedRate = rate;
                final int requestedMode = modeId;
                activity.runOnUiThread(() -> {
                    if (RunnerActivity.CurrentActivity != activity || !view.hasWindowFocus()) {
                        needsApply = true;
                        return;
                    }
                    try {
                        Window window = activity.getWindow();
                        WindowManager.LayoutParams params = window.getAttributes();
                        if (Build.VERSION.SDK_INT >= 23) params.preferredDisplayModeId = requestedMode;
                        params.preferredRefreshRate = requestedRate;
                        window.setAttributes(params);
                        if (Build.VERSION.SDK_INT >= 30 && view instanceof SurfaceView) {
                            Surface surface = ((SurfaceView)view).getHolder().getSurface();
                            if (surface.isValid()) {
                                surface.setFrameRate(requestedRate, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT);
                            } else needsApply = true;
                        }
                        Log.i("yoyo", "[Display] Android requested " + requestedRate
                            + " Hz, mode=" + requestedMode);
                    } catch (RuntimeException error) {
                        Log.w("yoyo", "[Display] Android refresh request failed", error);
                    }
                });
            }
            return rate;
        } catch (RuntimeException error) {
            return 0;
        }
    }
}
