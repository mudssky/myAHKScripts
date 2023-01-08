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

; 切换窗口到 1280*720
CapsLock & w::{
    ; 输入框宽和高
    wnhn := "W200 H100"
    title := WinGetTitle("A")
    widthInput := InputBox("输入调整的宽度（像素）", "输入宽度" ,wnhn).value
    heightInput := InputBox("输入调整的高度（像素）", "输入高度" ,wnhn).value
    if ( widthInput && heightInput){
        WinMove , ,widthInput,heightInput, title
    }else {
        MsgBox "宽度或高度未设置"
    }
}
