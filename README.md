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
```

当前主题保存在 `~/.posh-theme`，默认是 `M365Princess`。

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
