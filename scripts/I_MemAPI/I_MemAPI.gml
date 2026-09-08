/// @desc Windows working-set trim. Pages this process no longer needs go back to the OS.

function i_mem_native_ready() {
	return (os_type == os_windows) && extension_exists("I_Mem");
}

function process_mem_mb(bytes) {
	return string_format(max(0, real(bytes)) / (1024 * 1024), 1, 1);
}

/// Compact heaps and drop unused working-set pages for this process only.
function process_mem_trim() {
	if (!i_mem_native_ready()) then return false;
	try { gc_collect(); } catch (gc_err) { delete(gc_err); };
	var before = i_mem_working_set();
	var ok = i_mem_trim() != 0;
	var after = i_mem_working_set();
	print($"[Mem] trim working-set {process_mem_mb(before)}MB -> {process_mem_mb(after)}MB");
	return ok;
}

function process_mem_trim_later() {
	global.process_mem_trim_pending = true;
}

function process_mem_trim_pending() {
	if (!variable_global_exists("process_mem_trim_pending") || !global.process_mem_trim_pending) then return false;
	global.process_mem_trim_pending = false;
	return process_mem_trim();
}
