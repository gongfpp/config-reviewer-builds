# 配置评审台 Windows 离线构建

本仓库仅保存构建流程。源码从临时 AES-GCM 加密包载入，密钥仅存在仓库 Secret，不在 Git 或日志中。成功构建提供含完整 WebView2 离线安装器的 Windows x64 安装包、安装说明、检查脚本及 SHA256 清单。

构建测试包括 Rust 回归、Windows 凭据库、PE DLL 依赖检查、NSIS 安装和真实已安装应用 WebView2 UI 检查。CI 环境为 Windows Server 2022；目标内网 Windows 10 仍需验收。
