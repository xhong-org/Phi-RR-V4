///@desc 初始化交互式视频渲染设置
depth = -1000000;
field = 0;
status = "";
status_colour = c_yellow;
path_text = "";
output_text = "";
fps_text = "60";
quality_text = "24";
aspect_text = "16:9";
resolution_index = 1; // 默认 1080p
ratio_index = 0;
aa_index = 2; // 默认 8x MSAA
record_settlement = false;
fields = ["path", "output", "fps", "quality", "aspect"];
resolutions = ["720p", "1080p", "1440p", "2160p"];
ratios = ["16:9", "4:3", "1:1", "9:16"];
ratio_widths = [16, 4, 1, 9];
ratio_heights = [9, 3, 1, 16];
aa_values = [2, 4, 8];
ui_font = pls_ui_font_add(25, true, false, -infinity, infinity, false);

///@desc 写入渲染设置的状态提示
///@param {String} text 要显示的状态文字
///@returns {Undefined} 无
function setup_set_status(text) { status = text; };
///@desc 把当前字段的文字放进键盘缓冲
///@returns {Undefined} 无
function setup_begin_text() {
    // 按当前字段选择要编辑的文字。
    switch (field) {
        case 0: keyboard_string = path_text; break;
        case 1: keyboard_string = output_text; break;
        case 2: keyboard_string = fps_text; break;
        case 3: keyboard_string = quality_text; break;
        default: keyboard_string = aspect_text; break;
    };
};
///@desc 把键盘缓冲写回当前字段
///@returns {Undefined} 无
function setup_store_text() {
    // 按当前字段把键盘缓冲写回去。
    switch (field) {
        case 0: path_text = string(keyboard_string); break;
        case 1: output_text = string(keyboard_string); break;
        case 2: fps_text = string(keyboard_string); break;
        case 3: quality_text = string(keyboard_string); break;
        default: aspect_text = string(keyboard_string); break;
    };
};
setup_begin_text();
