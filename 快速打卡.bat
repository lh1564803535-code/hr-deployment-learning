@echo off
REM 学习打卡快速脚本
REM 使用方法：快速打卡.bat "今天完成的内容" "学习重点" "心得体会" "遇到的问题" "明天计划"

setlocal enabledelayedexpansion
chcp 65001 >nul

set completed=%~1
set keypoints=%~2
set experience=%~3
set problems=%~4
set tomorrow=%~5

if "%completed%"=="" (
    echo.
    echo ============================================================
    echo.
    echo 👋 欢迎使用学习打卡脚本
    echo.
    echo 使用方法:
    echo   快速打卡.bat "完成内容" "学习重点" "心得体会" "问题" "明天计划"
    echo.
    echo 示例:
    echo   快速打卡.bat "学习Docker" "镜像和容器概念" "理解了Docker架构" "无" "学习Dockerfile"
    echo.
    echo ============================================================
    echo.
    exit /b
)

REM 获取当前日期
for /f "tokens=1-4 delims=/-" %%a in ('date /t') do (set "date=%%a-%%b-%%c")

REM 创建日志内容
set "logfile=learning-notes\daily-notes.md"

echo. >> "%logfile%"
echo ## %date% >> "%logfile%"
echo. >> "%logfile%"
echo ### Completed >> "%logfile%"
echo - %completed% >> "%logfile%"
echo. >> "%logfile%"
echo ### Key Points >> "%logfile%"
echo %keypoints% >> "%logfile%"
echo. >> "%logfile%"
echo ### Experience >> "%logfile%"
echo %experience% >> "%logfile%"
echo. >> "%logfile%"
echo ### Problems >> "%logfile%"
echo %problems% >> "%logfile%"
echo. >> "%logfile%"
echo ### Tomorrow Plan >> "%logfile%"
echo - [ ] %tomorrow% >> "%logfile%"
echo. >> "%logfile%"
echo --- >> "%logfile%"

echo ✅ 日志已更新

REM Git 操作
git add .
git commit -m "📚 日常学习打卡: %date%"
git push origin main

echo ✅ 已推送到 GitHub！
