# PowerShell 美化一键安装：oh-my-posh + JetBrainsMono Nerd Font + theme 切换命令
#   本地运行：双击 install.cmd（会自动申请管理员权限）
#   在线运行：在管理员 PowerShell 里执行 irm https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main/install.ps1 | iex
# 重复运行是安全的，已经装好的步骤会跳过。

# 整体包在脚本块里，用 irm | iex 运行时变量不会留在当前会话
& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # PowerShell 5 的下载进度条会让下载慢好几倍
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $RepoRaw     = 'https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main'   # 在线安装时从这里下载 posh-theme.ps1
    $FontZipUrl  = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
    $FontFace    = 'JetBrainsMono NF'
    $CjkFallback = 'Sarasa Term SC'

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    # 从文件运行且不是管理员时，申请管理员权限重新运行
    if (-not $isAdmin -and $PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        return
    }

    function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

    # 按原编码读写 profile，避免把中文注释改成乱码
    function Read-TextFile($path) {
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return @{ Text = [Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2); Encoding = [Text.Encoding]::Unicode }
        }
        $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $start = if ($bom) { 3 } else { 0 }
        try {
            $enc = New-Object Text.UTF8Encoding($bom, $true)
            $text = $enc.GetString($bytes, $start, $bytes.Length - $start)
        } catch {
            $enc = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
            $text = $enc.GetString($bytes)
        }
        @{ Text = $text; Encoding = $enc }
    }

    # 原来的 oh-my-posh init 行：第一处换成加载切换脚本（保持原来的位置），其余的注释掉
    function Update-Profile($p) {
        $line = '. "$HOME/posh-theme.ps1"'
        $initPattern = [regex]'(?m)^[ \t]*oh-my-posh[ \t]+init\b[^\r\n]*'
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory (Split-Path $p) -Force | Out-Null
            [IO.File]::WriteAllText($p, "$line`r`n", (New-Object Text.UTF8Encoding $false))
            Write-Host "新建：$p"
            return
        }
        $file = Read-TextFile $p
        if ($file.Text -match 'posh-theme\.ps1') { Write-Host "已配置，跳过：$p"; return }
        Copy-Item $p "$p.bak" -Force
        $state = @{ First = $true }
        $text = $initPattern.Replace($file.Text, [Text.RegularExpressions.MatchEvaluator] {
            param($m)
            if ($state.First) { $state.First = $false; $line } else { '# ' + $m.Value }
        })
        if ($state.First) { $text = $text.TrimEnd() + "`r`n`r`n$line`r`n" }
        [IO.File]::WriteAllText($p, $text, $file.Encoding)
        Write-Host "已更新（原文件备份为 .bak）：$p"
    }

    function Update-TerminalFont($s, $face) {
        try {
            $raw = [IO.File]::ReadAllText($s)
            # Windows Terminal 允许 // 注释，PowerShell 5 的 ConvertFrom-Json 不认，先去掉
            $json = (($raw -split "`r?`n") | Where-Object { $_ -notmatch '^\s*//' }) -join "`n" | ConvertFrom-Json
            if (-not $json.profiles) { $json | Add-Member profiles ([pscustomobject]@{}) -Force }
            if ($json.profiles -is [array]) { $json.profiles = [pscustomobject]@{ list = $json.profiles } }
            if (-not $json.profiles.defaults) { $json.profiles | Add-Member defaults ([pscustomobject]@{}) -Force }
            $defaults = $json.profiles.defaults
            if ($defaults.font) {
                $defaults.font | Add-Member face $face -Force
            } else {
                $defaults | Add-Member font ([pscustomobject]@{ face = $face }) -Force
            }
            $defaults.PSObject.Properties.Remove('fontFace')   # 旧版写法，会和 font.face 冲突
            Copy-Item $s "$s.bak" -Force
            [IO.File]::WriteAllText($s, ($json | ConvertTo-Json -Depth 64), (New-Object Text.UTF8Encoding $false))
            Write-Host "已设置为 `"$face`"（原文件备份为 .bak）：$s"
        } catch {
            Write-Warning "修改失败：$s`n$_`n请手动在 Windows Terminal 设置 → 默认值 → 外观 里把字体设为：$face"
        }
    }

    try {
        if (-not $isAdmin) {
            Write-Warning '当前不是管理员，字体只能装给当前用户。如果 Windows Terminal 设置了以管理员身份运行，它会找不到字体，建议用管理员 PowerShell 重新运行。'
        }

        # 1. oh-my-posh
        Write-Step '检查 oh-my-posh'
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-Host '已安装，跳过'
        } else {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                throw '没有找到 winget，请先手动安装 oh-my-posh：https://ohmyposh.dev/docs/installation/windows'
            }
            winget install JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
            if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { throw 'oh-my-posh 安装失败' }
        }

        # 2. 字体：oh-my-posh font install 只能装给当前用户，所以自己装，管理员时装到全机器
        Write-Step "安装字体 $FontFace"
        $fontRegName = 'JetBrainsMonoNerdFont-Regular (TrueType)'
        $machineKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        $userKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        $installed = (Get-ItemProperty $machineKey).$fontRegName -or (-not $isAdmin -and (Get-ItemProperty $userKey -ErrorAction SilentlyContinue).$fontRegName)
        if ($installed) {
            Write-Host '已安装，跳过'
        } else {
            $fontKey = if ($isAdmin) { $machineKey } else { $userKey }
            $fontDir = if ($isAdmin) { Join-Path $env:windir 'Fonts' } else { Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts' }
            $tmp = Join-Path $env:TEMP "posh-font-$(Get-Random)"
            New-Item -ItemType Directory $tmp | Out-Null
            Write-Host '正在下载字体包（约 130 MB）...'
            Invoke-WebRequest $FontZipUrl -OutFile "$tmp\font.zip" -UseBasicParsing
            Expand-Archive "$tmp\font.zip" $tmp
            New-Item -ItemType Directory $fontDir -Force | Out-Null
            # 只装普通版（图标大），不装 Mono / Propo / NL 变体
            Get-ChildItem $tmp -Filter 'JetBrainsMonoNerdFont-*.ttf' | ForEach-Object {
                $dest = Join-Path $fontDir $_.Name
                if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest }   # 已存在的可能正被系统占用，覆盖会失败
                $value = if ($isAdmin) { $_.Name } else { Join-Path $fontDir $_.Name }
                New-ItemProperty $fontKey -Name "$($_.BaseName) (TrueType)" -Value $value -PropertyType String -Force | Out-Null
            }
            Remove-Item $tmp -Recurse -Force
            Write-Host '完成'
        }

        # 3. theme 切换脚本
        Write-Step '安装 theme 切换命令'
        $target = Join-Path $HOME 'posh-theme.ps1'
        $local = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'posh-theme.ps1' }
        if ($local -and (Test-Path $local)) {
            Copy-Item $local $target -Force
        } elseif ($RepoRaw) {
            Invoke-WebRequest "$RepoRaw/posh-theme.ps1" -OutFile $target -UseBasicParsing
        } else {
            throw '找不到 posh-theme.ps1，请在安装包目录里运行'
        }
        Unblock-File $target
        Write-Host "已复制到 $target"

        # 4. PowerShell 7 和 Windows PowerShell 5 的 profile
        Write-Step '配置 PowerShell profile'
        $docs = [Environment]::GetFolderPath('MyDocuments')
        foreach ($p in "$docs\PowerShell\Microsoft.PowerShell_profile.ps1", "$docs\WindowsPowerShell\Microsoft.PowerShell_profile.ps1") {
            Update-Profile $p
        }

        # 5. 允许 Windows PowerShell 5 加载 profile（它默认禁止运行脚本；PowerShell 7 默认就允许）
        Write-Step '检查 Windows PowerShell 执行策略'
        powershell.exe -NoProfile -Command {
            $list = Get-ExecutionPolicy -List
            $effective = 'Restricted'
            foreach ($scope in 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine') {
                $v = ($list | Where-Object Scope -eq $scope).ExecutionPolicy
                if ("$v" -ne 'Undefined') { $effective = "$v"; break }
            }
            if ($effective -in 'Restricted', 'AllSigned') {
                # 安装器带 -ExecutionPolicy Bypass 启动时会报"被更高优先级覆盖"，设置其实已生效，下面再核对
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
                if ((Get-ExecutionPolicy -Scope CurrentUser) -eq 'RemoteSigned') { '已改为 RemoteSigned（仅当前用户）' }
                else { Write-Warning '修改失败，可能被组策略限制，Windows PowerShell 5 将不会加载主题' }
            } else {
                "当前为 $effective，无需修改"
            }
        }

        # 6. Windows Terminal 字体
        Write-Step '设置 Windows Terminal 字体'
        Add-Type -AssemblyName System.Drawing
        $hasCjk = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name -contains $CjkFallback
        $face = if ($hasCjk) { "$FontFace, $CjkFallback" } else { $FontFace }
        $wtFiles = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
            "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
        ) | Where-Object { Test-Path $_ }
        if (-not $wtFiles) {
            Write-Warning "没有找到 Windows Terminal 的配置。请先打开一次 Windows Terminal 再重新运行，或手动把字体设为：$face"
        }
        foreach ($s in $wtFiles) { Update-TerminalFont $s $face }

        Write-Host "`n全部完成！请关闭所有 Windows Terminal 窗口后重新打开，然后输入 theme 试试。" -ForegroundColor Green
    } catch {
        Write-Host "`n安装失败：$_" -ForegroundColor Red
    }

    if ($PSCommandPath) { Read-Host "`n按回车键退出" }
}
