package com.gamemaker.ExtensionCore.ExtBridge;

// Separate from generated bridges so extension regeneration preserves the hook.
public final class FFVideosLifecycle {
    static { System.loadLibrary("FFVideos"); }

    private FFVideosLifecycle() {}

    public static native void invalidateContext();
}
