package ${YYAndroidPackageName};

import android.app.Activity;
import android.os.SystemClock;
import android.view.MotionEvent;
import android.view.View;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;

/** Raw input, before RunnerJNILib.TouchEvent. No Runtime touch indices are used. */
public final class IAndroidTouch extends RunnerSocial {
    private static final int CAPACITY = 4096;
    private static final int HEADER_BYTES = 20;
    private static final int EVENT_BYTES = 20;
    private static final int DOWN = 1;
    private static final int MOVE = 2;
    private static final int UP = 3;

    private final Object lock = new Object();
    private final AndroidDisplay display = new AndroidDisplay();
    private final int[] types = new int[CAPACITY];
    private final int[] tokens = new int[CAPACITY];
    private final float[] xs = new float[CAPACITY];
    private final float[] ys = new float[CAPACITY];
    private final long[] times = new long[CAPACITY];
    private final int[] pointers = new int[32];
    private int count;
    private int sequence;
    private int generation;
    private boolean focused = true;
    private long suspendedAt = -1;

    private void clearLocked() {
        count = 0;
        generation++;
        Arrays.fill(pointers, 0);
    }

    private void append(int type, int token, float x, float y, long time) {
        if (count == CAPACITY) {
            // A discontinuous stream must cancel holds, never invent a press.
            clearLocked();
            return;
        }
        types[count] = type;
        tokens[count] = token;
        xs[count] = x;
        ys[count] = y;
        times[count] = time;
        count++;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        Activity activity = RunnerActivity.CurrentActivity;
        View view = activity == null ? null : activity.findViewById(R.id.demogl);
        if (view == null || view.getWidth() <= 0 || view.getHeight() <= 0) return true;
        int action = event.getActionMasked();
        if (action == MotionEvent.ACTION_DOWN) view.requestUnbufferedDispatch(event);
        float sx = 1.0f / view.getWidth();
        float sy = 1.0f / view.getHeight();
        synchronized (lock) {
            if (!focused) return true;
            if (action == MotionEvent.ACTION_CANCEL || action == MotionEvent.ACTION_OUTSIDE) {
                clearLocked();
                return true;
            }
            int actionIndex = event.getActionIndex();
            // Android batches moves independently of the render rate. Preserve
            // their original times so low FPS does not erase a short flick.
            if (action == MotionEvent.ACTION_MOVE) {
                for (int h = 0; h < event.getHistorySize(); h++) {
                    for (int i = 0; i < event.getPointerCount(); i++) {
                        int id = event.getPointerId(i);
                        if (id < 0 || id >= pointers.length || pointers[id] == 0) continue;
                        append(MOVE, pointers[id], event.getHistoricalX(i, h) * sx,
                            event.getHistoricalY(i, h) * sy, event.getHistoricalEventTime(h));
                    }
                }
            }
            for (int i = 0; i < event.getPointerCount(); i++) {
                int id = event.getPointerId(i);
                if (id < 0 || id >= pointers.length) continue;
                int type = MOVE;
                if (i == actionIndex && (action == MotionEvent.ACTION_DOWN
                    || action == MotionEvent.ACTION_POINTER_DOWN)) {
                    // Tokens identify a contact, not an Android pointer slot.
                    sequence = sequence == Integer.MAX_VALUE ? 1 : sequence + 1;
                    pointers[id] = sequence;
                    type = DOWN;
                } else if (i == actionIndex && (action == MotionEvent.ACTION_UP
                    || action == MotionEvent.ACTION_POINTER_UP)) type = UP;
                if (pointers[id] == 0) continue;
                append(type, pointers[id], event.getX(i) * sx, event.getY(i) * sy, event.getEventTime());
                if (type == UP) pointers[id] = 0;
            }
        }
        // Own the entire stream; menu and gameplay share this extension.
        return true;
    }

    /** LE packet: version/count/generation/focus/suspend-age, then events. */
    public double i_android_touch_poll(ByteBuffer packet, double length) {
        if (packet == null || length < HEADER_BYTES || packet.capacity() < HEADER_BYTES) return -1;
        packet.order(ByteOrder.LITTLE_ENDIAN);
        synchronized (lock) {
            int limit = (Math.min(packet.capacity(), (int)length) - HEADER_BYTES) / EVENT_BYTES;
            if (limit < count) clearLocked();
            long now = SystemClock.uptimeMillis();
            packet.putInt(0, 2);
            packet.putInt(4, count);
            packet.putInt(8, generation);
            packet.putInt(12, focused ? 1 : 0);
            packet.putInt(16, suspendedAt < 0 ? -1
                : (int)Math.min(Integer.MAX_VALUE, Math.max(0, now - suspendedAt)));
            suspendedAt = -1;
            for (int i = 0; i < count; i++) {
                int offset = HEADER_BYTES + i * EVENT_BYTES;
                packet.putInt(offset, types[i]);
                packet.putInt(offset + 4, tokens[i]);
                packet.putFloat(offset + 8, xs[i]);
                packet.putFloat(offset + 12, ys[i]);
                packet.putInt(offset + 16, (int)Math.min(Integer.MAX_VALUE, Math.max(0, now - times[i])));
            }
            count = 0;
        }
        return 1;
    }

    public double i_android_touch_reset() {
        synchronized (lock) { clearLocked(); suspendedAt = -1; }
        return 0;
    }

    public double i_android_display_refresh_rate() {
        return display.refreshRate();
    }

    private void suspendLocked() {
        if (suspendedAt < 0) suspendedAt = SystemClock.uptimeMillis();
        focused = false;
        clearLocked();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        if (hasFocus) display.invalidate();
        synchronized (lock) {
            if (!hasFocus) suspendLocked();
            else focused = true;
        }
    }

    @Override
    public void onPause() {
        synchronized (lock) { suspendLocked(); }
    }

    @Override
    public void onResume() {
        display.invalidate();
        synchronized (lock) { focused = true; clearLocked(); }
    }

    @Override
    public void onDestroy() {
        synchronized (lock) { suspendLocked(); }
    }
}
