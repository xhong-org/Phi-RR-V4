/// @desc Standalone GIF87a/GIF89a decoder.

function rpe_gif__fail(msg) {
    throw msg;
}

function rpe_gif__u8(state) {
    if (state.pos >= state.size) then rpe_gif__fail("Unexpected end of GIF data");
    var value = buffer_peek(state.file_buffer, state.pos, buffer_u8);
    state.pos += 1;
    return value;
}

function rpe_gif__u16(state) {
    var lo = rpe_gif__u8(state);
    return lo | (rpe_gif__u8(state) << 8);
}

function rpe_gif__palette(state, count) {
    var palette = array_create(count, 0);
    for (var i = 0; i < count; i++) {
        var red = rpe_gif__u8(state);
        var green = rpe_gif__u8(state);
        var blue = rpe_gif__u8(state);
        palette[i] = red | (green << 8) | (blue << 16);
    }
    return palette;
}

function rpe_gif__skip_subblocks(state) {
    while (true) {
        var count = rpe_gif__u8(state);
        if (count == 0) then return;
        if (state.pos + count > state.size) then rpe_gif__fail("Truncated GIF subblock");
        state.pos += count;
    }
}

function rpe_gif__read_subblocks(state) {
    var bytes = [];
    while (true) {
        var count = rpe_gif__u8(state);
        if (count == 0) then return bytes;
        if (state.pos + count > state.size) then rpe_gif__fail("Truncated GIF image data");
        for (var i = 0; i < count; i++) {
            array_add(bytes, rpe_gif__u8(state));
        }
    }
}

function rpe_gif__lzw_decode(bytes, minimum_code_size, expected_size) {
    if (minimum_code_size < 2 || minimum_code_size > 8) then rpe_gif__fail("Invalid GIF LZW code size");

    var clear_code = 1 << minimum_code_size;
    var end_code = clear_code + 1;
    var available = clear_code + 2;
    var code_size = minimum_code_size + 1;
    var prefix = array_create(4096, 0);
    var suffix = array_create(4096, 0);
    var stack = array_create(4097, 0);
    var output = array_create(expected_size, 0);

    for (var i = 0; i < clear_code; i++) {
        suffix[i] = i;
    }

    var byte_pos = 0;
    var bit_data = 0;
    var bit_count = 0;
    var old_code = -1;
    var first_value = 0;
    var output_pos = 0;

    while (output_pos < expected_size) {
        while (bit_count < code_size) {
            if (byte_pos >= array_length(bytes)) then rpe_gif__fail("Truncated GIF LZW stream");
            bit_data = bit_data | (bytes[byte_pos] << bit_count);
            bit_count += 8;
            byte_pos += 1;
        }

        var code = bit_data & ((1 << code_size) - 1);
        bit_data = bit_data >> code_size;
        bit_count -= code_size;

        if (code == clear_code) {
            available = clear_code + 2;
            code_size = minimum_code_size + 1;
            old_code = -1;
            continue;
        }
        if (code == end_code) then break;

        if (old_code < 0) {
            if (code >= clear_code) then rpe_gif__fail("Invalid first GIF LZW code");
            output[output_pos] = code;
            output_pos += 1;
            first_value = code;
            old_code = code;
            continue;
        }

        var input_code = code;
        var stack_size = 0;
        if (code == available) {
            stack[stack_size] = first_value;
            stack_size += 1;
            code = old_code;
        } else if (code > available) {
            rpe_gif__fail("Invalid GIF LZW dictionary code");
        }

        while (code >= clear_code) {
            if (code >= available || stack_size >= 4096) then rpe_gif__fail("Invalid GIF LZW dictionary chain");
            stack[stack_size] = suffix[code];
            stack_size += 1;
            code = prefix[code];
        }

        first_value = suffix[code];
        stack[stack_size] = first_value;
        stack_size += 1;

        while (stack_size > 0 && output_pos < expected_size) {
            stack_size -= 1;
            output[output_pos] = stack[stack_size];
            output_pos += 1;
        }

        if (available < 4096) {
            prefix[available] = old_code;
            suffix[available] = first_value;
            available += 1;
            if (available == (1 << code_size) && code_size < 12) {
                code_size += 1;
            }
        }
        old_code = input_code;
    }

    if (output_pos != expected_size) then rpe_gif__fail("GIF image has too few pixels");
    return output;
}

