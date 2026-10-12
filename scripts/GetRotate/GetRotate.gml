// v2.3.0 的脚本资产已更改，请参见
// https://help.yoyogames.com/hc/en-us/articles/360005277377
///@desc 求点绕中心旋转后的坐标
///@param {Real} X 点的横坐标
///@param {Real} Y 点的纵坐标
///@param {Real} CX 旋转中心横坐标
///@param {Real} CY 旋转中心纵坐标
///@param {Real} Rotate 旋转角度
///@returns {Array} 旋转后的横坐标和纵坐标
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


///@desc 求点绕中心旋转后的横坐标
///@param {Real} X 点的横坐标
///@param {Real} Y 点的纵坐标
///@param {Real} CX 旋转中心横坐标
///@param {Real} CY 旋转中心纵坐标
///@param {Real} Rotate 旋转角度
///@returns {Real} 旋转后的横坐标
function GetRotateX(X, Y, CX, CY, Rotate)
{
	return ((lengthdir_x((X - CX), Rotate) - lengthdir_y((Y - CY), Rotate)) + CX);
};

///@desc 求点绕中心旋转后的纵坐标
///@param {Real} X 点的横坐标
///@param {Real} Y 点的纵坐标
///@param {Real} CX 旋转中心横坐标
///@param {Real} CY 旋转中心纵坐标
///@param {Real} Rotate 旋转角度
///@returns {Real} 旋转后的纵坐标
function GetRotateY(X, Y, CX, CY, Rotate)
{
	return ((lengthdir_y((X - CX), Rotate) + lengthdir_x((Y - CY), Rotate)) + CY);
};