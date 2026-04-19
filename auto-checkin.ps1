# 学习打卡自动化脚本 (PowerShell 版本)
# 使用方法：.\auto-checkin.ps1

param(
    [string]$Completed = "",
    [string]$Keypoints = "",
    [string]$Experience = "",
    [string]$Problems = "",
    [string]$Tomorrow = "",
    [string]$CommitMsg = "📚 今天的学习内容"
)

# 配置
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommandPath
$NotesFile = Join-Path $ProjectDir "learning-notes\daily-notes.md"
$ProgressFile = Join-Path $ProjectDir "LEARNING-PROGRESS.md"

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Get-DayNumber {
    if (Test-Path $NotesFile) {
        $content = Get-Content $NotesFile -Raw
        $dayCount = ($content | Select-String "## 20" -All).Matches.Count
        return $dayCount + 1
    }
    return 1
}

# 检查项目目录
Write-Header "🚀 学习打卡自动化脚本"

if (-not (Test-Path $ProjectDir)) {
    Write-Error "项目目录不存在: $ProjectDir"
    exit 1
}

Write-Success "项目检查通过"

# 检查 git 仓库
Push-Location $ProjectDir
try {
    $gitStatus = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "当前目录不是 Git 仓库"
        exit 1
    }
} finally {
    Pop-Location
}

# 如果没有传入参数，交互式输入
if (-not $Completed) {
    Write-Host "📚 请输入今天的学习内容：`n" -ForegroundColor Yellow
    $Completed = Read-Host "✅ 今天完成了什么？(逗号分隔)"
    $Keypoints = Read-Host "📝 学习要点是什么？"
    $Experience = Read-Host "🎯 你的心得体会？"
    $Problems = Read-Host "🐛 遇到的问题？(可选，按 Enter 跳过)"
    $Tomorrow = Read-Host "⏳ 明天的计划？"
    $CommitMsg = Read-Host "💬 Git 提交信息 (默认: 📚 今天的学习内容)"
    
    if (-not $CommitMsg) {
        $CommitMsg = "📚 今天的学习内容"
    }
    if (-not $Problems) {
        $Problems = "无"
    }
}

# 确认信息
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "📋 确认信息:" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "✅ 完成: $Completed"
Write-Host "📝 重点: $Keypoints"
Write-Host "🎯 心得: $Experience"
Write-Host "🐛 问题: $Problems"
Write-Host "⏳ 明天: $Tomorrow"
Write-Host "💬 提交信息: $CommitMsg"
Write-Host ("=" * 60) -ForegroundColor Cyan

$confirm = Read-Host "`n是否继续？(y/n)"
if ($confirm -ne "y") {
    Write-Error "已取消"
    exit 0
}

# 构建学习记录
$dayNum = Get-DayNumber
$today = Get-Date -Format "yyyy-MM-dd"

$entry = "`n## $today（第$dayNum`天）`n`n### ✅ 今天完成`n"
foreach ($item in $Completed.Split("，")) {
    $entry += "- ✓ $($item.Trim())`n"
}

$entry += @"
`n### 📝 学习重点
$Keypoints

### 🎯 心得体会
$Experience

### 🐛 遇到的问题
$Problems

### ⏳ 明天计划
- [ ] $Tomorrow

---
"@

# 更新学习笔记
Write-Host ""
Write-Info "正在更新学习笔记..."
Add-Content $NotesFile $entry
Write-Success "学习笔记已更新"

# 检查文件状态
Write-Host ""
Write-Host "📊 文件变更:" -ForegroundColor Yellow
Push-Location $ProjectDir
try {
    git status --short
    
    # 添加文件
    Write-Host ""
    Write-Info "正在添加文件到 Git..."
    git add . 2>&1 | Out-Null
    Write-Success "文件已添加"
    
    # 提交
    Write-Host ""
    Write-Info "正在提交..."
    git commit -m $CommitMsg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "提交成功"
    } else {
        Write-Info "没有新的更改需要提交"
    }
    
    # 推送到 GitHub
    Write-Host ""
    Write-Info "正在推送到 GitHub..."
    git push origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        git push origin master 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "推送成功!"
    } else {
        Write-Error "推送失败，请检查网络连接"
    }
    
    # 显示总结
    Write-Header "🎉 打卡完成！"
    Write-Host "📅 日期: $today"
    Write-Host "📍 第$dayNum`天"
    Write-Host "💬 提交信息: $CommitMsg"
    Write-Host ""
    Write-Host "访问你的 GitHub 仓库查看更新:" -ForegroundColor Yellow
    $remote = (git remote get-url origin 2>&1).ToString().Trim()
    Write-Host "🔗 $remote"
    Write-Host ""
    Write-Host ("=" * 60)
    Write-Host ""
    
} finally {
    Pop-Location
}
