/// @desc I_AndroidFiles GML helpers. Native functions live in the I_AndroidFiles extension.

function android_files_available() {
	return (os_type == os_android);
}

function android_files_logs_dir() {
	if (!android_files_available()) then return "";
	return i_android_files_logs_dir();
}

function android_files_external_dir() {
	if (!android_files_available()) then return "";
	return i_android_files_external_dir();
}

function android_files_internal_dir() {
	if (!android_files_available()) then return "";
	return i_android_files_internal_dir();
}

function android_files_mkdir(path) {
	if (!android_files_available()) then return false;
	return i_android_files_mkdir(path);
}

function android_files_exists(path) {
	if (!android_files_available()) then return file_exists(path);
	return i_android_files_exists(path);
}

function android_files_is_dir(path) {
	if (!android_files_available()) then return directory_exists(path);
	return i_android_files_is_dir(path);
}

function android_files_list(path) {
	if (!android_files_available()) then return "";
	return i_android_files_list(path);
}

function android_files_write_text(path, text) {
	if (!android_files_available()) then return false;
	return i_android_files_write_text(path, text);
}

function android_files_append_text(path, text) {
	if (!android_files_available()) then return false;
	return i_android_files_append_text(path, text);
}

function android_files_read_text(path) {
	if (!android_files_available()) then return "";
	return i_android_files_read_text(path);
}

function android_files_copy(source_path, dest_path) {
	if (!android_files_available()) then return false;
	return i_android_files_copy(source_path, dest_path);
}

function android_files_delete(path) {
	if (!android_files_available()) then return false;
	return i_android_files_delete(path);
}

function android_files_size(path) {
	if (!android_files_available()) {
		if (!file_exists(path)) then return -1;
		var bin = file_bin_open(path, 0);
		if (bin < 0) then return -1;
		var bytes = file_bin_size(bin);
		file_bin_close(bin);
		return bytes;
	};
	return i_android_files_size(path);
}

function android_files_buffer_span(buf, offset, size) {
	if (!buffer_exists(buf)) then return undefined;
	var buf_size = buffer_get_size(buf);
	var start = max(0, offset);
	var count = size;
	if (count < 0) then count = buf_size - start;
	if (start > buf_size) then return undefined;
	if (start + count > buf_size) then count = buf_size - start;
	if (count < 0) then count = 0;
	return { offset: start, size: count };
}

function android_files_write_buffer(path, buf, offset = 0, size = -1) {
	var span = android_files_buffer_span(buf, offset, size);
	if (!is_struct(span)) then return false;
	if (!android_files_available()) {
		buffer_save_ext(buf, path, span.offset, span.size);
		return file_exists(path);
	};
	var encoded = (span.size <= 0) ? "" : buffer_base64_encode(buf, span.offset, span.size);
	return i_android_files_write_base64(path, encoded);
}

function android_files_append_buffer(path, buf, offset = 0, size = -1) {
	var span = android_files_buffer_span(buf, offset, size);
	if (!is_struct(span)) then return false;
	if (!android_files_available()) {
		if (!file_exists(path)) {
			buffer_save_ext(buf, path, span.offset, span.size);
			return file_exists(path);
		};
		var existing = buffer_load(path);
		if (existing < 0) then return false;
		var dest = buffer_get_size(existing);
		buffer_resize(existing, dest + span.size);
		if (span.size > 0) then buffer_copy(buf, span.offset, span.size, existing, dest);
		buffer_save(existing, path);
		buffer_delete(existing);
		return file_exists(path);
	};
	var encoded = (span.size <= 0) ? "" : buffer_base64_encode(buf, span.offset, span.size);
	return i_android_files_append_base64(path, encoded);
}

function android_files_read_buffer(path, src_offset = 0, size = -1) {
	if (!android_files_available()) {
		if (!file_exists(path)) then return -1;
		var loaded = buffer_load(path);
		if (loaded < 0) then return -1;
		if (src_offset <= 0 && size < 0) then return loaded;
		var loaded_size = buffer_get_size(loaded);
		var start = max(0, src_offset);
		if (start > loaded_size) then start = loaded_size;
		var count = size;
		if (count < 0) then count = loaded_size - start;
		if (start + count > loaded_size) then count = loaded_size - start;
		if (count < 0) then count = 0;
		var sliced = buffer_create(count, buffer_grow, 1);
		if (count > 0) then buffer_copy(loaded, start, count, sliced, 0);
		buffer_delete(loaded);
		return sliced;
	};
	var encoded = i_android_files_read_base64_range(path, src_offset, size);
	if (!string_length(encoded)) {
		if (string_length(i_android_files_error())) then return -1;
		return buffer_create(0, buffer_grow, 1);
	};
	return buffer_base64_decode(encoded);
}

function android_files_read_buffer_into(path, buf, dest_offset = 0, src_offset = 0, size = -1) {
	if (!buffer_exists(buf)) then return -1;
	var temp = android_files_read_buffer(path, src_offset, size);
	if (temp < 0) then return -1;
	var count = buffer_get_size(temp);
	var dest = max(0, dest_offset);
	if (buffer_get_size(buf) < dest + count) then buffer_resize(buf, dest + count);
	if (count > 0) then buffer_copy(temp, 0, count, buf, dest);
	buffer_delete(temp);
	return count;
}

function android_files_error() {
	if (!android_files_available()) then return "";
	return i_android_files_error();
}
