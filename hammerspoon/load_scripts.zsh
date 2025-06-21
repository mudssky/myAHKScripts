#!/bin/zsh

# Hammerspoon Lua Scripts Loader
# 自动加载并应用所有Hammerspoon Lua脚本

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAMMERSPOON_CONFIG_DIR="$HOME/.hammerspoon"

echo -e "${BLUE}🔨 Hammerspoon Lua Scripts Loader${NC}"
echo -e "${BLUE}=================================${NC}"
echo

# 检查Hammerspoon是否已安装
if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo -e "${RED}❌ 错误: Hammerspoon未安装${NC}"
    echo -e "${YELLOW}请先安装Hammerspoon: https://www.hammerspoon.org/${NC}"
    echo -e "${YELLOW}或使用Homebrew安装: brew install --cask hammerspoon${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Hammerspoon已安装${NC}"

# 创建Hammerspoon配置目录（如果不存在）
if [ ! -d "$HAMMERSPOON_CONFIG_DIR" ]; then
    echo -e "${YELLOW}📁 创建Hammerspoon配置目录: $HAMMERSPOON_CONFIG_DIR${NC}"
    mkdir -p "$HAMMERSPOON_CONFIG_DIR"
fi

# 备份现有的init.lua文件
if [ -f "$HAMMERSPOON_CONFIG_DIR/init.lua" ]; then
    BACKUP_FILE="$HAMMERSPOON_CONFIG_DIR/init.lua.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}💾 备份现有配置文件到: $BACKUP_FILE${NC}"
    cp "$HAMMERSPOON_CONFIG_DIR/init.lua" "$BACKUP_FILE"
fi

# 生成新的init.lua文件
echo -e "${BLUE}📝 生成新的init.lua配置文件${NC}"

# 复制 init.lua 配置文件
echo "📋 复制 init.lua 配置文件..."
if [ -f "$SCRIPT_DIR/init/init.lua" ]; then
    cp "$SCRIPT_DIR/init/init.lua" "$HAMMERSPOON_CONFIG_DIR/init.lua"
    echo "✅ init.lua 配置文件已复制"
else
    echo "❌ 错误: 找不到 init.lua 文件在 $SCRIPT_DIR"
    exit 1
fi

echo -e "${GREEN}✅ init.lua配置文件已生成${NC}"

# 创建scripts目录并复制lua文件
SCRIPTS_TARGET_DIR="$HAMMERSPOON_CONFIG_DIR/scripts"
echo -e "${BLUE}📁 创建scripts目录: $SCRIPTS_TARGET_DIR${NC}"
mkdir -p "$SCRIPTS_TARGET_DIR"

# 复制所有lua文件到scripts目录
echo -e "${BLUE}📋 复制lua脚本文件${NC}"
copied_count=0

for lua_file in "$SCRIPT_DIR"/*.lua; do
    if [ -f "$lua_file" ]; then
        filename=$(basename "$lua_file")
        target_file="$SCRIPTS_TARGET_DIR/$filename"
        
        echo -e "${YELLOW}  📄 复制: $filename${NC}"
        cp "$lua_file" "$target_file"
        copied_count=$((copied_count + 1))
    fi
done

if [ $copied_count -eq 0 ]; then
    echo -e "${YELLOW}⚠️  没有找到lua文件${NC}"
else
    echo -e "${GREEN}✅ 已复制 $copied_count 个lua文件${NC}"
fi

# 检查Hammerspoon是否正在运行
if pgrep -x "Hammerspoon" > /dev/null; then
    echo -e "${GREEN}🔄 Hammerspoon正在运行，重启以应用新配置${NC}"
    # 重启Hammerspoon以应用新配置
    osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
    sleep 2
    open -a Hammerspoon
else
    echo -e "${YELLOW}🚀 启动Hammerspoon${NC}"
    open -a Hammerspoon
fi

echo
echo -e "${GREEN}🎉 所有脚本已成功加载!${NC}"
echo -e "${BLUE}配置文件位置: $HAMMERSPOON_CONFIG_DIR${NC}"
echo -e "${BLUE}脚本文件位置: $SCRIPTS_TARGET_DIR${NC}"
echo
echo -e "${YELLOW}使用说明:${NC}"
echo -e "${YELLOW}- 按 Cmd+Alt+Ctrl+R 可重新加载配置${NC}"
echo -e "${YELLOW}- 修改lua文件后会自动重新加载${NC}"
echo -e "${YELLOW}- 查看Hammerspoon控制台可以看到详细日志${NC}"
echo
echo -e "${GREEN}主要Windows风格快捷键:${NC}"
echo -e "${GREEN}- Alt+Tab: 应用切换${NC}"
echo -e "${GREEN}- Win+方向键: 窗口排列${NC}"
echo -e "${GREEN}- Ctrl+C/V/X/Z: 复制粘贴撤销${NC}"
echo -e "${GREEN}- Alt+F4: 关闭应用${NC}"
echo -e "${GREEN}- Win+L: 锁屏${NC}"
echo -e "${GREEN}- Win+E: 打开Finder${NC}"
echo -e "${GREEN}- 更多快捷键请查看脚本内容${NC}"