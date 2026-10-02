# oh-my-posh 主题切换（由两个 PowerShell profile 共同加载），用法见 theme -h
# https://github.com/criscuolosubidu/posh-theme

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { return }

$global:PoshThemeVersion = '1.1.1'
$global:PoshThemeRepoRaw = 'https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main'
$global:PoshThemeScript = $PSCommandPath   # theme -Update 覆盖的就是这个文件
$global:PoshThemeFile = Join-Path $HOME '.posh-theme'
$global:PoshThemeDefault = 'M365Princess'
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

    oh-my-posh init pwsh --config (Get-PoshThemeConfig $Name) | Invoke-Expression
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
oh-my-posh init pwsh --config (Get-PoshThemeConfig $global:PoshThemeCurrent) | Invoke-Expression
