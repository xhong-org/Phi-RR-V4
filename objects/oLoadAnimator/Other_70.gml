// 内建视频的 Async Social 回调；只处理本加载器持有的解锁视频。
if (mode != "unlock" || !unlock_open) then exit;
var _video_event = async_load[? "type"];
if (_video_event == "video_start") {
    video_set_volume(settings_store().musicVolume);
    unlock_started = true;
    print("[UnlockVideo] Playing; chart load is waiting");
} else if (_video_event == "video_end") {
    unlock_ended = true;
};
