# Hammerspoon Windows风格快捷键脚本

这个项目为macOS用户提供了Windows风格的快捷键映射，让经常使用Windows系统的用户在macOS上有更熟悉的操作体验。

## 📋 功能特性

### 🪟 窗口管理
- **Alt+Tab**: 应用程序切换（类似Windows）
- **Win+Tab**: 显示所有窗口（Mission Control）
- **Win+D**: 显示桌面
- **Win+L**: 锁定屏幕
- **Win+E**: 打开Finder（类似Windows资源管理器）
- **Win+R**: 运行对话框（Spotlight搜索）
- **Win+X**: 系统工具菜单（打开系统偏好设置）

### 📐 窗口排列
- **Win+Left**: 窗口靠左半屏
- **Win+Right**: 窗口靠右半屏
- **Win+Up**: 窗口最大化
- **Win+Down**: 窗口最小化

### ✏️ 文本编辑
- **Ctrl+A**: 全选
- **Ctrl+C**: 复制
- **Ctrl+V**: 粘贴
- **Ctrl+X**: 剪切
- **Ctrl+Z**: 撤销
- **Ctrl+Y**: 重做
- **Ctrl+S**: 保存
- **Ctrl+F**: 查找
- **Ctrl+N**: 新建
- **Ctrl+O**: 打开
- **Ctrl+P**: 打印
- **Ctrl+W**: 关闭窗口/标签页
- **Ctrl+T**: 新建标签页

### 🌐 浏览器快捷键
- **Ctrl+Tab**: 下一个标签页
- **Ctrl+Shift+Tab**: 上一个标签页
- **F5**: 刷新页面
- **Ctrl+R**: 刷新页面
- **Ctrl+Shift+T**: 恢复关闭的标签页

### 🖥️ 系统快捷键
- **Alt+F4**: 关闭应用程序
- **Ctrl+Shift+Esc**: 打开活动监视器（类似任务管理器）
- **Win+I**: 打开系统偏好设置
- **Win+Pause**: 打开关于本机

### 📸 截图快捷键
- **Print Screen (F13)**: 全屏截图
- **Alt+Print Screen**: 窗口截图

### 🔊 音量控制
- **Ctrl+Alt+Up**: 音量增加
- **Ctrl+Alt+Down**: 音量减少
- **Ctrl+Alt+M**: 静音切换

### 🖥️ 虚拟桌面
- **Ctrl+Win+Left**: 切换到左边的桌面
- **Ctrl+Win+Right**: 切换到右边的桌面
- **Ctrl+Win+D**: 创建新的桌面

### 🚀 应用程序快速启动
- **Win+1到Win+9**: 快速切换到运行中的应用程序

### 📁 文件管理器
- **F2**: 重命名文件
- **Delete**: 移到废纸篓
- **Shift+Delete**: 永久删除
- **Ctrl+Shift+N**: 新建文件夹

## 🛠️ 安装和使用

### 前置要求
1. **安装Hammerspoon**:
   ```bash
   brew install hammerspoon
   ```
   或者从官网下载: https://www.hammerspoon.org/

2. **启动Hammerspoon**并给予必要的权限（辅助功能权限）

### 自动安装
运行提供的zsh脚本来自动安装和配置：

```bash
./load_scripts.zsh
```

这个脚本会：
- 检查Hammerspoon是否已安装
- 备份现有的配置文件
- 创建新的配置文件
- 复制所有lua脚本到正确位置
- 启动或重新加载Hammerspoon

### 手动安装
如果你想手动安装：

1. 复制`win.lua`到`~/.hammerspoon/scripts/`目录
2. 创建或修改`~/.hammerspoon/init.lua`文件来加载脚本
3. 重新加载Hammerspoon配置

## 🔧 配置管理

### 修饰键配置
脚本默认启用**修饰键交换模式**，将Windows风格的快捷键更好地适配到macOS：
- **Win键** → **Ctrl键**（macOS的Control键）
- **Ctrl键** → **Cmd键**（macOS的Command键）

#### 环境变量配置（推荐）
通过设置环境变量来控制修饰键映射：

```bash
# 禁用修饰键交换（使用标准映射）
export HAMMERSPOON_MODIFIER_SWAP=false

# 启用修饰键交换（默认行为）
export HAMMERSPOON_MODIFIER_SWAP=true
```

将环境变量添加到你的shell配置文件中：
```bash
# 添加到 ~/.zshrc 或 ~/.bash_profile
echo 'export HAMMERSPOON_MODIFIER_SWAP=false' >> ~/.zshrc
source ~/.zshrc
```

#### 全局变量配置（向后兼容）
也可以通过在`~/.hammerspoon/init.lua`中设置全局变量：

```lua
-- 在加载win.lua之前设置
_G.modifierSwapped = false  -- 禁用交换
-- 然后加载脚本
require('scripts.win')
```

#### 配置模式对比

| 功能 | 交换模式（默认） | 标准模式 |
|------|------------------|----------|
| 窗口排列 | **Ctrl+方向键** | **Cmd+方向键** |
| 文本操作 | **Cmd+C/V/X/Z** | **Ctrl+C/V/X/Z** |
| 锁定屏幕 | **Ctrl+L** | **Cmd+L** |
| 打开Finder | **Ctrl+E** | **Cmd+E** |
| 系统设置 | **Ctrl+I** | **Cmd+I** |

**推荐使用交换模式**，因为它让Windows用户在macOS上有更自然的操作体验。

### 重新加载配置
- **快捷键**: `Cmd+Alt+Ctrl+R`
- **自动重载**: 修改lua文件后会自动重新加载

### 查看日志
打开Hammerspoon控制台可以查看详细的加载日志和错误信息，包括当前的修饰键配置状态。

### 自定义配置
你可以修改`win.lua`文件来自定义快捷键映射：

```lua
-- 例如：添加新的快捷键
hs.hotkey.bind({"cmd"}, "j", function()
    -- 你的自定义功能
end)
```

## 📁 文件结构

```
hammerspoon/
├── win.lua              # 主要的Windows风格快捷键脚本
├── load_scripts.zsh     # 自动安装和配置脚本
└── README.md           # 说明文档
```

安装后的Hammerspoon配置结构：
```
~/.hammerspoon/
├── init.lua            # 主配置文件（自动生成）
└── scripts/
    └── win.lua         # Windows风格快捷键脚本
```

## 🐛 故障排除

### 快捷键不工作
1. 确保Hammerspoon有辅助功能权限
2. 检查是否有其他应用占用了相同的快捷键
3. 查看Hammerspoon控制台的错误信息

### 脚本加载失败
1. 检查lua语法是否正确
2. 查看Hammerspoon控制台的错误日志
3. 尝试重新加载配置（`Cmd+Alt+Ctrl+R`）

### 权限问题
1. 在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中添加Hammerspoon
2. 重启Hammerspoon应用

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

本项目采用MIT许可证。

## 🙏 致谢

感谢[Hammerspoon](https://www.hammerspoon.org/)项目提供了强大的macOS自动化工具。