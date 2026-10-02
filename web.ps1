# Entry point for: irm https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main/web.ps1 | iex
# install.ps1 keeps a UTF-8 BOM because Windows PowerShell 5 needs it to read Chinese text from a file,
# but iex treats the BOM as part of the first token ("?#" is not recognized), so strip it here.
# Keep this file ASCII-only and without a BOM.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/criscuolosubidu/posh-theme/main/install.ps1').TrimStart([char]0xFEFF)
