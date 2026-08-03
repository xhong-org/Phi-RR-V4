/// @function grid_to_struct_array(grid)
function ds_grid_to_struct_array(grid) {
    var rows = (ds_grid_height(grid));
    var cols = (ds_grid_width(grid));

    // 读取第一行作为列名
    var columns = [];
    for (var xx = 0; xx < cols; xx ++) {
        array_add(columns, string(ds_grid_get(grid, xx, 0)));
    };

    var objectArray = [];

    
    for (var yy = 1; yy < rows; yy ++) {
        var rowStruct = {};
        for (var xx = 0; xx < cols; xx ++) {
            var key = (columns[xx]),
				val = (ds_grid_get(grid, xx, yy));
			
            rowStruct[$ key] = val;
           
        };
        array_add(objectArray, rowStruct);
    };

    return (objectArray);
};