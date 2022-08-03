

; 批量关闭程序的函数，传入进程名或者pid数字
processArrClose(processArr){
	For processName in processArr
	if (PID := ProcessExist(processName)){
		ProcessClose(PID)
	}
}

; 下班时，按win+l 批量关闭程序
#l::{
	; 下班应该关闭的程序
	offDuttiesCloseProcessArr:= ["foobar2000.exe","QQMusic.exe"]
	processArrClose(offDuttiesCloseProcessArr)
}
