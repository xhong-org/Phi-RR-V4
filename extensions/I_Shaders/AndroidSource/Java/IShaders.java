package ${YYAndroidPackageName};
import java.lang.String;
import java.nio.ByteBuffer;
import static com.gamemaker.ExtensionCore.ExtBridge.IShadersBridge.__EXT_JNI__rpe_hlsl_shutdown;

public final class IShaders extends IShadersInternal {
    @Override
    public void onPause() {
        // Runner stops its GL thread before dispatching extension onPause.
        // EGL may reuse the old context handle on resume; discard native names
        // now so the next Draw rebuilds programs and the capture texture.
        __EXT_JNI__rpe_hlsl_shutdown();
    }

    @Override
    public void onDestroy() {
        __EXT_JNI__rpe_hlsl_shutdown();
    }
}
