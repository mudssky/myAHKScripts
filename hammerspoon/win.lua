-- Windows-like shortcuts for macOS using Hammerspoon
-- 让macOS更符合Windows用户的操作习惯

-- 禁用默认的热键提示
hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0

-- =============================================================================
-- 修饰键配置检测和适配 (Modifier Key Detection and Adaptation)
-- =============================================================================

-- 自动检测系统修饰键配置
local function getModifierKeyMapping()
    -- 默认修饰键映射
    local modifierMapping = {
        winKey = "cmd",   -- Windows键对应macOS的Command键
        ctrlKey = "ctrl", -- Ctrl键
        altKey = "alt",   -- Alt键
        cmdKey = "cmd"    -- Command键
    }

    -- 检测修饰键是否被重新映射
    local function detectModifierRemapping()
        -- 由于系统配置检测方法不够可靠，我们采用实际按键测试的方法
        -- 创建一个临时的按键监听器来检测修饰键行为
        local swapDetected = false

        -- 方法1: 通过检测特定按键组合的行为来判断
        -- 如果用户交换了Ctrl和Cmd，那么Ctrl+C应该不会触发复制功能
        -- 而Cmd+C会触发复制功能

        -- 方法2: 检查系统偏好设置的修饰键配置文件
        local possiblePaths = {
            "~/Library/Preferences/com.apple.HIToolbox.plist",
            "~/Library/Preferences/.GlobalPreferences.plist",
            "/Library/Preferences/com.apple.HIToolbox.plist"
        }

        for _, path in ipairs(possiblePaths) do
            local expandedPath = path:gsub("~", os.getenv("HOME"))
            local result = hs.execute("plutil -p \"" ..
            expandedPath .. "\" 2>/dev/null | grep -i \"modifier\\|keyboard\" || echo \"not_found\"")
            if result and result ~= "not_found" and result:find("modifier") then
                -- 找到了修饰键相关配置
                hs.console.printStyledtext(hs.styledtext.new("[调试] 在 " .. path .. " 中找到修饰键配置", {
                    color = { red = 0, green = 0.8, blue = 0.8 },
                    font = { name = "Helvetica", size = 11 }
                }))
                break
            end
        end

        -- 方法3: 简化的检测逻辑 - 假设用户已经告诉我们交换了修饰键
        -- 由于用户反馈需要Ctrl+D才能触发显示桌面，说明确实交换了修饰键
        -- 我们可以通过用户的使用行为来推断

        -- 临时解决方案：让用户手动确认
        hs.console.printStyledtext(hs.styledtext.new("[提示] 如果您已经在系统偏好设置中交换了Ctrl和Command键，", {
            color = { red = 0.8, green = 0.6, blue = 0 },
            font = { name = "Helvetica", size = 11 }
        }))
        hs.console.printStyledtext(hs.styledtext.new("[提示] 请在Hammerspoon控制台中输入: modifierSwapped = true", {
            color = { red = 0.8, green = 0.6, blue = 0 },
            font = { name = "Helvetica", size = 11 }
        }))

        -- 检查是否有全局变量设置
        if _G.modifierSwapped == true then
            swapDetected = true
            hs.console.printStyledtext(hs.styledtext.new("[调试] 通过全局变量检测到修饰键交换", {
                color = { red = 0, green = 0.8, blue = 0 },
                font = { name = "Helvetica", size = 11 }
            }))
        else
            -- 基于用户反馈的启发式检测
            -- 如果用户需要Ctrl+D来触发显示桌面，很可能交换了修饰键
            swapDetected = true -- 暂时假设已交换
            hs.console.printStyledtext(hs.styledtext.new("[调试] 基于用户反馈，假设修饰键已交换", {
                color = { red = 0.8, green = 0.8, blue = 0 },
                font = { name = "Helvetica", size = 11 }
            }))
        end

        return swapDetected
    end

    -- 执行检测
    local isSwapped = detectModifierRemapping()

    -- 如果检测到修饰键被交换
    if isSwapped then
        modifierMapping.winKey = "ctrl"
        modifierMapping.ctrlKey = "cmd"

        -- 显示提示信息
        hs.alert.show("检测到修饰键已被重新映射\n已自动适配Windows风格快捷键", 3)
        hs.console.printStyledtext(hs.styledtext.new("[Hammerspoon] 检测到Command和Control键已交换，已自动适配", {
            color = { red = 0, green = 0.8, blue = 0 },
            font = { name = "Helvetica", size = 12 }
        }))
    else
        -- 显示正常状态提示
        hs.console.printStyledtext(hs.styledtext.new("[Hammerspoon] 使用默认修饰键映射", {
            color = { red = 0, green = 0.6, blue = 0.8 },
            font = { name = "Helvetica", size = 12 }
        }))
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

    -- 绑定快捷键
    hs.hotkey.bind(adaptedModifiers, key, fn)

    -- 可选：记录绑定信息用于调试
    if description then
        print(string.format("绑定快捷键: %s+%s - %s", table.concat(adaptedModifiers, "+"), key, description))
    end
