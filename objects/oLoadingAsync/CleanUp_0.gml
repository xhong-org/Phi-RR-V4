if (font_exists(ui_font)) then font_delete(ui_font);
if (variable_global_exists("chart_session") && is_struct(global.chart_session)
        && variable_struct_exists(global.chart_session, "zip_task")
        && global.chart_session.zip_task >= 0) {
        var task_id = global.chart_session.zip_task;
        if (unicode_zip_task_pending(task_id)) then unicode_zip_task_cancel(task_id);
        else unicode_zip_task_release(task_id);
        global.chart_session.zip_task = -1;
};
