# oh-my-posh 主题切换（由两个 PowerShell profile 共同加载），用法见 theme -h
# https://github.com/criscuolosubidu/posh-theme

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { return }

$global:PoshThemeVersion = '1.3.0'
$global:PoshThemeRepoRaw = 'https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main'
$global:PoshThemeScript = $PSCommandPath   # theme -Update 覆盖的就是这个文件
$global:PoshThemeFile = Join-Path $HOME '.posh-theme'
$global:PoshThemeDefault = 'M365Princess'
# 命令运行超过 BusyDelayMs 毫秒后，标签页变成 BusyColor 并显示转圈动画；这样的命令失败时标签页变成 ErrorColor，
# 直到下一条命令开始；ssh 登录远程时标签页变成 RemoteColor。可以在 profile 里覆盖，颜色设为 '' 则不变色
if ($null -eq $global:PoshThemeBusyColor) { $global:PoshThemeBusyColor = '#F3AE35' }
if ($null -eq $global:PoshThemeErrorColor) { $global:PoshThemeErrorColor = '#D81E5B' }
if ($null -eq $global:PoshThemeRemoteColor) { $global:PoshThemeRemoteColor = '#4B95E9' }
# 自己管理标签页（标题、转圈）或者只是在等你操作的交互式程序：运行时不转圈、不改标题、不变色，退出码也不算失败
if ($null -eq $global:PoshThemeInteractiveApps) {
    $global:PoshThemeInteractiveApps = @('claude', 'codex', 'gemini', 'opencode', 'aider', 'copilot',
        'vim', 'nvim', 'vi', 'hx', 'nano', 'less', 'htop', 'btop', 'lazygit')
}
if ($null -eq $global:PoshThemeBusyDelayMs) { $global:PoshThemeBusyDelayMs = 1000 }
$global:PoshThemes = @(
    '1_shell', 'M365Princess', 'agnoster.minimal', 'agnoster', 'agnosterplus', 'aliens', 'amro',
    'atomic', 'atomicBit', 'avit', 'blue-owl', 'blueish', 'bubbles', 'bubblesextra', 'bubblesline',
    'capr4n', 'catppuccin', 'catppuccin_frappe', 'catppuccin_latte', 'catppuccin_macchiato',
    'catppuccin_mocha', 'cert', 'chips', 'cinnamon', 'clean-detailed', 'cloud-context',
    'cloud-native-azure', 'cobalt2', 'craver', 'darkblood', 'di4am0nd', 'dracula', 'easy-term',
    'emodipt-extend', 'emodipt', 'fish', 'free-ukraine', 'froczh', 'gmay', 'grandpa-style',
    'gruvbox', 'half-life', 'honukai', 'hotstick.minimal', 'hul10', 'hunk', 'huvix', 'if_tea',
    'illusi0n', 'iterm2', 'jandedobbeleer-accessible', 'jandedobbeleer', 'jblab_2021',
    'jonnychipz', 'json', 'jtracey93', 'jv_sitecorian', 'kali', 'kushal', 'lambda',
    'lambdageneration', 'larserikfinholt', 'lightgreen', 'marcduiker', 'markbull', 'material',
    'microverse-power', 'mojada', 'montys', 'mt', 'multiverse-neon', 'negligible', 'neko',
    'night-owl', 'nordtron', 'nu4a', 'onehalf.minimal', 'paradox', 'pararussel', 'patriksvensson',
    'peru', 'pixelrobots', 'plague', 'poshmon', 'powerlevel10k_classic', 'powerlevel10k_lean',
    'powerlevel10k_modern', 'powerlevel10k_rainbow', 'powerline', 'probua.minimal', 'pure',
    'quick-term', 'remk', 'robbyrussell', 'rudolfs-dark', 'rudolfs-light', 'sim-web', 'slim',
    'slimfat', 'smoothie', 'sonicboom_dark', 'sonicboom_light', 'sorin', 'space', 'spaceship',
    'star', 'stelbent-compact.minimal', 'stelbent.minimal', 'takuya', 'the-unnamed', 'thecyberden',
    'tiwahu', 'tokyo', 'tokyonight_storm', 'tonybaloney', 'uew', 'unicorn', 'velvet', 'wholespace',
    'wopian', 'xtoys', 'ys', 'zash')

