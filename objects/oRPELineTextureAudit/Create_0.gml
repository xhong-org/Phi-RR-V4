/// @description Wait for RPE lines, then audit custom texture loading once.
persistent = true;
wait_frames = 0;
audit_complete = false;
test_mode = variable_global_exists("pls_archive_test") && global.pls_archive_test;
exit_test_mode = variable_global_exists("pls_exit_test") && global.pls_exit_test;
print($"[RPETextureAudit] Created testMode={test_mode}");