function rpe_gif__clear_rect(state, left, top, width, height) {
    var x0 = max(0, left);
    var y0 = max(0, top);
    var x1 = min(state.width, left + width);
    var y1 = min(state.height, top + height);
    for (var yy = y0; yy < y1; yy++) {
        var offset = ((yy * state.width + x0) * 4);
        for (var xx = x0; xx < x1; xx++) {
            buffer_poke(state.canvas, offset, buffer_u8, state.background_color & 255);
            buffer_poke(state.canvas, offset + 1, buffer_u8, (state.background_color >> 8) & 255);
            buffer_poke(state.canvas, offset + 2, buffer_u8, (state.background_color >> 16) & 255);
            buffer_poke(state.canvas, offset + 3, buffer_u8, state.background_alpha);
            offset += 4;
        }
    }
}

function rpe_gif__apply_disposal(state) {
    switch (state.previous_disposal) {
        case 2:
            rpe_gif__clear_rect(state, state.previous_left, state.previous_top,
                state.previous_width, state.previous_height);
            break;
        case 3:
            if (state.restore_valid) {
                buffer_copy(state.restore, 0, state.canvas_size, state.canvas, 0);
                state.restore_valid = false;
            }
            break;
    }
}

function rpe_gif__draw_image(state, pixels, palette, left, top, image_width,
        image_height, interlaced, transparent, transparent_index) {
    var source_pos = 0;
    var pass_starts = interlaced ? [0, 4, 2, 1] : [0];
    var pass_steps = interlaced ? [8, 8, 4, 2] : [1];

    for (var pass = 0; pass < array_length(pass_starts); pass++) {
        for (var image_y = pass_starts[pass]; image_y < image_height; image_y += pass_steps[pass]) {
            var canvas_y = top + image_y;
            for (var image_x = 0; image_x < image_width; image_x++) {
                var color_index = pixels[source_pos];
                source_pos += 1;
                if (transparent && color_index == transparent_index) then continue;
                if (color_index < 0 || color_index >= array_length(palette)) then rpe_gif__fail("GIF color index is out of range");

                var canvas_x = left + image_x;
                if (canvas_x < 0 || canvas_x >= state.width || canvas_y < 0 || canvas_y >= state.height) then continue;
                var color = palette[color_index];
                var offset = ((canvas_y * state.width + canvas_x) * 4);
                buffer_poke(state.canvas, offset, buffer_u8, color & 255);
                buffer_poke(state.canvas, offset + 1, buffer_u8, (color >> 8) & 255);
                buffer_poke(state.canvas, offset + 2, buffer_u8, (color >> 16) & 255);
                buffer_poke(state.canvas, offset + 3, buffer_u8, 255);
            }
        }
    }
}

function rpe_gif__capture_frame(state) {
    var frame_pixels = state.width * state.height;
    if (array_length(state.frames) >= 256 || state.decoded_pixels + frame_pixels > 16777216) {
        rpe_gif__fail("GIF frame budget exceeded");
    }
    state.decoded_pixels += frame_pixels;
    state.surface = surface_create(state.width, state.height);
    if (state.surface < 0 || !surface_exists(state.surface)) then rpe_gif__fail("Could not create GIF frame surface");
    buffer_set_surface(state.canvas, state.surface, 0);
    var sprite = sprite_create_from_surface(state.surface, 0, 0, state.width, state.height,
        false, false, floor(state.width * 0.5), floor(state.height * 0.5));
    surface_free(state.surface);
    state.surface = -1;
    if (!sprite_exists(sprite)) then rpe_gif__fail("Could not create GIF frame sprite");
    array_add(state.frames, sprite);
}

