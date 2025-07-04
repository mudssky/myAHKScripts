#requires -version 5.0
<#
.SYNOPSIS
    AutoHotkey 脚本构建和部署工具

.DESCRIPTION
    将 scripts 目录下的所有 AutoHotkey 脚本合并为单个脚本文件，
    并可选择性地创建启动快捷方式以实现开机自启动。

.PARAMETER ScriptName
    输出的脚本文件名，默认为 'myAllScripts.ahk'

.PARAMETER StartUpFolder
    启动文件夹路径，如果不指定则使用用户启动目录

.PARAMETER ConcatNotInclude
    使用完整拼接模式而非 #include 模式

.PARAMETER UseUserStartup
    使用用户启动目录而非系统启动目录（推荐）

.PARAMETER Force
    强制覆盖现有文件

.PARAMETER NoAutoStart
    不自动启动生成的脚本

.PARAMETER Verbose
    显示详细输出信息

.EXAMPLE
    .\makeScripts.ps1
    使用默认设置构建脚本

.EXAMPLE
    .\makeScripts.ps1 -ScriptName "MyCustomScript.ahk" -UseUserStartup -Verbose
    自定义脚本名并使用用户启动目录
#>

param(
    [ValidatePattern('.*\.ahk$')]
    [string]$ScriptName = 'myAllScripts.ahk',
    
    [ValidateScript({Test-Path $_ -IsValid})]
    [string]$StartUpFolder,
    
    [switch]$ConcatNotInclude,
    [switch]$UseUserStartup = $true,
    [switch]$Force,
    [switch]$NoAutoStart,
    [switch]$Verbose
)
# ==================== 配置管理 ====================

# 加载配置文件
function Get-BuildConfiguration {
    param([string]$ConfigPath = "./build.config.json")
    
    try {
        if (Test-Path $ConfigPath) {
            $configContent = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
            $config = $configContent | ConvertFrom-Json
            Write-BuildLog "配置文件已加载: $ConfigPath" "Info"
            return $config
        } else {
            Write-BuildLog "配置文件不存在，使用默认设置: $ConfigPath" "Warning"
            return $null
        }
    }
    catch {
        Write-BuildLog "加载配置文件失败: $($_.Exception.Message)" "Error"
        return $null
    }
}

# 合并配置和参数
function Merge-Configuration {
    param(
        [object]$Config,
        [hashtable]$Parameters
    )
    
    if (-not $Config) {
        return $Parameters
    }
    
    # 从配置文件中读取默认值，如果参数未指定则使用配置文件的值
    $merged = @{}
    
    # 构建设置
    $merged.ScriptsPath = if ($Parameters.ContainsKey('ScriptsPath')) { $Parameters.ScriptsPath } else { $Config.build.scriptsPath }
    $merged.BasePath = if ($Parameters.ContainsKey('BasePath')) { $Parameters.BasePath } else { $Config.build.basePath }
    $merged.OutputPath = if ($Parameters.ContainsKey('OutputPath')) { $Parameters.OutputPath } else { $Config.build.outputPath }
    $merged.UseInclude = if ($Parameters.ContainsKey('ConcatNotInclude')) { -not $Parameters.ConcatNotInclude } else { $Config.build.useInclude }
    
    # 快捷方式设置
    $merged.CreateShortcut = if ($Parameters.ContainsKey('CreateShortcut')) { $Parameters.CreateShortcut } else { $Config.shortcuts.createShortcut }
    $merged.UseUserStartup = if ($Parameters.ContainsKey('UseUserStartup')) { $Parameters.UseUserStartup } else { $Config.shortcuts.useUserStartup }
    
    # 执行设置
    $merged.AutoStart = if ($Parameters.ContainsKey('NoAutoStart')) { -not $Parameters.NoAutoStart } else { $Config.execution.autoStart }
    $merged.Force = if ($Parameters.ContainsKey('Force')) { $Parameters.Force } else { $Config.execution.force }
    $merged.Verbose = if ($Parameters.ContainsKey('Verbose')) { $Parameters.Verbose } else { $Config.execution.verbose }
    
    return $merged
}

# ==================== 辅助函数 ====================

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 写入构建日志
function Write-BuildLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Verbose) {
        Add-Content -Path "build.log" -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    switch ($Level) {
        "Error" { 
            Write-Host "✗ $Message" -ForegroundColor Red
            Write-Error $Message
        }
        "Warning" { 
            Write-Host "⚠ $Message" -ForegroundColor Yellow
        }
        "Success" { 
            Write-Host "✓ $Message" -ForegroundColor Green
        }
        default { 
            if ($Verbose) {
                Write-Host "ℹ $Message" -ForegroundColor Cyan
            }
        }
    }
}

