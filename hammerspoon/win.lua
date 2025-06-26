-- Windows-like shortcuts for macOS using Hammerspoon
-- 让macOS更符合Windows用户的操作习惯

-- 禁用默认的热键提示
hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0

-- =============================================================================
-- 修饰键配置检测和适配 (Modifier Key Detection and Adaptation)
-- =============================================================================

-- 修饰键配置
local function getModifierKeyMapping()
    -- 检查环境变量HAMMERSPOON_MODIFIER_SWAP
    local envSwap = os.getenv("HAMMERSPOON_MODIFIER_SWAP")
    local shouldSwap = true -- 默认为交换模式
    
    -- 如果环境变量存在，根据其值决定是否交换
    if envSwap ~= nil then
        shouldSwap = (envSwap:lower() == "true" or envSwap == "1")
    end
    
    -- 也检查全局变量（向后兼容）
    if _G.modifierSwapped ~= nil then
        shouldSwap = _G.modifierSwapped
    end
    
    local modifierMapping
    if shouldSwap then
        -- 交换模式：Win键映射为Ctrl，Ctrl键映射为Cmd
        modifierMapping = {
            winKey = "ctrl",  -- Windows键对应macOS的Control键
            ctrlKey = "cmd",  -- Ctrl键对应macOS的Command键
            altKey = "alt",   -- Alt键
            cmdKey = "cmd"    -- Command键
        }
        hs.alert.show("修饰键交换模式已启用", 2)
    else
        -- 标准模式：保持原始映射
        modifierMapping = {
            winKey = "cmd",   -- Windows键对应macOS的Command键
            ctrlKey = "ctrl", -- Ctrl键
            altKey = "alt",   -- Alt键
            cmdKey = "cmd"    -- Command键
        }
        hs.alert.show("标准修饰键模式已启用", 2)
    end

    return modifierMapping
end

-- 获取修饰键映射
local modKeys = getModifierKeyMapping()

-- 辅助函数：创建适配的快捷键绑定
local function bindKey(modifiers, key, fn, description)
    -- 替换修饰键
    local adaptedModifiers = {}
    for _, mod in ipairs(modifiers) do
        if mod == "win" then
            table.insert(adaptedModifiers, modKeys.winKey)
        elseif mod == "ctrl" then
            table.insert(adaptedModifiers, modKeys.ctrlKey)
        elseif mod == "alt" then
            table.insert(adaptedModifiers, modKeys.altKey)
        elseif mod == "cmd" then
            table.insert(adaptedModifiers, modKeys.cmdKey)
        else
            table.insert(adaptedModifiers, mod)
        end
    end

    -- 绑定快捷键，添加错误处理
    local success, err = pcall(function()
        hs.hotkey.bind(adaptedModifiers, key, fn)
    end)
    
    if not success then
        print(string.format("绑定快捷键失败: %s+%s - %s", table.concat(adaptedModifiers, "+"), key, err))
    elseif description then
        print(string.format("绑定快捷键: %s+%s - %s", table.concat(adaptedModifiers, "+"), key, description))
    end
end

-- =============================================================================
-- 窗口管理 (Window Management)
-- =============================================================================

-- Alt+Tab: 应用程序切换 (使用系统App Switcher)
bindKey({ "alt" }, "tab", function()
    hs.eventtap.keyStroke({ "cmd" }, "tab")
end, "应用程序切换")

-- Win+Tab: 显示所有窗口 (Mission Control)
bindKey({ "win" }, "tab", function()
    hs.spaces.openMissionControl()
end, "显示所有窗口")

-- Win+D: 显示桌面
bindKey({ "win" }, "d", function()
    hs.eventtap.keyStroke({ "fn" }, "F11")
end, "显示桌面")

-- Win+L: 锁定屏幕
bindKey({ "win" }, "l", function()
    hs.caffeinate.lockScreen()
end, "锁定屏幕")

-- Win+E: 打开Finder (类似Windows资源管理器)
bindKey({ "win" }, "e", function()
    launchOrFocusApp("Finder")
end, "打开Finder")