function rpe_gif__cleanup(state, delete_sprites) {
    if (state.surface >= 0 && surface_exists(state.surface)) {
        surface_free(state.surface);
    }
    state.surface = -1;
    if (state.file_buffer >= 0) {
        buffer_delete(state.file_buffer);
        state.file_buffer = -1;
    }
    if (state.canvas >= 0) {
        buffer_delete(state.canvas);
        state.canvas = -1;
    }
    if (state.restore >= 0) {
        buffer_delete(state.restore);
        state.restore = -1;
    }
    if (delete_sprites) {
        for (var i = 0; i < array_length(state.frames); i++) {
            if (sprite_exists(state.frames[i])) then sprite_delete(state.frames[i]);
        }
        state.frames = [];
    }
}

/// @function rpe_gif_decode(file_path)
/// @param {String} file_path
/// @returns {Struct|Undefined} Decoded GIF frames and timing, or undefined on failure.
function rpe_gif_decode(file_path) {
    var state = {
        file_buffer: -1,
        canvas: -1,
        restore: -1,
        surface: -1,
        size: 0,
        pos: 0,
        width: 0,
        height: 0,
        canvas_size: 0,
        frames: [],
        delays: [],
        total: 0,
        previous_disposal: 0,
        previous_left: 0,
        previous_top: 0,
        previous_width: 0,
        previous_height: 0,
        restore_valid: false,
		background_color: 0,
		background_alpha: 0,
		decoded_pixels: 0
    };

    try {
        if (!is_string(file_path) || !file_exists(file_path)) then rpe_gif__fail("GIF file does not exist");
        state.file_buffer = buffer_load(file_path);
        if (state.file_buffer < 0) then rpe_gif__fail("Could not load GIF file");
        state.size = buffer_get_size(state.file_buffer);
        if (state.size < 13) then rpe_gif__fail("GIF file is too small");

        var signature = "";
        for (var header_pos = 0; header_pos < 6; header_pos++) {
            signature += chr(rpe_gif__u8(state));
        }
        if (signature != "GIF87a" && signature != "GIF89a") then rpe_gif__fail("Invalid GIF signature");

        state.width = rpe_gif__u16(state);
        state.height = rpe_gif__u16(state);
        if (state.width <= 0 || state.height <= 0) then rpe_gif__fail("Invalid GIF dimensions");
        state.canvas_size = state.width * state.height * 4;
        if (state.canvas_size <= 0 || state.width * state.height > 4194304) then rpe_gif__fail("GIF dimensions are too large");

        var screen_flags = rpe_gif__u8(state);
        var background_index = rpe_gif__u8(state);
        rpe_gif__u8(state); // Pixel aspect ratio.
        var global_palette = [];
        if ((screen_flags & $80) != 0) {
            global_palette = rpe_gif__palette(state, 1 << ((screen_flags & 7) + 1));
			if (background_index >= 0 && background_index < array_length(global_palette)) {
				state.background_color = global_palette[background_index];
				state.background_alpha = 255;
			};
        }

        state.canvas = buffer_create(state.canvas_size, buffer_fixed, 1);
        state.restore = buffer_create(state.canvas_size, buffer_fixed, 1);
        if (state.canvas < 0 || state.restore < 0) then rpe_gif__fail("Could not allocate GIF canvas buffers");
        buffer_fill(state.canvas, 0, buffer_u8, 0, state.canvas_size);
        buffer_fill(state.restore, 0, buffer_u8, 0, state.canvas_size);

        var gce_delay = 0;
        var gce_transparent = false;
        var gce_transparent_index = 0;
        var gce_disposal = 0;
        var finished = false;

        while (!finished) {
            var marker = rpe_gif__u8(state);
            switch (marker) {
                case $3B:
                    finished = true;
                    break;

                case $21:
                    var extension_type = rpe_gif__u8(state);
                    if (extension_type == $F9) {
                        if (rpe_gif__u8(state) != 4) then rpe_gif__fail("Invalid GIF graphic control extension");
                        var gce_flags = rpe_gif__u8(state);
                        gce_delay = max(0.01, rpe_gif__u16(state) * 0.01);
                        gce_transparent_index = rpe_gif__u8(state);
                        if (rpe_gif__u8(state) != 0) then rpe_gif__fail("Invalid GIF graphic control terminator");
                        gce_transparent = (gce_flags & 1) != 0;
                        gce_disposal = (gce_flags >> 2) & 7;
                        if (gce_disposal > 3) then gce_disposal = 0;
                    } else {
                        rpe_gif__skip_subblocks(state);
                    }
                    break;

                case $2C:
                    rpe_gif__apply_disposal(state);

                    var image_left = rpe_gif__u16(state);
                    var image_top = rpe_gif__u16(state);
                    var image_width = rpe_gif__u16(state);
                    var image_height = rpe_gif__u16(state);
                    if (image_width <= 0 || image_height <= 0) then rpe_gif__fail("Invalid GIF image dimensions");
                    var image_pixel_count = image_width * image_height;
                    if (image_pixel_count <= 0 || image_pixel_count > 2147483647) then rpe_gif__fail("GIF image dimensions are too large");

                    var image_flags = rpe_gif__u8(state);
                    var palette = global_palette;
                    if ((image_flags & $80) != 0) {
                        palette = rpe_gif__palette(state, 1 << ((image_flags & 7) + 1));
                    }
                    if (array_length(palette) == 0) then rpe_gif__fail("GIF image has no color table");

                    var minimum_code_size = rpe_gif__u8(state);
                    var compressed = rpe_gif__read_subblocks(state);
                    var pixels = rpe_gif__lzw_decode(compressed, minimum_code_size, image_pixel_count);

                    if (gce_disposal == 3) {
                        buffer_copy(state.canvas, 0, state.canvas_size, state.restore, 0);
                        state.restore_valid = true;
                    } else {
                        state.restore_valid = false;
                    }

                    rpe_gif__draw_image(state, pixels, palette, image_left, image_top,
                        image_width, image_height, (image_flags & $40) != 0,
                        gce_transparent, gce_transparent_index);
                    rpe_gif__capture_frame(state);
					var frame_delay = max(0.01, gce_delay);
                    array_add(state.delays, frame_delay);
                    state.total += frame_delay;

                    state.previous_disposal = gce_disposal;
                    state.previous_left = image_left;
                    state.previous_top = image_top;
                    state.previous_width = image_width;
                    state.previous_height = image_height;
                    gce_delay = 0;
                    gce_transparent = false;
                    gce_transparent_index = 0;
                    gce_disposal = 0;
                    break;

                default:
                    rpe_gif__fail("Unknown GIF block marker");
            }
        }

        if (array_length(state.frames) == 0) then rpe_gif__fail("GIF contains no image frames");
        var decoded = {
            frames: state.frames,
            delays: state.delays,
            total: state.total,
            width: state.width,
            height: state.height
        };
        rpe_gif__cleanup(state, false);
        return decoded;
    } catch (error) {
        show_debug_message($"[RPE GIF] {string(error)}");
        rpe_gif__cleanup(state, true);
        return undefined;
    }
}

/// @function rpe_gif_free(decoded)
/// @param {Struct} decoded
function rpe_gif_free(decoded) {
    if (!is_struct(decoded) || !struct_exists(decoded, "frames") || !is_array(decoded.frames)) then return;
    for (var i = 0; i < array_length(decoded.frames); i++) {
        if (sprite_exists(decoded.frames[i])) then sprite_delete(decoded.frames[i]);
    }
    decoded.frames = [];
    decoded.delays = [];
    decoded.total = 0;
}
