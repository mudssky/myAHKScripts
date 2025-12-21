#requires -version 5.0
<#
.SYNOPSIS
    AutoHotkey script build and deployment tool

.DESCRIPTION
    Merges all AutoHotkey scripts in the scripts directory into a single script file,
    and optionally creates a startup shortcut for auto-start.

.PARAMETER ScriptName
    Output script filename, default is 'myAllScripts.ahk'

.PARAMETER StartUpFolder
    Startup folder path, uses user startup directory if not specified

.PARAMETER ConcatNotInclude
    Use full concatenation mode instead of #include mode

.PARAMETER UseUserStartup
    Use user startup directory instead of system startup directory (Recommended)

.PARAMETER Force
    Force overwrite existing files

.PARAMETER NoAutoStart
    Do not automatically start the generated script

.PARAMETER Verbose
    Show detailed output information

.EXAMPLE
    .\makeScripts.ps1
    Build script using default settings

.EXAMPLE
    .\makeScripts.ps1 -ScriptName "MyCustomScript.ahk" -UseUserStartup -Verbose
    Custom script name and use user startup directory
#>

param(
    [ValidatePattern('.*\.ahk$')]
    [string]$ScriptName = 'myAllScripts.ahk',
    
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$StartUpFolder,
    
    [switch]$ConcatNotInclude,
    [switch]$UseUserStartup = $true,
    [switch]$Force,
    [switch]$NoAutoStart,
    [switch]$Verbose
)
# ==================== Configuration Management ====================

# Load Configuration
function Get-BuildConfiguration {
    param(
        [string]$ConfigPath = "./build.config.json",
        [string]$LocalConfigPath = "./build.config.local.json"
    )
    
    try {
        $finalConfig = $null
        
        # Load Base Configuration
        if (Test-Path $ConfigPath) {
            $configContent = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
            $finalConfig = $configContent | ConvertFrom-Json
            Write-BuildLog "Base configuration loaded: $ConfigPath" "Info"
        }
        
        # Load Local Configuration (Priority)
        if (Test-Path $LocalConfigPath) {
            $localContent = Get-Content -Path $LocalConfigPath -Raw -Encoding UTF8
            $localConfig = $localContent | ConvertFrom-Json
            Write-BuildLog "Local configuration loaded: $LocalConfigPath (Priority)" "Info"
            
            if ($null -eq $finalConfig) {
                $finalConfig = $localConfig
            }
            else {
                # Merge local config into base config
                foreach ($section in $localConfig.PSObject.Properties) {
                    $sectionName = $section.Name
                    if ($null -eq $finalConfig.$sectionName) {
                        $finalConfig | Add-Member -MemberType NoteProperty -Name $sectionName -Value $section.Value
                    }
                    else {
                        # Deep merge for sections (build, shortcuts, etc.)
                        foreach ($prop in $section.Value.PSObject.Properties) {
                            $propName = $prop.Name
                            $finalConfig.$sectionName.$propName = $prop.Value
                        }
                    }
                }
            }
        }
        
        if ($null -eq $finalConfig) {
            Write-BuildLog "No configuration found, using internal defaults" "Warning"
        }
        
        return $finalConfig
    }
    catch {
        Write-BuildLog "Failed to load configuration: $($_.Exception.Message)" "Error"
        return $null
    }
}

# Merge Configuration and Parameters
function Merge-Configuration {
    param(
        [object]$Config,
        [hashtable]$Parameters
    )
    
    if (-not $Config) {
        return $Parameters
    }
    
    # Read defaults from config, use parameter if specified
    $merged = @{}
    
    # Build Settings
    $merged.ScriptsPath = if ($Parameters.ContainsKey('ScriptsPath')) { $Parameters.ScriptsPath } else { $Config.build.scriptsPath }
    $merged.BasePath = if ($Parameters.ContainsKey('BasePath')) { $Parameters.BasePath } else { $Config.build.basePath }
    $merged.OutputPath = if ($Parameters.ContainsKey('OutputPath')) { $Parameters.OutputPath } else { $Config.build.outputPath }
    $merged.UseInclude = if ($Parameters.ContainsKey('ConcatNotInclude')) { -not $Parameters.ConcatNotInclude } else { $Config.build.useInclude }
    $merged.Exclude = if ($Parameters.ContainsKey('Exclude')) { $Parameters.Exclude } else { $Config.build.exclude }
    
    # Shortcut Settings
    $merged.CreateShortcut = if ($Parameters.ContainsKey('CreateShortcut')) { $Parameters.CreateShortcut } else { $Config.shortcuts.createShortcut }
    $merged.UseUserStartup = if ($Parameters.ContainsKey('UseUserStartup')) { $Parameters.UseUserStartup } else { $Config.shortcuts.useUserStartup }
    
    # Execution Settings
    $merged.AutoStart = if ($Parameters.ContainsKey('NoAutoStart')) { -not $Parameters.NoAutoStart } else { $Config.execution.autoStart }
    $merged.Force = if ($Parameters.ContainsKey('Force')) { $Parameters.Force } else { $Config.execution.force }
    $merged.Verbose = if ($Parameters.ContainsKey('Verbose')) { $Parameters.Verbose } else { $Config.execution.verbose }
    
    return $merged
}