-- Win+R: 运行对话框 (Spotlight搜索)
bindKey({ "win" }, "r", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "space")
end, "运行对话框")

-- Win+X: 系统工具菜单 (打开系统偏好设置)
bindKey({ "win" }, "x", function()
    launchOrFocusApp("System Preferences")
end, "系统工具菜单")

-- =============================================================================
-- 窗口排列 (Window Snapping)
-- =============================================================================

-- 窗口操作辅助函数
local function getWindowAndScreen()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("没有活动窗口", 1)
        return nil, nil
    end
    local screen = win:screen()
    if not screen then
        hs.alert.show("无法获取屏幕信息", 1)
        return nil, nil
    end
    return win, screen
end

-- Win+Left: 窗口靠左半屏
bindKey({ "win" }, "left", function()
    local win, screen = getWindowAndScreen()
    if win and screen then
        local frame = screen:frame()
        win:setFrame({
            x = frame.x,
            y = frame.y,
            w = frame.w / 2,
            h = frame.h
        })
    end
end, "窗口靠左半屏")

-- Win+Right: 窗口靠右半屏
bindKey({ "win" }, "right", function()
    local win, screen = getWindowAndScreen()
    if win and screen then
        local frame = screen:frame()
        win:setFrame({
            x = frame.x + frame.w / 2,
            y = frame.y,
            w = frame.w / 2,
            h = frame.h
        })
    end
end, "窗口靠右半屏")

-- Win+Up: 窗口最大化
bindKey({ "win" }, "up", function()
    local win = hs.window.focusedWindow()
    if win then
        if win:isMaximizable() then
            win:maximize()
        else
            hs.alert.show("窗口无法最大化", 1)
        end
    end
end, "窗口最大化")

-- Win+Down: 窗口最小化
bindKey({ "win" }, "down", function()
    local win = hs.window.focusedWindow()
    if win then
        if win:isMinimizable() then
            win:minimize()
        else
            hs.alert.show("窗口无法最小化", 1)
        end
    end
end, "窗口最小化")

-- =============================================================================
-- 文本编辑快捷键 (Text Editing)
-- =============================================================================

-- Ctrl+A: 全选 (在macOS中映射为Cmd+A)
bindKey({ "ctrl" }, "a", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "a")
end, "全选")

-- Ctrl+C: 复制
bindKey({ "ctrl" }, "c", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "c")
end, "复制")

-- Ctrl+V: 粘贴
bindKey({ "ctrl" }, "v", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "v")
end, "粘贴")

-- Ctrl+X: 剪切
bindKey({ "ctrl" }, "x", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "x")
end, "剪切")

-- Ctrl+Z: 撤销
bindKey({ "ctrl" }, "z", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "z")
end, "撤销")

-- Ctrl+Y: 重做
bindKey({ "ctrl" }, "y", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "z")
end, "重做")

-- Ctrl+S: 保存
bindKey({ "ctrl" }, "s", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "s")
end, "保存")

-- Ctrl+F: 查找
bindKey({ "ctrl" }, "f", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "f")
end, "查找")

-- Ctrl+N: 新建
bindKey({ "ctrl" }, "n", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "n")
end, "新建")

-- Ctrl+O: 打开
bindKey({ "ctrl" }, "o", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "o")
end, "打开")

-- Ctrl+P: 打印
bindKey({ "ctrl" }, "p", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "p")
end, "打印")

-- Ctrl+W: 关闭窗口/标签页
bindKey({ "ctrl" }, "w", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "w")
end, "关闭窗口")

-- Ctrl+T: 新建标签页
bindKey({ "ctrl" }, "t", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "t")
end, "新建标签页")

-- =============================================================================
-- 浏览器快捷键 (Browser Shortcuts)
-- =============================================================================

-- Ctrl+Tab: 下一个标签页
bindKey({ "ctrl" }, "tab", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "]")
end, "下一个标签页")

-- Ctrl+Shift+Tab: 上一个标签页
bindKey({ "ctrl", "shift" }, "tab", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "[")
end, "上一个标签页")

-- F5: 刷新页面
bindKey({}, "F5", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "r")
end, "刷新页面")

