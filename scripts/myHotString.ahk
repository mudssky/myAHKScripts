
; 设置终止符
Hotstring("EndChars", "`n `t{^Pause}")
; 替换日期和时间
::rq:: {
    send FormatTime("R")
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