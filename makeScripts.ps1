#requires -version 5.0
#requires –runasadministrator
# 顶部设置需求管理员权限
param(
    [string]$scriptName = 'myAllScripts.ahk',
    # 当前用户快速启动文件夹的位置
    # [string]$startUpFolder = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    # 所有用户通用的快速启动目录
    [string]$startUpFolder = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp",
    [switch]$concatNotInclude
)
function new-lnk($targetPath, $sourcePath) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($targetPath)
    $shortcut.TargetPath = $sourcePath
    $shortcut.Save()
}
$includString = ''
# 递归查找scrpts目录下的所有ahk脚本，合成为一个脚本
Get-ChildItem -Recurse -Path   ./Scripts *.ahk | ForEach-Object {
    if ($concatNotInclude) {
        # -raw获取原始字符串，这样就不会破坏换行符了。
        $ahkStr = Get-Content -Path $_.FullName -Raw
        $includString += $ahkStr + "`n"
    }
    else {
        
        # powershell里面要把换行符解释成换行符
        $includString += "#include  {0} `n" -f $_.FullName
    }
}

$baseStr = Get-Content .\base.ahk

$finalAHK = $baseStr + $includString

Out-File -InputObject $finalAHK -Encoding utf8 -FilePath $scriptName 

$linkPath = Join-Path -Path $startUpFolder -ChildPath $scriptName.Replace('.ahk', '.lnk')

# 如果还没有加入快捷方式到快速启动，就创建一次快捷方式，实现快速启动
if (-not (Test-Path -Path $linkPath)) {
    # New-Item -ItemType SymbolicLink -Path $startUpFolder -Name $scriptName  -Value $scriptName
    new-lnk -targetPath $linkPath -sourcePath (Join-Path -Path (Get-Location) -ChildPath $scriptName)
    Write-Host -ForegroundColor Green ('write  item: {0} to folder {1},link name:{2}' -f $path, $startUpFolder, $scriptName)
}

# 执行一次脚本
Start-Process -FilePath $scriptName