# ~/.posh-themes/<小写主题名>.omp.json 存在时优先使用（用 extends 修补内置主题）
# oh-my-posh 只认小写的内置主题名，传 M365Princess 会变成 CONFIG NOT FOUND
function global:Get-PoshThemeConfig([string]$Name) {
    $override = Join-Path $HOME ".posh-themes\$($Name.ToLower()).omp.json"
    if (Test-Path $override) { $override } else { $Name.ToLower() }
}

# ---------- 标签页：标题显示路径；命令运行较久时标签页变色、转圈 ----------
# Windows Terminal 控制序列：OSC 9;4;3 / 9;4;0 显示 / 清除标签页转圈，
# OSC 4;264 / OSC 104;264 设置 / 恢复标签页颜色（Windows Terminal 1.15+）。
# 不用 OSC 9;4;2 表示失败：实测 Windows Terminal 1.24 的标签页上它只是个蓝色圆环，看不出是错误

# '#F3AE35' -> OSC 4;264 设置标签页颜色的序列，格式不对返回空字符串
function global:Get-PoshThemeTabColorVT([string]$Color) {
    if ($Color -match '^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$') {
        "$([char]27)]4;264;rgb:$($Matches[1])/$($Matches[2])/$($Matches[3])$([char]7)"
    } else { '' }
}

