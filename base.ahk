; 拼接所有的ahk脚本的头部，做一些通用的设置
#SingleInstance Force ;跳过对话框，执行此脚本时默认覆盖原来的同名脚本，只允许当前脚本的一个实例存在
#Warn ;启用所有警告，并且把他们显示到消息框中
SendMode "Input" ; 让 Send 成为 SendInput 的代名词. 由于其卓越的速度和可靠性, 推荐在新脚本中使用.
SetWorkingDir A_ScriptDir ;设置脚本工作目录为当前脚本所在的目录。
