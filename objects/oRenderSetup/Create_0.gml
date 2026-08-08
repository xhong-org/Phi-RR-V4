/// @description Interactive video-render settings.
depth = -1000000;
field = 0;
status = "";
status_colour = c_yellow;
path_text = "";
output_text = "";
fps_text = "60";
quality_text = "24";
resolution_index = 1; // 1080p
ratio_index = 0; // 16:9, the only supported plugin ratio
aa_index = 2; // 8x MSAA
fields = ["path", "output", "fps", "quality"];
resolutions = ["720p", "1080p", "1440p", "2160p"];
aa_values = [2, 4, 8];
ui_font = -1;
if (file_exists(working_directory + "resource/saira.ttf")) {
    font_add_enable_aa(true);
    ui_font = font_add(working_directory + "resource/saira.ttf", 25, true, false, -infinity, infinity);
};

function setup_set_status(text) { status = text; };
function setup_begin_text() {
    switch (field) {
        case 0: keyboard_string = path_text; break;
        case 1: keyboard_string = output_text; break;
        case 2: keyboard_string = fps_text; break;
        default: keyboard_string = quality_text; break;
    };
};
function setup_store_text() {
    switch (field) {
        case 0: path_text = string(keyboard_string); break;
        case 1: output_text = string(keyboard_string); break;
        case 2: fps_text = string(keyboard_string); break;
        default: quality_text = string(keyboard_string); break;
    };
};
setup_begin_text();
