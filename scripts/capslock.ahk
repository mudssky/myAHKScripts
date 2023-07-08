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

; 计算两点之间的距离
calcDistance(x1,y1,x2,y2){
    return ((x2-x1)**2 + (y2-y1)**2)**0.5
}

; 实现鼠标连点相关功能,启动连点后，鼠标出现位移则取消连点
isMouseClickOn:=false
mouseClickCount:=0
clickInterval:=50
CapsLock & c::{
    global isMouseClickOn,mouseClickCount,clickInterval
    isMouseClickOn :=true
    MouseGetPos &xpos, &ypos
    Loop{
        if isMouseClickOn{
            MouseClick("left")
            mouseClickCount++
            MouseGetPos &xpos2, &ypos2
            ; 连点超过十分钟自动停止
            if (mouseClickCount*clickInterval>1000*60*10){
                isMouseClickOn:=false
                break
            }
            if(calcDistance(xpos,ypos,xpos2,ypos2)>50){
                isMouseClickOn:=false
                break
            }
        }else{
            break
        }
        Sleep(clickInterval)
    }
    mouseClickCount:=0
}

resetMouseClick(){
    global isMouseClickOn,mouseClickCount
    isMouseClickOn:=false
    mouseClickCount:=0
    resetMousePosition()
}
; 重置鼠标位置到屏幕中心，用于多屏幕时寻找鼠标位置
resetMousePosition(){
    MouseMove(A_ScreenWidth/2, A_ScreenHeight/2)
}
; 重置鼠标连点
CapsLock & r::{
    resetMouseClick()
}

CapsLock & m::{
    resetMouseClick()
    global clickInterval
    wnhn := "W200 H100"
    timeInput := InputBox("鼠标点击的时间间隔(ms)", "默认为50ms" ,wnhn)

    if (timeInput.Result='Cancel'){
        return
    }else if (timeInput.Value <10){
        MsgBox('不能输入小于10的数')
        return
    }
    clickInterval:=timeInput.Value

}

; 设置指针大小
SPI_SETCURSORSIZE := 0x0071

; 指定所需的指针大小（例如，20）
desiredSize := 50

; 调用 SystemParametersInfo 函数
DllCall("SystemParametersInfo", "UInt", SPI_SETCURSORSIZE, "UInt", desiredSize, "Ptr", 0, "UInt", 0)