-- Ctrl+R: 刷新页面
bindKey({ "ctrl" }, "r", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "r")
end, "刷新页面")

-- Ctrl+Shift+T: 恢复关闭的标签页
bindKey({ "ctrl", "shift" }, "t", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "t")
end, "恢复关闭的标签页")

-- =============================================================================
-- 系统快捷键 (System Shortcuts)
-- =============================================================================

-- Alt+F4: 关闭应用程序
bindKey({ "alt" }, "F4", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "q")
end, "关闭应用程序")

-- Ctrl+Shift+Esc: 打开活动监视器 (类似任务管理器)
bindKey({ "ctrl", "shift" }, "escape", function()
    launchOrFocusApp("Activity Monitor")
end, "打开活动监视器")

-- Win+I: 打开系统偏好设置 (类似Windows设置)
bindKey({ "win" }, "i", function()
    launchOrFocusApp("System Preferences")
end, "打开系统偏好设置")

-- Win+F12: 打开关于本机 (替代Win+Pause，因为macOS没有pause键)
bindKey({ "win" }, "F12", function()
    launchOrFocusApp("System Information")
end, "打开关于本机")

-- =============================================================================
-- 截图快捷键 (Screenshot Shortcuts)
-- =============================================================================

-- Print Screen: 截取整个屏幕
bindKey({}, "F13", function() -- F13通常映射为Print Screen
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "3")
end, "截取整个屏幕")

-- Alt+Print Screen: 截取当前窗口
bindKey({ "alt" }, "F13", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "4")
    hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({}, "space")
    end)
end, "截取当前窗口")

-- Win+Shift+S: 截图工具 (类似Windows截图工具)
bindKey({ "win", "shift" }, "s", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "4")
end, "截图工具")

-- =============================================================================
-- 音量和媒体控制 (Volume and Media Control)
-- =============================================================================

-- 音量控制辅助函数
local function adjustVolume(delta)
    local device = hs.audiodevice.defaultOutputDevice()
    if device then
        local currentVolume = device:volume()
        local newVolume = math.max(0, math.min(100, currentVolume + delta))
        device:setVolume(newVolume)
        hs.alert.show(string.format("音量: %d%%", newVolume), 0.5)
    end
end

local function toggleMute()
    local device = hs.audiodevice.defaultOutputDevice()
    if device then
        local isMuted = device:muted()
        device:setMuted(not isMuted)
        hs.alert.show(isMuted and "取消静音" or "静音", 0.5)
    end
end

-- Ctrl+Alt+Up: 音量增加
bindKey({ "ctrl", "alt" }, "up", function()
    adjustVolume(10)
end, "音量增加")

-- Ctrl+Alt+Down: 音量减少
bindKey({ "ctrl", "alt" }, "down", function()
    adjustVolume(-10)
end, "音量减少")

-- Ctrl+Alt+M: 静音
bindKey({ "ctrl", "alt" }, "m", function()
    toggleMute()
end, "静音切换")

-- =============================================================================
-- 虚拟桌面 (Virtual Desktops)
-- =============================================================================

-- Win+Ctrl+Left: 切换到左边的桌面
bindKey({ "win", "ctrl" }, "left", function()
    hs.eventtap.keyStroke({ modKeys.ctrlKey }, "left")
end, "切换到左边的桌面")

-- Win+Ctrl+Right: 切换到右边的桌面
bindKey({ "win", "ctrl" }, "right", function()
    hs.eventtap.keyStroke({ modKeys.ctrlKey }, "right")
end, "切换到右边的桌面")

-- Win+Ctrl+D: 创建新的虚拟桌面
bindKey({ "win", "ctrl" }, "d", function()
    hs.eventtap.keyStroke({ modKeys.ctrlKey }, "up")
    hs.timer.doAfter(0.5, function()
        hs.eventtap.keyStroke({}, "return")
    end)
end, "创建新的虚拟桌面")

