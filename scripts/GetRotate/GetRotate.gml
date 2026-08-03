// v2.3.0的脚本资产已更改，请参见\ n // https://help.yoyogames.com/hc/en-us/articles/360005277377
function GetRotate(X, Y, CX, CY, Rotate)
{
	return [ GetRotateX(X, Y, CX, CY, Rotate), GetRotateY(X, Y, CX, CY, Rotate) ];
};

//function GetRotate(X, Y, CX, CY, Rotate)
//{
//    var dx = X - CX;
//    var dy = Y - CY;
//    var cs = dcos(Rotate);
//    var sn = dsin(Rotate);

//    return [
//        CX + dx * cs - dy * sn,
//        CY + dx * sn + dy * cs
//    ];
//}


function GetRotateX(X, Y, CX, CY, Rotate)
{
	return ((lengthdir_x((X - CX), Rotate) - lengthdir_y((Y - CY), Rotate)) + CX);
};

function GetRotateY(X, Y, CX, CY, Rotate)
{
	return ((lengthdir_y((X - CX), Rotate) + lengthdir_x((Y - CY), Rotate)) + CY);
};