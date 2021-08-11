; 获取当前的时间戳精确到秒
GetCurrentTimeStamp(){
    ; unix时间戳的起始时间精确到秒
    startTime :='19700101000000'
    ; datediff 计算现在的utc时间到unix时间戳的起始时间经过的秒数
    return DateDiff(A_NowUTC,startTime,'Seconds')
}
; 设置终止符 空格,回车和tab
Hotstring("EndChars", "`n `t")
; 替换日期和时间
::rq:: {
    ; send FormatTime("R")
    send FormatTime(,"yyyy年M月d日 dddd HH:mm:ss")
}
; 日期 YYYYMMDDHH24MISS 格式，也就是19700101000000，这种全是数字的日期
::rqss:: {
    send A_Now 
}
; 输出当前时间戳（秒）热词
::sjc:: {
    send GetCurrentTimeStamp()
}
; 热字符串由终止符触发，包含下面几个
;  -()[]{}':;"/\,.?!`n `t
; 其中`n是回车 Enter
; `t 是Tab
; 上面`t前面其实还有一个空格，空格也是终止符

; TimeString := FormatTime()
; MsgBox "The current time and date (time first) is " TimeString

; TimeString := FormatTime("R")
; MsgBox "The current time and date (date first) is " TimeString

; TimeString := FormatTime(, "Time")
; MsgBox "The current time is " TimeString

; TimeString := FormatTime("T12", "Time")
; MsgBox "The current 24-hour time is " TimeString

; TimeString := FormatTime(, "LongDate")
; MsgBox "The current date (long format) is " TimeString

; TimeString := FormatTime(20050423220133, "dddd MMMM d, yyyy hh:mm:ss tt")
; MsgBox "The specified date and time, when formatted, is " TimeString

; MsgBox FormatTime(200504, "'Month Name': MMMM`n'Day Name': dddd")

; YearWeek := FormatTime(20050101, "YWeek")
; MsgBox "January 1st of 2005 is in the following ISO year and week number: " YearWeek