
- [myAHKScripts](#myahkscripts)
  - [安装](#安装)
  - [01. capslock.ahk](#01-capslockahk)
  - [02.switchIME.ahk](#02switchimeahk)
  - [03.win.ahk](#03winahk)
  - [04.鼠标连点器](#04鼠标连点器)

# myAHKScripts

存放自己编写的autohotkey脚本，全部基于v2版本的语法。
脚本统一存放在scripts目录

## 安装

### 1. 安装 AutoHotkey 2.0

项目提供了自动安装脚本 `install-autohotkey.ps1`，可以自动下载并安装最新版本的 AutoHotkey 2.0：

```powershell
# 以管理员身份运行 PowerShell，然后执行：
.\install-autohotkey.ps1

# 静默安装（无用户交互）
.\install-autohotkey.ps1 -Silent

# 强制重新安装（即使已安装）
.\install-autohotkey.ps1 -Force
```

**注意事项：**
- 建议以管理员身份运行 PowerShell
- 确保 PowerShell 执行策略允许运行脚本
- 脚本会自动从 GitHub 下载最新版本
- 安装完成后需要重启终端以使用 AutoHotkey 命令

### 2. 部署脚本

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

需要把默认输入法调成微软拼音，进入特定的几个app比如vscode 或者windows terminal 就会用shift切换到英文模式，离开这些app的时候就会切换回中文模式。

|快捷键|功能|
|---|---|
|Capslock+1|切换为微软拼音输入法|
|Capslock+2|切换为微软英文键盘|
|Capslock+3|切换为微软日文输入法|

## 03.win.ahk

win相关的快捷键
定义`win+l`热键用于下班时，一键关闭一些应用程序
在数组中放入进程名即可

```ahk
offDuttiesCloseProcessArr:= ["foobar2000.exe","QQMusic.exe"]
```

## 04.鼠标连点器

| 快捷键     | 功能                                                         |
| ---------- | ------------------------------------------------------------ |
| Capslock+c | 连续点击，超过10分钟或者鼠标位移大于50停止                   |
| Capslock+r | 停止点击，重置计数器,重置鼠标指针到屏幕中心（多屏幕的时候找不到鼠标指针时好用） |
| CapsLock+m | 输入点击的时间间隔                                           |
