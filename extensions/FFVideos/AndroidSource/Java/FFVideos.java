package ${YYAndroidPackageName};
import java.lang.String;
import java.nio.ByteBuffer;

public final class FFVideos extends FFVideosInternal {
    @Override
    public void onPause() {
        com.gamemaker.ExtensionCore.ExtBridge.FFVideosLifecycle.invalidateContext();
    }
}
