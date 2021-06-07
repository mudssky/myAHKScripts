
- [myAHKScripts](#myahkscripts)
  - [安装](#安装)
  - [01. capslock.ahk](#01-capslockahk)
  - [02.switchIME.ahk](#02switchimeahk)

# myAHKScripts
存放自己编写的autohotkey脚本，全部基于v2版本的语法。
脚本统一存放在scripts目录

## 安装
makeScripts是powershell脚本，用于把scripts目录里面的所有脚本和base.ahk拼接成一个并且在startup目录创建快捷方式，然后再执行一遍最终生成的ahk脚本。

注意先确认powershell的执行权限，还有autohotkey v2是否正确安装再执行。
**可能会需要管理员权限才能执行**。

默认会采用include的方式进行拼接，有一个 `-concatNotInclude`参数，如果传递给脚本
最后生成的ahk文件就是完整拼接的了。
## 01. capslock.ahk
定制capslock键作为修饰键
使用了官方提供的代码，完全禁用capslock键并且排除IME带来的干扰，使用capslock+esc代替capslock原来的功能。

|快捷键|功能|
|---|---|
|Capslock+t|窗口置顶toggle|
|Capslock+esc|大写锁定切换|

## 02.switchIME.ahk
提供自动切换输入法的功能。
在你使用vscode或者windows terminal之类的应用时会把你的输入法切换成英文输入法

|快捷键|功能|
|---|---|
|Capslock+1|切换为微软拼音输入法|
|Capslock+2|切换为微软英文键盘|
|Capslock+3|切换为微软日文输入法|


