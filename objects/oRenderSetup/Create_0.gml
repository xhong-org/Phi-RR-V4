/// @description Interactive video-render settings.
depth = -1000000;
field = 0;
status = "";
status_colour = c_yellow;
path_text = "";
output_text = "";
fps_text = "60";
quality_text = "24";
aspect_text = "16:9";
resolution_index = 1; // 1080p
ratio_index = 0;
aa_index = 2; // 8x MSAA
record_settlement = false;
fields = ["path", "output", "fps", "quality", "aspect"];
resolutions = ["720p", "1080p", "1440p", "2160p"];
ratios = ["16:9", "4:3", "1:1", "9:16"];
ratio_widths = [16, 4, 1, 9];
ratio_heights = [9, 3, 1, 16];
aa_values = [2, 4, 8];
ui_font = pls_ui_font_add(25, true, false, -infinity, infinity, false);

function setup_set_status(text) { status = text; };
function setup_begin_text() {
    switch (field) {
        case 0: keyboard_string = path_text; break;
        case 1: keyboard_string = output_text; break;
        case 2: keyboard_string = fps_text; break;
        case 3: keyboard_string = quality_text; break;
        default: keyboard_string = aspect_text; break;
    };
};
function setup_store_text() {
    switch (field) {
        case 0: path_text = string(keyboard_string); break;
        case 1: output_text = string(keyboard_string); break;
        case 2: fps_text = string(keyboard_string); break;
        case 3: quality_text = string(keyboard_string); break;
        default: aspect_text = string(keyboard_string); break;
    };
};
setup_begin_text();
