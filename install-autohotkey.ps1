# AutoHotkey 2.0 自动安装脚本
# 此脚本将自动下载并安装最新版本的 AutoHotkey 2.0

param(
    [switch]$Force,
    [switch]$Silent
)

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 获取最新版本信息
function Get-LatestAHKVersion {
    try {
        Write-Host "正在获取 AutoHotkey 2.0 最新版本信息..." -ForegroundColor Yellow
        $apiUrl = "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        
        # 查找 .exe 安装包
        $asset = $response.assets | Where-Object { $_.name -like "*_setup.exe" -and $_.name -notlike "*_x64_setup.exe" }
        
        if ($asset) {
            return @{
                Version = $response.tag_name
                DownloadUrl = $asset.browser_download_url
                FileName = $asset.name
            }
        } else {
            throw "未找到合适的安装包"
        }
    }
    catch {
        Write-Error "获取版本信息失败: $($_.Exception.Message)"
        return $null
    }
}

# 检查是否已安装 AutoHotkey
function Test-AHKInstalled {
    $ahkPath = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
    if ($ahkPath) {
        try {
            $version = & $ahkPath.Source "--version" 2>$null
            if ($version -match "v2\.") {
                Write-Host "检测到已安装 AutoHotkey 2.0: $version" -ForegroundColor Green
                return $true
            }
        }
        catch {
            # 忽略版本检查错误
        }
    }
    
    # 检查注册表
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($regPath in $regPaths) {
        $installed = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | 
                    Where-Object { $_.DisplayName -like "*AutoHotkey*" -and $_.DisplayVersion -like "2.*" }
        if ($installed) {
            Write-Host "检测到已安装 AutoHotkey 2.0: $($installed.DisplayVersion)" -ForegroundColor Green
            return $true
        }
    }
    
    return $false
}

# 下载文件
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Host "正在下载: $Url" -ForegroundColor Yellow
        
        # 使用 WebClient 下载并显示进度
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        
        Write-Host "下载完成: $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "下载失败: $($_.Exception.Message)"
        return $false
    }
}

# 安装 AutoHotkey
function Install-AutoHotkey {
    param(
        [string]$InstallerPath,
        [bool]$Silent
    )
    
    try {
        Write-Host "正在安装 AutoHotkey 2.0..." -ForegroundColor Yellow
        
        $arguments = if ($Silent) { "/S" } else { "" }
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "AutoHotkey 2.0 安装成功!" -ForegroundColor Green
            return $true
        } else {
            Write-Error "安装失败，退出代码: $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Error "安装过程中发生错误: $($_.Exception.Message)"
        return $false
    }
}

# 主函数
function Main {
    Write-Host "=== AutoHotkey 2.0 自动安装脚本 ===" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-Warning "建议以管理员身份运行此脚本以确保正确安装"
        if (-not $Force) {
            $response = Read-Host "是否继续? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "安装已取消" -ForegroundColor Yellow
                return
            }
        }
    }
    
    # 检查是否已安装
    if ((Test-AHKInstalled) -and (-not $Force)) {
        Write-Host "AutoHotkey 2.0 已安装，使用 -Force 参数强制重新安装" -ForegroundColor Yellow
        return
    }
    
    # 获取最新版本
    $versionInfo = Get-LatestAHKVersion
    if (-not $versionInfo) {
        Write-Error "无法获取版本信息，安装终止"
        return
    }
    
    Write-Host "最新版本: $($versionInfo.Version)" -ForegroundColor Green
    Write-Host "下载地址: $($versionInfo.DownloadUrl)" -ForegroundColor Gray
    
    # 创建临时目录
    $tempDir = Join-Path $env:TEMP "AHK_Install"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    $installerPath = Join-Path $tempDir $versionInfo.FileName
    
    # 下载安装包
    if (-not (Download-File -Url $versionInfo.DownloadUrl -OutputPath $installerPath)) {
        Write-Error "下载失败，安装终止"
        return
    }
    
    # 安装
    if (Install-AutoHotkey -InstallerPath $installerPath -Silent $Silent) {
        Write-Host ""
        Write-Host "=== 安装完成 ===" -ForegroundColor Green
        Write-Host "请重新启动 PowerShell 或命令提示符以使用 AutoHotkey 命令" -ForegroundColor Yellow
        
        # 验证安装
        Start-Sleep -Seconds 2
        if (Test-AHKInstalled) {
            Write-Host "✓ 安装验证成功" -ForegroundColor Green
        } else {
            Write-Warning "安装验证失败，请手动检查安装状态"
        }
    }
    
    # 清理临时文件
    try {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Host "临时文件已清理" -ForegroundColor Gray
    }
    catch {
        Write-Warning "清理临时文件失败: $($_.Exception.Message)"
    }
}

# 执行主函数
Main

Write-Host ""
Write-Host "脚本执行完成，按任意键退出..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")