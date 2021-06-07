; 定制CapsLock
; 必须安装键盘钩子，官方提供的限制IME使得Capslock不会被触发可以正常映射的方法
InstallKeybdHook
SendSuppressedKeyUp(key) {
    DllCall("keybd_event"
        , "char", GetKeyVK(key)
        , "char", GetKeySC(key)
        , "uint", KEYEVENTF_KEYUP := 0x2
    , "uptr", KEY_BLOCK_THIS := 0xFFC3D450)
}
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
