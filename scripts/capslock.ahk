; 定制CapsLock
; 设置大写锁定正常为一直关闭状态
SetCapsLockState "AlwaysOff"
; 使用capslock+esc切换大写锁定
; 废除capslock直接切换大小写锁定的功能
Capslock & Esc::{
    If GetKeyState("CapsLock", "T") = 1
        SetCapsLockState "AlwaysOff"
    Else 
        SetCapsLockState "AlwaysOn"
}
; toggle winAlwaysOnTop 实现窗口置顶 CapsLock+t
CapsLock & t::{
    WinSetAlwaysOnTop -1, "A"
}