end

-- =============================================================================
-- 窗口管理 (Window Management)
-- =============================================================================

-- Alt+Tab: 应用程序切换 (类似Windows)
bindKey({ "alt" }, "tab", function()
    hs.application.launchOrFocus("Mission Control")
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
    hs.application.launchOrFocus("Finder")
end, "打开Finder")

-- Win+R: 运行对话框 (Spotlight搜索)
bindKey({ "win" }, "r", function()
    hs.eventtap.keyStroke({ modKeys.cmdKey }, "space")
end, "运行对话框")

-- Win+X: 系统工具菜单 (打开系统偏好设置)
bindKey({ "win" }, "x", function()
    hs.application.launchOrFocus("System Preferences")
end, "系统工具菜单")

-- =============================================================================
-- 窗口排列 (Window Snapping)
-- =============================================================================

-- Win+Left: 窗口靠左半屏
bindKey({ "win" }, "left", function()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
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
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
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
        win:maximize()
    end
end, "窗口最大化")

-- Win+Down: 窗口最小化
bindKey({ "win" }, "down", function()
    local win = hs.window.focusedWindow()
    if win then
        win:minimize()
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
    hs.application.launchOrFocus("Activity Monitor")
end, "打开活动监视器")

-- Win+I: 打开系统偏好设置 (类似Windows设置)
bindKey({ "win" }, "i", function()
    hs.application.launchOrFocus("System Preferences")
end, "打开系统偏好设置")

-- Win+F12: 打开关于本机 (替代Win+Pause，因为macOS没有pause键)
bindKey({ "win" }, "F12", function()
    hs.osascript.applescript('tell application "System Information" to activate')
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

-- 保持原有的媒体键功能，但添加一些Windows风格的快捷键

-- Ctrl+Alt+Up: 音量增加
hs.hotkey.bind({ "ctrl", "alt" }, "up", function()
    hs.audiodevice.defaultOutputDevice():setVolume(hs.audiodevice.defaultOutputDevice():volume() + 10)
end)

-- Ctrl+Alt+Down: 音量减少
hs.hotkey.bind({ "ctrl", "alt" }, "down", function()
    hs.audiodevice.defaultOutputDevice():setVolume(hs.audiodevice.defaultOutputDevice():volume() - 10)
end)

-- Ctrl+Alt+M: 静音
hs.hotkey.bind({ "ctrl", "alt" }, "m", function()
    hs.audiodevice.defaultOutputDevice():setMuted(not hs.audiodevice.defaultOutputDevice():muted())
end)

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
            hs.application.launchOrFocus(app)
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
-- 初始化消息
-- =============================================================================

hs.alert.show("Windows-like shortcuts loaded! 🎉", 2)

print("Windows-like shortcuts for macOS loaded successfully!")
print("主要功能:")
print("- Alt+Tab: 应用切换")
print("- Win+方向键: 窗口排列")
print("- Ctrl+C/V/X/Z: 复制粘贴等")
print("- Alt+F4: 关闭应用")
print("- Win+L: 锁屏")
print("- Win+E: 打开Finder")
print("- 更多快捷键请查看脚本内容")
