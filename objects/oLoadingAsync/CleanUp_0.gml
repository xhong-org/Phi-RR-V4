// 清理：释放界面字体，并取消或释放未完成的解压任务
pls_ui_font_release_instance();
if (variable_global_exists("chart_session") && is_struct(global.chart_session)
        && variable_struct_exists(global.chart_session, "zip_task")
        && global.chart_session.zip_task >= 0) {
        var task_id = global.chart_session.zip_task;
        // 还在跑就取消，否则只释放句柄。
        if (unicode_zip_task_pending(task_id)) then unicode_zip_backend_task_cancel(task_id);
        else unicode_zip_backend_task_release(task_id);
        global.chart_session.zip_task = -1;
};