function global:Get-PoshThemeTabPath {
    $loc = Get-Location
    $p = if ($loc.Provider.Name -eq 'FileSystem') { $loc.ProviderPath } else { $loc.Path }
    if ($p -eq $HOME -or $p.StartsWith("$HOME\", [StringComparison]::OrdinalIgnoreCase)) { $p = '~' + $p.Substring($HOME.Length) }
    $parts = $p.TrimEnd('\') -split '\\'
    if ($parts.Count -gt 3) { $p = '…\' + ($parts[-2..-1] -join '\') }
    $p
}

function global:Write-PoshThemeVT([string]$Sequence) {
    # 只在 Windows Terminal 里发，别的终端可能不认识
    if ($env:WT_SESSION -and $Sequence) { [Console]::Out.Write($Sequence); [Console]::Out.Flush() }
}

# 后台线程：命令开始后等 BusyDelayMs，命令还没结束才变色、转圈，避免 ls、cd 这类瞬间命令让标签页闪烁
function global:Get-PoshThemeBusyState {
    if (-not $global:PoshThemeBusyState) {
        $state = [hashtable]::Synchronized(@{
            Lock = New-Object object; Signal = New-Object System.Threading.AutoResetEvent $false
            Seq = 0; Running = $false; Shown = $false; Title = ''; Sequence = ''; DelayMs = 1000
        })
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript({
            param($state)
            while ($true) {
                [void]$state.Signal.WaitOne()
                if ($state.Quit) { return }
                $seq = $state.Seq
                [System.Threading.Thread]::Sleep($state.DelayMs)
                [System.Threading.Monitor]::Enter($state.Lock)
                try {
                    if ($state.Running -and $state.Seq -eq $seq) {
                        $state.Shown = $true
                        [Console]::Title = $state.Title
                        if ($state.Sequence) { [Console]::Out.Write($state.Sequence); [Console]::Out.Flush() }
                    }
                } finally { [System.Threading.Monitor]::Exit($state.Lock) }
            }
        }).AddArgument($state)
        [void]$ps.BeginInvoke()
        # 退出时 PowerShell 会等这个后台脚本结束，而它卡在 WaitOne 上打断不了，必须先通知它返回，否则 exit 会卡死
        $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
            $global:PoshThemeBusyState.Quit = $true
            [void]$global:PoshThemeBusyState.Signal.Set()
        }
        $global:PoshThemeBusyState = $state
    }
    $global:PoshThemeBusyState
}

# 'claude --resume' -> 'claude'；'& "C:\Program Files\Neovim\bin\nvim.exe" a.md' -> 'nvim'
function global:Get-PoshThemeCommandName([string]$CommandLine) {
    if ($CommandLine -match '^\s*(?:[&.]\s+)?(?:"([^"]+)"|''([^'']+)''|(\S+))') {
        $first = @($Matches[1], $Matches[2], $Matches[3] | Where-Object { $_ })[0]
        ($first -replace '^.*[\\/]', '') -replace '\.(exe|cmd|bat|ps1)$', ''
    }
}

# 'ssh -p 2222 -i key me@host ls' -> 'me@host'；不是 ssh 命令返回 $null
function global:Get-PoshThemeSshTarget([string]$CommandLine) {
    $tokens = @($CommandLine.Trim() -split '\s+')
    if ($tokens.Count -lt 2 -or ($tokens[0] -replace '^.*[\\/]', '') -notmatch '^ssh(\.exe)?$') { return $null }
    for ($i = 1; $i -lt $tokens.Count; $i++) {
        $t = $tokens[$i]
        if ($t -cmatch '^-[BbcDEeFIiJLlmOoPpRSWw]$') { $i++; continue }   # 这些选项带参数，连参数一起跳过
        if ($t.StartsWith('-')) { continue }
        return $t -replace '^ssh://', ''
    }
    $null
}

# 命令开始执行（PSReadLine 接受输入行时调用）
function global:Invoke-PoshThemePreexec([string]$Line) {
    $esc = [char]27; $bel = [char]7
    if ($global:PoshThemeErrorShown) { Write-PoshThemeVT "$esc]104;264$bel"; $global:PoshThemeErrorShown = $false }
    $cmd = ($Line -split "`r?`n")[0].Trim()
    if ($cmd -match '^exit\b') { return }   # 退出本身可能超过 1 秒，别在关闭前闪一下
    $remote = Get-PoshThemeSshTarget $cmd
    if ($remote) {
        # ssh 登录远程不是本机在忙：不转圈，立即换成 RemoteColor；标题之后可能被远程 shell 改掉，以远程的为准
        $Host.UI.RawUI.WindowTitle = "ssh: $remote"
        Write-PoshThemeVT (Get-PoshThemeTabColorVT $global:PoshThemeRemoteColor)
        $global:PoshThemeRemoteShown = $true
        return
    }
    if ((Get-PoshThemeCommandName $cmd) -in $global:PoshThemeInteractiveApps) {
        # Claude Code、Codex 等会自己设置标题、自己发转圈信号（工作时转、等输入时停），这里不插手，免得盖掉它们的状态
        $global:PoshThemeInteractiveShown = $true
        return
    }
    if ($cmd.Length -gt 30) { $cmd = $cmd.Substring(0, 29) + '…' }
    $sequence = if ($env:WT_SESSION) { "$esc]9;4;3$bel" + (Get-PoshThemeTabColorVT $global:PoshThemeBusyColor) } else { '' }
    $state = Get-PoshThemeBusyState
    [System.Threading.Monitor]::Enter($state.Lock)
    try {
        $state.Seq++
        $state.Running = $true
        $state.Shown = $false
        $state.Title = "$cmd · $(Get-PoshThemeTabPath)"
        $state.Sequence = $sequence
        $state.DelayMs = [int]$global:PoshThemeBusyDelayMs
    } finally { [System.Threading.Monitor]::Exit($state.Lock) }
    [void]$state.Signal.Set()
}

# 显示提示符之前（命令结束后）调用，由注入 oh-my-posh 的 Set-PoshContext 触发
function global:Invoke-PoshThemePrompt($ErrorCode) {
    $esc = [char]27; $bel = [char]7
    if ($global:PoshThemeRemoteShown) {
        $global:PoshThemeRemoteShown = $false
        # ssh 的退出码一般是远程最后一条命令的，只有 255 才是 ssh 自己出错（连不上、断线）
        $errorVT = if ($ErrorCode -eq 255) { Get-PoshThemeTabColorVT $global:PoshThemeErrorColor } else { '' }
        if ($errorVT) {
            Write-PoshThemeVT $errorVT
            $global:PoshThemeErrorShown = $true
        } else {
            Write-PoshThemeVT "$esc]104;264$bel"
        }
    }
    if ($global:PoshThemeInteractiveShown) {
        $global:PoshThemeInteractiveShown = $false
        Write-PoshThemeVT "$esc]9;4;0$bel"   # 程序被强行关掉时可能留下它自己的转圈
    }
    $state = $global:PoshThemeBusyState
    if ($state) {
        [System.Threading.Monitor]::Enter($state.Lock)
        try {
            $shown = $state.Shown
            $state.Running = $false
            $state.Shown = $false
        } finally { [System.Threading.Monitor]::Exit($state.Lock) }
        if ($shown) {
            # 运行较久的命令失败时，标签页保持 ErrorColor，下次执行命令时恢复
            $errorVT = if ($ErrorCode) { Get-PoshThemeTabColorVT $global:PoshThemeErrorColor } else { '' }
            if ($errorVT) {
                Write-PoshThemeVT "$esc]9;4;0$bel$errorVT"
                $global:PoshThemeErrorShown = $true
            } else {
                Write-PoshThemeVT "$esc]9;4;0$bel$esc]104;264$bel"
            }
        }
    }
    $Host.UI.RawUI.WindowTitle = Get-PoshThemeTabPath
}

# 加载主题并挂上钩子。oh-my-posh 在模块内部调用自己的 Set-PoshContext，在全局定义同名函数不会被调用，
# 所以要注入到模块里；每次 init 都会重建模块，因此每次加载主题后都要重新注入
function global:Initialize-PoshTheme([string]$Name) {
    oh-my-posh init pwsh --config (Get-PoshThemeConfig $Name) | Invoke-Expression
    $omp = Get-Module oh-my-posh-core
    if ($omp) { & $omp { function script:Set-PoshContext { Invoke-PoshThemePrompt $script:ErrorCode } } }

    # 不占用回车键（oh-my-posh 的瞬时提示符要用），改用 PSReadLine 的历史记录回调感知命令开始
    if (-not $global:PoshThemeHistoryHooked -and (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)) {
        $global:PoshThemeOrigHistoryHandler = (Get-PSReadLineOption).AddToHistoryHandler
        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$line)
            try { Invoke-PoshThemePreexec $line } catch { }
            if ($global:PoshThemeOrigHistoryHandler) { $global:PoshThemeOrigHistoryHandler.Invoke($line) } else { $true }
        }
        $global:PoshThemeHistoryHooked = $true
    }
}

# global: 让 theme -Update 在函数里重新加载本文件时，新定义的 theme 仍然是全局的
function global:theme {
    param(
        [Parameter(Position = 0)]
        [ArgumentCompleter({
            param($cmd, $param, $word)
            $global:PoshThemes | Where-Object { $_ -like "$word*" }
        })]
        [string]$Name,
        [switch]$Random,
        [switch]$Once,
        [switch]$Update,
        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host "theme - oh-my-posh 主题切换 v$global:PoshThemeVersion" -ForegroundColor Cyan
        Write-Host @"

用法：
  theme                  列出所有主题，当前主题高亮显示
  theme <名字>           切换并记住，新开的终端也会沿用（支持 Tab 补全）
  theme <名字> -Once     只在当前窗口试用，不保存
  theme -Random          随机换一个（可以加 -Once）
  theme -Update          从 GitHub 升级 theme 命令本身
  theme -h               显示这份说明

文件：
  ~/.posh-theme                     当前选择的主题
  ~/.posh-themes/<名字>.omp.json    主题覆盖文件，存在时优先使用（用 extends 修补内置主题）

标签页（Windows Terminal）：
  标题显示当前路径（部分主题自带标题设置，以主题为准）
  命令运行超过 1 秒时，标签页变色并显示转圈动画；这样的命令失败时标签页变红，直到下一条命令开始
  ssh 登录远程时标签页变蓝、不转圈，标题显示 ssh: 主机；ssh 出错退出（退出码 255）时变红
  Claude Code、Codex、vim 等交互式程序运行时不插手，标签页交给它们自己管理
  可以在 profile 里修改：
    `$PoshThemeBusyColor = '#4B95E9'    运行中的标签页颜色，设为 '' 则不变色
    `$PoshThemeErrorColor = ''          失败后的标签页颜色，设为 '' 则不变色
    `$PoshThemeRemoteColor = '#59C9A5'  ssh 远程会话的标签页颜色，设为 '' 则不变色
    `$PoshThemeInteractiveApps += 'k9s'  加入不需要转圈的交互式程序（按命令名匹配）
    `$PoshThemeBusyDelayMs = 500        运行多久之后才显示

主页：https://github.com/criscuolosubidu/posh-theme
"@
        return
    }

    if ($Update) {
        $self = if ($global:PoshThemeScript) { $global:PoshThemeScript } else { Join-Path $HOME 'posh-theme.ps1' }
        $tmp = "$self.download"
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        try {
            Invoke-WebRequest "$global:PoshThemeRepoRaw/posh-theme.ps1" -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Warning "下载失败：$_"
            return
        }
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$errors)
        if ($errors.Count -gt 0) {
            Remove-Item $tmp
            Write-Warning '下载的文件不完整或已损坏，未做修改'
            return
        }
        # 不用 Get-FileHash：从 pwsh 里启动的 Windows PowerShell 5 会继承错误的模块路径，找不到它
        $same = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tmp)) -eq [Convert]::ToBase64String([IO.File]::ReadAllBytes($self))
        if ($same) {
            Remove-Item $tmp
            Write-Host "已经是最新版本 v$global:PoshThemeVersion" -ForegroundColor Green
            return
        }
        $old = $global:PoshThemeVersion
        Move-Item $tmp $self -Force
        . $self
        Write-Host "已升级：v$old -> v$global:PoshThemeVersion" -ForegroundColor Green
        return
    }

    if ($Random) {
        $Name = $global:PoshThemes | Where-Object { $_ -ne $global:PoshThemeCurrent } | Get-Random
    }

    if (-not $Name) {
        $width = ($global:PoshThemes | Measure-Object -Property Length -Maximum).Maximum + 4
        $cols = [Math]::Max(1, [Math]::Floor($Host.UI.RawUI.WindowSize.Width / $width))
        for ($i = 0; $i -lt $global:PoshThemes.Count; $i += $cols) {
            $row = $global:PoshThemes[$i..([Math]::Min($i + $cols, $global:PoshThemes.Count) - 1)]
            foreach ($t in $row) {
                if ($t -eq $global:PoshThemeCurrent) {
                    Write-Host "* $t" -ForegroundColor Black -BackgroundColor Green -NoNewline
                } else {
                    Write-Host "  $t" -NoNewline
                }
                Write-Host (' ' * ($width - $t.Length - 2)) -NoNewline
            }
            Write-Host
        }
        return
    }

    if ($Name -notin $global:PoshThemes) {
        Write-Warning "没有叫 '$Name' 的主题，输入 theme 查看全部"
        return
    }
    $Name = $global:PoshThemes | Where-Object { $_ -eq $Name } | Select-Object -First 1

    Initialize-PoshTheme $Name
    $global:PoshThemeCurrent = $Name
    if ($Once) {
        Write-Host "当前窗口临时使用 $Name" -ForegroundColor Yellow
    } else {
        Set-Content -Path $global:PoshThemeFile -Value $Name
        Write-Host "已切换到 $Name" -ForegroundColor Green
    }
}

$global:PoshThemeCurrent = if (Test-Path $global:PoshThemeFile) { (Get-Content $global:PoshThemeFile -Raw).Trim() }
if ($global:PoshThemeCurrent -notin $global:PoshThemes) { $global:PoshThemeCurrent = $global:PoshThemeDefault }
Initialize-PoshTheme $global:PoshThemeCurrent
