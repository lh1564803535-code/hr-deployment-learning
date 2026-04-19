#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
学习打卡自动化脚本
使用方法：python auto-checkin.py
"""

import os
import sys
import subprocess
from datetime import datetime
import json

# 项目配置
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
NOTES_FILE = os.path.join(PROJECT_DIR, 'learning-notes', 'daily-notes.md')
PROGRESS_FILE = os.path.join(PROJECT_DIR, 'LEARNING-PROGRESS.md')

def get_today_date():
    """获取今天的日期"""
    return datetime.now()

def read_file(filepath):
    """读取文件内容"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return ""

def write_file(filepath, content):
    """写入文件内容"""
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def append_to_file(filepath, content):
    """追加内容到文件"""
    with open(filepath, 'a', encoding='utf-8') as f:
        f.write(content)

def run_command(cmd, cwd=None):
    """执行命令"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            capture_output=True, 
            text=True,
            cwd=cwd or PROJECT_DIR
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def create_daily_template(day_num):
    """创建每日学习模板"""
    today = get_today_date()
    date_str = today.strftime("%Y-%m-%d")
    
    template = f"""
## {today.strftime("%Y-%m-%d")}（第{day_num}天）

### ✅ 今天完成
- ✓ [添加你今天完成的内容]

### 📝 学习重点
[记录重点知识点]

### 🎯 心得体会
[记录你的想法和收获]

### 🐛 遇到的问题
1. [问题描述]
   - ✅ 解决：[解决方案]

### ⏳ 明天计划
- [ ] [明天的学习计划]

---
"""
    return template

def get_day_number():
    """获取第几天"""
    content = read_file(NOTES_FILE)
    # 计算已有的天数
    day_count = content.count("## 20")  # 统计日期数量
    return day_count + 1

def get_input(prompt, default=""):
    """获取用户输入"""
    if default:
        user_input = input(f"{prompt} [{default}]: ").strip()
        return user_input or default
    else:
        return input(f"{prompt}: ").strip()

def main():
    """主函数"""
    print("\n" + "="*60)
    print("🚀 学习打卡自动化脚本")
    print("="*60 + "\n")
    
    # 检查项目目录
    if not os.path.exists(PROJECT_DIR):
        print(f"❌ 项目目录不存在: {PROJECT_DIR}")
        sys.exit(1)
    
    # 检查 git 仓库
    is_git_repo, _, _ = run_command("git status")
    if not is_git_repo:
        print("❌ 当前目录不是 Git 仓库")
        sys.exit(1)
    
    print("✅ 项目检查通过\n")
    
    # 获取今天的学习内容
    print("📚 请输入今天的学习内容：\n")
    
    completed = get_input("✅ 今天完成了什么？(逗号分隔)")
    keypoints = get_input("📝 学习要点是什么？")
    experience = get_input("🎯 你的心得体会？")
    problems = get_input("🐛 遇到的问题？(可选)", "无")
    tomorrow = get_input("⏳ 明天的计划？")
    
    # 生成提交信息
    commit_msg = get_input("\n💬 Git 提交信息", "📚 今天的学习内容")
    
    # 确认信息
    print("\n" + "="*60)
    print("📋 确认信息:")
    print("="*60)
    print(f"✅ 完成: {completed}")
    print(f"📝 重点: {keypoints}")
    print(f"🎯 心得: {experience}")
    print(f"🐛 问题: {problems}")
    print(f"⏳ 明天: {tomorrow}")
    print(f"💬 提交信息: {commit_msg}")
    print("="*60 + "\n")
    
    confirm = input("是否继续？(y/n): ").strip().lower()
    if confirm != 'y':
        print("❌ 已取消")
        sys.exit(0)
    
    # 构建完整的学习记录
    day_num = get_day_number()
    today = get_today_date()
    date_str = today.strftime("%Y-%m-%d")
    
    entry = f"""
## {date_str}（第{day_num}天）

### ✅ 今天完成
"""
    for item in completed.split("，"):
        entry += f"- ✓ {item.strip()}\n"
    
    entry += f"""
### 📝 学习重点
{keypoints}

### 🎯 心得体会
{experience}

### 🐛 遇到的问题
{problems}

### ⏳ 明天计划
- [ ] {tomorrow}

---
"""
    
    # 更新学习笔记
    print("\n📝 正在更新学习笔记...")
    append_to_file(NOTES_FILE, entry)
    print("✅ 学习笔记已更新\n")
    
    # 检查文件状态
    success, output, _ = run_command("git status --short")
    if success:
        print("📊 文件变更:")
        print(output)
    
    # 添加文件到暂存区
    print("\n📤 添加文件到 Git...")
    success, _, err = run_command("git add .")
    if not success:
        print(f"❌ 添加失败: {err}")
        sys.exit(1)
    print("✅ 文件已添加\n")
    
    # 提交
    print("💾 正在提交...")
    success, output, err = run_command(f'git commit -m "{commit_msg}"')
    if not success:
        if "nothing to commit" in err or "nothing to commit" in output:
            print("ℹ️  没有新的更改需要提交")
        else:
            print(f"❌ 提交失败: {err}")
            sys.exit(1)
    else:
        print(f"✅ 提交成功")
        print(output)
    
    # 推送到 GitHub
    print("\n🌐 正在推送到 GitHub...")
    success, output, err = run_command("git push origin main")
    if not success:
        # 尝试 master 分支
        success, output, err = run_command("git push origin master")
        if not success:
            print(f"⚠️ 推送失败: {err}")
            print("💡 提示：请检查 GitHub 是否配置正确")
            print("   或手动执行: git push origin main")
        else:
            print("✅ 推送成功!")
            print(output)
    else:
        print("✅ 推送成功!")
        print(output)
    
    # 显示总结
    print("\n" + "="*60)
    print("🎉 打卡完成！")
    print("="*60)
    print(f"📅 日期: {date_str}")
    print(f"📍 第{day_num}天")
    print(f"💬 提交信息: {commit_msg}")
    print("\n访问你的 GitHub 仓库查看更新:")
    
    # 获取 GitHub 仓库 URL
    success, remote, _ = run_command("git remote get-url origin")
    if success:
        print(f"🔗 {remote.strip()}")
    
    print("\n=" * 60 + "\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ 已取消")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ 出错: {e}")
        sys.exit(1)