# ==================== Helper Functions ====================

# Check Administrator Privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Write Build Log
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
            Write-Host "X $Message" -ForegroundColor Red
            Write-Error $Message
        }
        "Warning" { 
            Write-Host "! $Message" -ForegroundColor Yellow
        }
        "Success" { 
            Write-Host "V $Message" -ForegroundColor Green
        }
        default { 
            if ($Verbose) {
                Write-Host "i $Message" -ForegroundColor Cyan
            }
        }
    }
}

# Create Shortcut
function New-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.WorkingDirectory = Split-Path $TargetPath -Parent
        $shortcut.Description = "AutoHotkey Auto-Start Script"
        $shortcut.Save()
        
        # Release COM Object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        Write-BuildLog "Shortcut created: $ShortcutPath" "Success"
        return $true
    }
    catch {
        Write-BuildLog "Failed to create shortcut: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Verify AutoHotkey Installation
function Test-AutoHotkeyInstalled {
    $commonPaths = @(
        "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe",
        "C:\Program Files\AutoHotkey\AutoHotkey.exe",
        "C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe"
    )
    
    # Check PATH first
    $ahkCommand = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
    if ($ahkCommand) {
        try {
            $version = & $ahkCommand.Source "--version" 2>$null
            if ($version -match "v2\.") {
                Write-BuildLog "AutoHotkey 2.0 detected (PATH): $version" "Success"
                return $true
            }
        }
        catch { }
    }

    # Check common paths
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-BuildLog "AutoHotkey detected at: $path" "Success"
            return $true
        }
    }
    
    # Check Registry
    try {
        $installDir = Get-ItemProperty -Path "HKLM:\SOFTWARE\AutoHotkey" -Name "InstallDir" -ErrorAction SilentlyContinue
        if ($installDir -and (Test-Path $installDir.InstallDir)) {
            Write-BuildLog "AutoHotkey detected via Registry: $($installDir.InstallDir)" "Success"
            return $true
        }
    }
    catch { }

    Write-BuildLog "AutoHotkey 2.0 not detected. Please run install-autohotkey.ps1 first" "Warning"
    return $false
}

# Get Startup Folder Path
function Get-StartupFolderPath {
    if ($StartUpFolder) {
        return $StartUpFolder
    }
    
    if ($UseUserStartup) {
        return "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    }
    else {
        # Check for admin privileges
        if (-not (Test-Administrator)) {
            Write-BuildLog "Admin privileges required for system startup. Switching to user startup." "Warning"
            return "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        }
        return "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    }
}
# ==================== Main Build Logic ====================

# Get AHK Scripts
function Get-AhkScripts {
    param(
        [string]$ScriptsPath = "./Scripts",
        [array]$ExcludeList = @()
    )
    
    try {
        if (-not (Test-Path $ScriptsPath)) {
            Write-BuildLog "Scripts directory not found: $ScriptsPath" "Error"
            return @()
        }
        
        $scripts = Get-ChildItem -Recurse -Path $ScriptsPath -Filter "*.ahk" -ErrorAction Stop | 
            Where-Object { $ExcludeList -notcontains $_.Name } |
            Sort-Object Name
                   
        Write-BuildLog "Found $($scripts.Count) AHK script files (Excluded: $($ExcludeList -join ', '))" "Info"
        
        return $scripts
    }
    catch {
        Write-BuildLog "Failed to get script files: $($_.Exception.Message)" "Error"
        return @()
    }
}

# Build Script Content
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
                Write-Progress -Activity "Building AHK Script" -Status "Processing: $($script.Name)" -PercentComplete (($processedCount / $Scripts.Count) * 100)
            }
            
            if ($UseInclude) {
                # Use #include mode
                $includeString += "#include `"$($script.FullName)`"`n"
                Write-BuildLog "Added include: $($script.Name)" "Info"
            }
            else {
                # Use concatenation mode
                $ahkContent = Get-Content -Path $script.FullName -Raw -Encoding UTF8
                if ($ahkContent) {
                    $includeString += "; ==================== $($script.Name) ====================`n"
                    $includeString += $ahkContent + "`n`n"
                    Write-BuildLog "Concatenated content: $($script.Name)" "Info"
                }
            }
        }
        catch {
            Write-BuildLog "Failed to process script file $($script.Name): $($_.Exception.Message)" "Warning"
            continue
        }
    }
    
    if ($Verbose) {
        Write-Progress -Activity "Building AHK Script" -Completed
    }
    
    return $includeString
}

