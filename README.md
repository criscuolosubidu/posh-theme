# PowerShell 美化配置

oh-my-posh 主题 + JetBrainsMono Nerd Font 字体 + 随时切换主题的 `theme` 命令。

## 安装

**方式一：在线安装（推荐）**

用**管理员身份**打开 PowerShell，执行：

```powershell
irm https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main/web.ps1 | iex
```

**方式二：离线安装**

下载或克隆整个仓库，双击 `install.cmd`，在弹出的管理员确认里点"是"。

装完后**关闭所有 Windows Terminal 窗口再重新打开**。

## 安装脚本做了什么

1. 没有 oh-my-posh 时用 winget 安装
2. 下载安装 JetBrainsMono Nerd Font（约 130 MB），管理员运行时装给全机器
3. 把 `posh-theme.ps1` 复制到用户目录
4. 修改 PowerShell 7 和 Windows PowerShell 5 的 profile：原来的 `oh-my-posh init` 行换成加载切换脚本，没有就追加
5. Windows PowerShell 5 默认禁止运行脚本时，把当前用户的执行策略改为 RemoteSigned
6. 把 Windows Terminal 的默认字体设为 `JetBrainsMono NF`；装了更纱黑体时，中文用 `Sarasa Term SC` 显示

改动过的 profile 和 Terminal 配置都会在同目录留一份 `.bak` 备份。重复运行是安全的，已经装好的步骤会跳过。

## 使用

```powershell
theme                   # 列出全部主题，当前主题高亮显示
theme atomic            # 切换并记住，新开的终端也会沿用（支持 Tab 补全）
theme -Random           # 随机换一个
theme dracula -Once     # 只在当前窗口试用，不保存
theme -Update           # 从 GitHub 升级 theme 命令本身
theme -h                # 查看说明
```

当前主题保存在 `~/.posh-theme`，默认是 `M365Princess`。

## 标签页状态（Windows Terminal 1.15+）

- **标题显示当前路径**，开多个 pwsh 时一眼就能分清。部分主题自带标题设置，空闲时以主题为准。
- **命令运行超过 1 秒**：标签页变成琥珀色并显示转圈动画，标题显示正在运行的命令。`ls`、`cd` 这类瞬间完成的命令不会让标签页闪烁。
- **运行较久的命令失败**：标签页变红，直到下一条命令开始。
- **ssh 登录远程**：标签页立即变蓝、不转圈，标题显示 `ssh: 主机`（远程 shell 自己设置标题时以远程为准）。退出后恢复；只有 ssh 自己出错（退出码 255，比如连不上、断线）才变红，远程最后一条命令失败不算。

- **Claude Code、Codex、vim 等交互式程序**：运行时不转圈、不改标题、不变色，标签页交给程序自己管理（Claude Code 会自己设置标题、工作时自己转圈）。退出后清掉它可能残留的转圈，退出码不算失败。

| 颜色 | 含义 |
|---|---|
| 琥珀色 + 转圈 | 本机命令运行中 |
| 蓝色 | ssh 远程会话 |
| 红色 | 运行较久的命令失败 / ssh 连接出错 |

可以在 profile 里修改（写在加载 `posh-theme.ps1` 那一行的前面或后面都行）：

```powershell
$PoshThemeBusyColor   = '#4B95E9'   # 运行中的颜色，'' 表示不变色
$PoshThemeErrorColor  = ''          # 失败后的颜色，'' 表示不变色
$PoshThemeRemoteColor = '#59C9A5'   # ssh 远程会话的颜色，'' 表示不变色
$PoshThemeBusyDelayMs = 500         # 运行多久之后才显示
```

交互式程序名单默认是 `claude codex gemini opencode aider copilot vim nvim vi hx nano less htop btop lazygit`，按命令名匹配。要追加的话写在加载 `posh-theme.ps1` 那一行**之后**：

```powershell
$PoshThemeInteractiveApps += 'k9s'
```

## 升级

| 要升级的东西 | 命令 |
|---|---|
| `theme` 命令 | `theme -Update`（v1.1.0 之前装的没有这个参数，先重新运行一次安装命令） |
| oh-my-posh | `oh-my-posh upgrade` |
| 字体、profile、Terminal 设置 | 重新运行安装命令，已经装好的步骤会跳过 |

## 说明

- **为什么不用 `oh-my-posh font install`**：它只给当前用户装字体，Windows Terminal 以管理员身份运行时会找不到。
- **为什么用普通版 NF 而不是 Mono 版**：Mono 版图标不会重叠，但很小。普通版图标大，个别主题里图标后面没留空格时会压住下一个字。
- **修补某个主题**：在 `~/.posh-themes/<小写主题名>.omp.json` 写一个用 `extends` 继承原主题的文件，`theme` 会优先用它。例如：

  ```json
  {
    "extends": "m365princess",
    "blocks": [{ "type": "prompt", "alignment": "left",
                 "segments": [{ "type": "git", "template": " ➜ ({{ .HEAD }}) " }] }],
    "version": 4
  }
  ```

## 卸载

1. 删除两个 profile 里的 `. "$HOME/posh-theme.ps1"` 这一行，或用 `.bak` 还原
2. 删除 `~/posh-theme.ps1` 和 `~/.posh-theme`
3. 在 Windows Terminal 设置里改回原来的字体，或用 `settings.json.bak` 还原