# 创建快捷方式
function New-Shortcut {
    param(
        [string]$TargetPath,
        [string]$SourcePath
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($TargetPath)
        $shortcut.TargetPath = $SourcePath
        $shortcut.WorkingDirectory = Split-Path $SourcePath -Parent
        $shortcut.Description = "AutoHotkey 自动启动脚本"
        $shortcut.Save()
        
        # 释放 COM 对象
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        Write-BuildLog "快捷方式创建成功: $TargetPath" "Success"
        return $true
    }
    catch {
        Write-BuildLog "创建快捷方式失败: $($_.Exception.Message)" "Error"
        return $false
    }
}

# 验证 AutoHotkey 安装
function Test-AutoHotkeyInstalled {
    $ahkCommand = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
    if ($ahkCommand) {
        try {
            $version = & $ahkCommand.Source "--version" 2>$null
            if ($version -match "v2\.") {
                Write-BuildLog "检测到 AutoHotkey 2.0: $version" "Success"
                return $true
            }
        }
        catch {
            # 忽略版本检查错误
        }
    }
    
    Write-BuildLog "未检测到 AutoHotkey 2.0，请先运行 install-autohotkey.ps1" "Warning"
    return $false
}

# 获取启动文件夹路径
function Get-StartupFolderPath {
    if ($StartUpFolder) {
        return $StartUpFolder
    }
    
    if ($UseUserStartup) {
        return "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    } else {
        # 检查是否有管理员权限
        if (-not (Test-Administrator)) {
            Write-BuildLog "写入系统启动目录需要管理员权限，切换到用户启动目录" "Warning"
            return "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        }
        return "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    }
}
# ==================== 主要构建逻辑 ====================

# 获取 AHK 脚本文件
function Get-AhkScripts {
    param([string]$ScriptsPath = "./Scripts")
    
    try {
        if (-not (Test-Path $ScriptsPath)) {
            Write-BuildLog "脚本目录不存在: $ScriptsPath" "Error"
            return @()
        }
        
        $scripts = Get-ChildItem -Recurse -Path $ScriptsPath -Filter "*.ahk" -ErrorAction Stop
        Write-BuildLog "找到 $($scripts.Count) 个 AHK 脚本文件" "Info"
        
        return $scripts
    }
    catch {
        Write-BuildLog "获取脚本文件失败: $($_.Exception.Message)" "Error"
        return @()
    }
}

# 构建脚本内容
function Build-AhkScript {
    param(
        [array]$Scripts,
        [bool]$UseInclude = $true
    )
    
    $includeString = ''
    $processedCount = 0
    
    foreach ($script in $Scripts) {
        try {
            $processedCount++
            
            if ($Verbose) {
                Write-Progress -Activity "构建 AHK 脚本" -Status "处理: $($script.Name)" -PercentComplete (($processedCount / $Scripts.Count) * 100)
            }
            
            if ($UseInclude) {
                # 使用 #include 模式
                $includeString += "#include `"$($script.FullName)`"`n"
                Write-BuildLog "添加包含: $($script.Name)" "Info"
            } else {
                # 使用完整拼接模式
                $ahkContent = Get-Content -Path $script.FullName -Raw -Encoding UTF8
                if ($ahkContent) {
                    $includeString += "; ==================== $($script.Name) ====================`n"
                    $includeString += $ahkContent + "`n`n"
                    Write-BuildLog "拼接内容: $($script.Name)" "Info"
                }
            }
        }
        catch {
            Write-BuildLog "处理脚本文件失败 $($script.Name): $($_.Exception.Message)" "Warning"
            continue
        }
    }
    
    if ($Verbose) {
        Write-Progress -Activity "构建 AHK 脚本" -Completed
    }
    
    return $includeString
}

# 主构建函数
function Invoke-ScriptBuild {
    Write-BuildLog "开始构建 AutoHotkey 脚本" "Info"
    
    # 检查 AutoHotkey 安装
    Test-AutoHotkeyInstalled | Out-Null
    
    # 检查输出文件是否存在
    if ((Test-Path $ScriptName) -and (-not $Force)) {
        $response = Read-Host "文件 '$ScriptName' 已存在，是否覆盖? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-BuildLog "构建已取消" "Warning"
            return $false
        }
    }
    
    # 获取脚本文件
    $scripts = Get-AhkScripts
    if ($scripts.Count -eq 0) {
        Write-BuildLog "未找到任何 AHK 脚本文件" "Error"
        return $false
    }
    
    # 读取基础脚本
    try {
        if (Test-Path ".\base.ahk") {
            $baseContent = Get-Content ".\base.ahk" -Raw -Encoding UTF8
            Write-BuildLog "加载基础脚本: base.ahk" "Info"
        } else {
            $baseContent = "; AutoHotkey 2.0 自动生成脚本`n; 生成时间: $(Get-Date)`n`n"
            Write-BuildLog "未找到 base.ahk，使用默认头部" "Warning"
        }
    }
    catch {
        Write-BuildLog "读取基础脚本失败: $($_.Exception.Message)" "Error"
        return $false
    }
    
    # 构建脚本内容
    $includeContent = Build-AhkScript -Scripts $scripts -UseInclude (-not $ConcatNotInclude)
    $finalContent = $baseContent + "`n" + $includeContent
    
    # 写入输出文件
    try {
        Out-File -InputObject $finalContent -Encoding UTF8 -FilePath $ScriptName -ErrorAction Stop
        Write-BuildLog "脚本构建成功: $ScriptName" "Success"
        return $true
    }
    catch {
        Write-BuildLog "写入输出文件失败: $($_.Exception.Message)" "Error"
        return $false
    }
} 

# ==================== 主执行逻辑 ====================

# 加载配置文件
$config = Get-BuildConfiguration

# 合并配置和命令行参数
$currentParams = @{
    ScriptName = $ScriptName
    ConcatNotInclude = $ConcatNotInclude
    CreateShortcut = $CreateShortcut
    UseUserStartup = $UseUserStartup
    Force = $Force
    NoAutoStart = $NoAutoStart
    Verbose = $Verbose
}

$mergedConfig = Merge-Configuration -Config $config -Parameters $currentParams

# 应用合并后的配置
if ($config) {
    $script:ScriptName = $mergedConfig.OutputPath
    $script:ConcatNotInclude = -not $mergedConfig.UseInclude
    $script:CreateShortcut = $mergedConfig.CreateShortcut
    $script:UseUserStartup = $mergedConfig.UseUserStartup
    $script:Force = $mergedConfig.Force
    $script:NoAutoStart = -not $mergedConfig.AutoStart
    $script:Verbose = $mergedConfig.Verbose
}

try {
    Write-BuildLog "=== AutoHotkey 脚本构建工具 ===" "Info"
    Write-BuildLog "输出文件: $ScriptName" "Info"
    Write-BuildLog "使用包含模式: $(-not $ConcatNotInclude)" "Info"
    
    # 执行构建
    $buildSuccess = Invoke-ScriptBuild
    
    if (-not $buildSuccess) {
        Write-BuildLog "脚本构建失败，退出" "Error"
        exit 1
    }
    
    # 获取启动文件夹路径
    $startupPath = Get-StartupFolderPath
    if (-not $startupPath) {
        Write-BuildLog "无法确定启动文件夹路径" "Error"
        exit 1
    }
    
    # 创建快捷方式
     if ($CreateShortcut) {
         $linkName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName) + ".lnk"
         $linkPath = Join-Path -Path $startupPath -ChildPath $linkName
         
         if ((Test-Path -Path $linkPath) -and (-not $Force)) {
             Write-BuildLog "快捷方式已存在: $linkPath" "Info"
         } else {
             $shortcutSuccess = New-Shortcut -LinkPath $linkPath -TargetPath (Resolve-Path $ScriptName).Path
             
             if ($shortcutSuccess) {
                 Write-BuildLog "快捷方式已创建: $linkPath" "Success"
             } else {
                 Write-BuildLog "快捷方式创建失败" "Warning"
             }
         }
     }
    
    # 自动启动脚本
    if (-not $NoAutoStart) {
        try {
            Write-BuildLog "启动 AutoHotkey 脚本..." "Info"
            Start-Process -FilePath $ScriptName -ErrorAction Stop
            Write-BuildLog "脚本已启动: $ScriptName" "Success"
        }
        catch {
            Write-BuildLog "启动脚本失败: $($_.Exception.Message)" "Error"
        }
    }
    
    Write-BuildLog "所有操作完成" "Success"
}
catch {
    Write-BuildLog "执行过程中发生错误: $($_.Exception.Message)" "Error"
    exit 1
}
finally {
    # 清理临时文件或资源
    if ($Verbose) {
        Write-BuildLog "清理完成" "Info"
    }
}