# Invoke Script Build
function Invoke-ScriptBuild {
    param(
        [string]$OutputName,
        [bool]$Force,
        [bool]$UseInclude,
        [array]$ExcludeList = @()
    )

    Write-BuildLog "Starting AutoHotkey Script Build" "Info"
    
    # Check AutoHotkey Installation
    Test-AutoHotkeyInstalled | Out-Null
    
    # Check if output file exists
    # Overwrite by default, skipping prompt
    if (Test-Path $OutputName) {
        Write-BuildLog "File '$OutputName' already exists. Overwriting..." "Info"
    }
    
    # Get Script Files
    $scripts = Get-AhkScripts -ExcludeList $ExcludeList
    if ($scripts.Count -eq 0) {
        Write-BuildLog "No AHK script files found" "Error"
        return $false
    }
    
    # Read Base Script
    try {
        if (Test-Path ".\base.ahk") {
            $baseContent = Get-Content ".\base.ahk" -Raw -Encoding UTF8
            Write-BuildLog "Loaded base script: base.ahk" "Info"
        }
        else {
            $baseContent = "; AutoHotkey 2.0 Auto-Generated Script`n; Generated at: $(Get-Date)`n`n"
            Write-BuildLog "base.ahk not found, using default header" "Warning"
        }
    }
    catch {
        Write-BuildLog "Failed to read base script: $($_.Exception.Message)" "Error"
        return $false
    }
    
    # Build Script Content
    $includeContent = Build-AhkScript -Scripts $scripts -UseInclude $UseInclude
    $finalContent = $baseContent + "`n" + $includeContent
    
    # Write Output File
    try {
        Out-File -InputObject $finalContent -Encoding UTF8 -FilePath $OutputName -ErrorAction Stop
        Write-BuildLog "Script built successfully: $OutputName" "Success"
        return $true
    }
    catch {
        Write-BuildLog "Failed to write output file: $($_.Exception.Message)" "Error"
        return $false
    }
} 

# ==================== Main Execution Logic ====================

# Load Configuration
$config = Get-BuildConfiguration

# Merge Configuration and Parameters
$currentParams = @{}
foreach ($key in $PSBoundParameters.Keys) {
    $currentParams[$key] = $PSBoundParameters[$key]
}

$mergedConfig = Merge-Configuration -Config $config -Parameters $currentParams

# Apply Merged Configuration
if ($config) {
    if ($null -ne $mergedConfig.OutputPath) { $script:ScriptName = $mergedConfig.OutputPath }
    if ($null -ne $mergedConfig.UseInclude) { $script:ConcatNotInclude = -not $mergedConfig.UseInclude }
    if ($null -ne $mergedConfig.CreateShortcut) { $script:CreateShortcut = $mergedConfig.CreateShortcut }
    if ($null -ne $mergedConfig.UseUserStartup) { $script:UseUserStartup = $mergedConfig.UseUserStartup }
    if ($null -ne $mergedConfig.Force) { $script:Force = $mergedConfig.Force }
    if ($null -ne $mergedConfig.AutoStart) { $script:NoAutoStart = -not $mergedConfig.AutoStart }
    if ($null -ne $mergedConfig.Verbose) { $script:Verbose = $mergedConfig.Verbose }
}

try {
    Write-BuildLog "=== AutoHotkey Script Builder ===" "Info"
    Write-BuildLog "Output File: $ScriptName" "Info"
    Write-BuildLog "Use Include Mode: $(-not $ConcatNotInclude)" "Info"
    
    # Execute Build
    $buildSuccess = Invoke-ScriptBuild -OutputName $ScriptName -Force $script:Force -UseInclude (-not $ConcatNotInclude) -ExcludeList $mergedConfig.Exclude
    
    if (-not $buildSuccess) {
        Write-BuildLog "Build failed, exiting" "Error"
        exit 1
    }
    
    # Get Startup Folder Path
    $startupPath = Get-StartupFolderPath
    if (-not $startupPath) {
        Write-BuildLog "Could not determine startup folder path" "Error"
        exit 1
    }
    
    # Create Shortcut
    if ($CreateShortcut) {
        $linkName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName) + ".lnk"
        $linkPath = Join-Path -Path $startupPath -ChildPath $linkName
         
        if ((Test-Path -Path $linkPath) -and (-not $Force)) {
            Write-BuildLog "Shortcut already exists: $linkPath" "Info"
        }
        else {
            $shortcutSuccess = New-Shortcut -ShortcutPath $linkPath -TargetPath (Resolve-Path $ScriptName).Path
             
            if ($shortcutSuccess) {
                Write-BuildLog "Shortcut created: $linkPath" "Success"
            }
            else {
                Write-BuildLog "Failed to create shortcut" "Warning"
            }
        }
    }
    
    # Auto-Start Script
    if (-not $NoAutoStart) {
        try {
            Write-BuildLog "Starting AutoHotkey Script..." "Info"
            Start-Process -FilePath $ScriptName -ErrorAction Stop
            Write-BuildLog "Script started: $ScriptName" "Success"
        }
        catch {
            Write-BuildLog "Failed to start script: $($_.Exception.Message)" "Error"
        }
    }
    
    Write-BuildLog "All operations completed" "Success"
}
catch {
    Write-BuildLog "Error occurred during execution: $($_.Exception.Message)" "Error"
    exit 1
}
finally {
    # Cleanup
    if ($Verbose) {
        Write-BuildLog "Cleanup completed" "Info"
    }
}