-- Win+Ctrl+F4: 关闭当前虚拟桌面
bindKey({ "win", "ctrl" }, "F4", function()
    hs.eventtap.keyStroke({ modKeys.ctrlKey }, "up")
    hs.timer.doAfter(0.5, function()
        hs.eventtap.keyStroke({}, "delete")
    end)
end, "关闭当前虚拟桌面")

-- =============================================================================
-- 应用程序快速启动 (Quick App Launch)
-- =============================================================================

-- 应用程序启动辅助函数
local function launchOrFocusApp(appName)
    if not appName then
        hs.alert.show("应用程序名称为空", 1)
        return
    end
    
    -- 应用程序名称映射表，处理一些常见的别名
    local appNameMap = {
        ["System Preferences"] = "System Preferences",
        ["系统偏好设置"] = "System Preferences",
        ["Activity Monitor"] = "Activity Monitor",
        ["活动监视器"] = "Activity Monitor",
        ["System Information"] = "System Information",
        ["系统信息"] = "System Information"
    }
    
    local actualAppName = appNameMap[appName] or appName
    local success = hs.application.launchOrFocus(actualAppName)
    if not success then
        hs.alert.show(string.format("无法启动应用程序: %s", actualAppName), 2)
    end
end

-- Win+1到Win+9: 启动或切换到任务栏上的应用程序
local taskbarApps = {
    "Finder",
    "Safari",
    "Terminal",
    "Visual Studio Code",
    "System Preferences",
    "Activity Monitor",
    "Calculator",
    "TextEdit",
    "Preview"
}

for i = 1, 9 do
    bindKey({ "win" }, tostring(i), function()
        local app = taskbarApps[i]
        if app then
            launchOrFocusApp(app)
        end
    end, "启动/切换到" .. (taskbarApps[i] or "应用程序"))
end

-- =============================================================================
-- 文件管理器快捷键 (File Manager Shortcuts)
-- =============================================================================

-- F2: 重命名 (在Finder中)
bindKey({}, "F2", function()
    hs.eventtap.keyStroke({}, "return")
end, "重命名")

-- Delete: 移到废纸篓
bindKey({}, "delete", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "delete")
end, "移到废纸篓")

-- Shift+Delete: 永久删除
bindKey({ "shift" }, "delete", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "alt" }, "delete")
end, "永久删除")

-- Ctrl+Shift+N: 新建文件夹
bindKey({ "ctrl", "shift" }, "n", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey, "shift" }, "n")
end, "新建文件夹")

-- =============================================================================
-- 初始化和配置信息
-- =============================================================================

-- 显示加载成功消息
hs.alert.show("Windows风格快捷键已加载 🎉", 2)

-- 输出配置信息到控制台
local function printLoadInfo()
    local envSwap = os.getenv("HAMMERSPOON_MODIFIER_SWAP")
    local currentMode = (modKeys.winKey == "ctrl") and "交换模式" or "标准模式"
    
    print("\n=== Windows风格快捷键配置 ===")
    print("修饰键映射:")
    print(string.format("  当前模式: %s", currentMode))
    print(string.format("  Win键: %s", modKeys.winKey))
    print(string.format("  Ctrl键: %s", modKeys.ctrlKey))
    print(string.format("  Alt键: %s", modKeys.altKey))
    print("\n环境变量配置:")
    if envSwap then
        print(string.format("  HAMMERSPOON_MODIFIER_SWAP: %s", envSwap))
    else
        print("  HAMMERSPOON_MODIFIER_SWAP: 未设置 (使用默认交换模式)")
    end
    print("\n主要功能:")
    print("  - Alt+Tab: 应用切换")
    print("  - Win+方向键: 窗口排列")
    print("  - Ctrl+C/V/X/Z: 文本操作")
    print("  - Alt+F4: 关闭应用")
    print("  - Win+L: 锁屏")
    print("  - Win+E: 打开Finder")
    print("  - Win+1-9: 快速启动应用")
    print("\n配置修饰键映射:")
    print("  环境变量: export HAMMERSPOON_MODIFIER_SWAP=false (禁用交换)")
    print("  全局变量: _G.modifierSwapped = false (向后兼容)")
    print("================================\n")
end

printLoadInfo()
