// ##### extgen :: Auto-generated file do not edit!! #####

package ${YYAndroidPackageName};

import java.nio.ByteBuffer;
import java.util.*;
import ${YYAndroidPackageName}.GMExtWire;
import ${YYAndroidPackageName}.GMExtWire.GMFunction;
import ${YYAndroidPackageName}.GMExtWire.GMValue;

public abstract class IAndroidOpenInternal extends RunnerSocial implements IAndroidOpenInterface {

    public double __EXT_NATIVE__i_android_open_pick(String filter)
    {
        boolean __result = i_android_open_pick(filter);
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_open_busy()
    {
        boolean __result = i_android_open_busy();
        return __result ? 1.0 : 0.0;
    }

    public double __EXT_NATIVE__i_android_open_status()
    {
        int __result = i_android_open_status();
        return (double)__result;
    }

    public String __EXT_NATIVE__i_android_open_path()
    {
        String __result = i_android_open_path();
        return __result;
    }

    public String __EXT_NATIVE__i_android_open_name()
    {
        String __result = i_android_open_name();
        return __result;
    }

    public String __EXT_NATIVE__i_android_open_error()
    {
        String __result = i_android_open_error();
        return __result;
    }

    public double __EXT_NATIVE__i_android_open_reset()
    {
        i_android_open_reset();
        return 0;
    }

}