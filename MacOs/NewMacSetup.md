# New Mac Setup

用途：新 Mac 装机命令清单（每段一句说明）。

---

## 快速开始（新 Mac 按这个顺序跑）

用途：把“这份文档 + 这个仓库”变成可执行的装机流程。

1. 安装 Apple Git / 开发者工具（用途：让 `/usr/bin/git`、编译工具可用）：

```bash
xcode-select --install
```

2. 安装 Homebrew（用途：后续 `brew install` / `brew bundle`）：

```bash
brew --version
which brew
```

3. 获取本仓库（用途：拿到脚本与 VS Code 工作区设置）：

```bash
git clone https://github.com/Mingz6/LearnScripts.git
cd LearnScripts
```

4. 一键安装 Brewfile（用途：把工具安装齐）：

```bash
brew bundle --file Brewfile
```

5. 启用 nvm / conda（用途：让它们在 zsh 里可用）：

```bash
./MacOs/enable-nvm.sh
./MacOs/enable-conda.sh
```

6. 打开 VS Code（用途：应用 `.vscode/settings.json`，并开始工作）：

```bash
code .
```

---

## 0. 基础检查

用途：确认 shell 环境。

```bash
uname -m
echo $SHELL
```

---

## 1. Homebrew

用途：用 Brewfile 把老机器的 brew 清单迁移到新机器。

### 1) 新机器：安装 Homebrew

用途：安装包管理器（按官方方式安装）。安装后检查：

```bash
brew --version
which brew
```

### 2) 老机器：导出 Brewfile

用途：导出已安装的 formula/cask 清单：

```bash
cd /path/to/LearnScripts
brew bundle dump --file Brewfile --force
```

说明：我现在把 `Brewfile` 放在本仓库根目录（`LearnScripts/Brewfile`），新 Mac clone 仓库后可直接 `brew bundle`。

### 3) 新机器：导入 Brewfile

用途：按 Brewfile 一键安装：

```bash
brew bundle --file Brewfile
```

备注：App Store 的应用不在 Brewfile 里。

---

## 2. Terminal（终端）

用途：选一个你日常用的终端入口（系统 Terminal / VS Code 终端），并保持交互体验稳定。

常见选择：

- 系统 Terminal：够用、最轻量。
- VS Code 集成终端：适合开发工作流（同一窗口里编辑 + 跑命令）。

### 我现在的终端方案（2025-12）

用途：保持 zsh 干净可控，同时把交互体验提升到“开发者日用”。

- Prompt：Starship
- 插件/工具：
  - zsh-autosuggestions（历史建议）
  - zsh-syntax-highlighting（语法高亮）
  - fzf（模糊搜索 / 补全增强）
  - zoxide（更聪明的 cd）

相关文件：

- `~/.zprofile`：PATH（Homebrew、个人 bin、dotnet tools）
- `~/.zshrc`：compinit、fzf 集成、zoxide、autosuggestions、syntax highlighting、Starship init

安装（用途：安装你当前方案里的 prompt/插件/增强工具）：

```bash
brew install starship zsh-autosuggestions zsh-syntax-highlighting fzf zoxide
```

可选：安装 fzf 的 shell 集成（用途：补全/快捷键更完整）：

```bash
$(brew --prefix)/opt/fzf/install --all
```

最小 `~/.zshrc` 片段（用途：把上述工具接到 zsh 里；按需合并到你现有配置）：

```bash
# fzf
[ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ] && source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
[ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ] && source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"

# zoxide
eval "$(zoxide init zsh)"

# zsh plugins
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# prompt
eval "$(starship init zsh)"
```

VS Code 终端稳定性（避免长命令/大输出导致崩溃）：

- 工作区设置：`.vscode/settings.json`（关闭终端 GPU 加速等）

备份（仅本地，避免误提交）：

- 本仓库下：`MacOs/zsh-backups/`（已加入 `.gitignore`）

---

## 3. Git（版本控制）

用途：用 macOS 自带（Apple Git）完成 clone/commit/push 等日常开发。

### 安装（Apple Git）

用途：安装 Xcode Command Line Tools（包含 `/usr/bin/git`）。

```bash
xcode-select --install
```

如果你已经装了完整 Xcode：

用途：让命令行工具指向 Xcode（也会提供 git）。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 更新（Apple Git）

用途：更新 Apple Git（随 Xcode / Command Line Tools / macOS 更新而更新）。

- App Store / 系统设置里更新 Xcode
- 系统更新（Software Update）
- 重新安装/修复 Command Line Tools（必要时）：

```bash
xcode-select --install
```

### 验证你现在用的是“系统 Git”

用途：确认当前调用的是 `/usr/bin/git`（Apple Git）。

```bash
which -a git
git --version
```

### 配置 Git 身份（用途：让 commit 带上你的 name/email）

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global --list | grep -E '^user\.'
```

### 配置 SSH（以 GitHub 为例）（用途：免输密码 clone/push）

```bash
mkdir -p ~/.ssh
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
```

把剪贴板里的公钥添加到 GitHub（Settings → SSH and GPG keys）后验证：

```bash
ssh -T git@github.com
```

---

## 4. zsh 配置（轻量方案）

用途：保持 zsh 干净可控（不依赖 Oh My Zsh / p10k）。

关键文件：

- `~/.zprofile`：登录 shell（PATH、工具链环境变量）
- `~/.zshrc`：交互 shell（补全、插件、prompt 初始化）

确认你当前没有加载 Oh My Zsh / p10k（用途：排查 prompt 来源）：

```bash
ls -la ~/.oh-my-zsh ~/.p10k.zsh 2>/dev/null
grep -nE "oh-my-zsh|p10k|powerlevel10k|ZSH_THEME" ~/.zshrc ~/.zprofile ~/.zshenv ~/.zlogin 2>/dev/null
```

---

## 5. Node.js 版本管理（nvm）

为什么当时装 nvm：

- Node 项目经常要求不同版本（例如老项目要 Node 16，新项目要 Node 20）。nvm 方便切换。

它用来干什么：

- 安装/切换 Node 版本：`nvm install` / `nvm use`

更推荐的替代品（2025 视角）：

- fnm（Fast Node Manager）：更快、对 zsh 友好，体验通常比 nvm 更顺。
- volta：项目级固定版本（团队一致性更强）。

如果仍然用 nvm（保留你原来的配置思路，整理成更清晰版本）：

安装：

```bash
brew install nvm
mkdir -p ~/.nvm
```

启用（用途：让 `nvm` 在 zsh 里可用）：

- 如果你在这个仓库里：

```bash
./MacOs/enable-nvm.sh
```

在 `~/.zprofile` 或 `~/.zshrc`（二选一，建议统一放 `~/.zshrc`）加入：

```bash
# Homebrew
export PATH="$HOME/bin:/opt/homebrew/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
```

之后执行：

```bash
source ~/.zshrc
```

如果你遇到 `nvm: command not found`（用途：快速修复 nvm “不工作”）：

1. 先确认 brew 里是否已安装 nvm：

```bash
brew list --formula | grep -E '^nvm$'
ls -la /opt/homebrew/opt/nvm/nvm.sh
```

2. 如果已安装但还是找不到 nvm，说明 zsh 没加载初始化脚本：把上面的 nvm 初始化段落放到 `~/.zshrc`，然后重新加载：

```bash
source ~/.zshrc
command -v nvm
```

3. nvm 生效后，如果还没装过任何 Node 版本：

```bash
nvm install --lts
nvm use --lts
node --version
```

---

## 6. Conda（Anaconda / Python 环境）

用途：给 Python 做隔离环境（不同项目用不同依赖/不同 Python 版本）。

安装（用途：安装 Anaconda，包含 `conda`）：

```bash
brew install --cask anaconda
```

启用（用途：让 `conda` 在 zsh 里可用）：

- 如果你在这个仓库里：

```bash
./MacOs/enable-conda.sh
```

验证（用途：确认 conda 可用且路径正确）：

```bash
conda --version
conda info --base
```

常用（用途：查看/创建/切换 Python 环境）：

```bash
conda env list
conda create -n py312 python=3.12 -y
conda activate py312
python --version
conda deactivate
```

可选（用途：避免每次打开终端自动进入 base）：

```bash
conda config --set auto_activate_base false
```

Prompt 可选（用途：不让 conda 单独显示 `(base)` 换行；交给 Starship 在同一行显示环境名）：

```bash
conda config --set changeps1 false
```

并让 Starship 也显示 `base`（默认会忽略 base）：

```bash
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
[conda]
ignore_base = false

# 右侧时间戳（可选）
right_format = "$time"

[time]
disabled = false
time_format = "%T"
format = "[$time]($style)"
EOF
```

---

## 7. PowerShell（pwsh）

为什么当时装 PowerShell：

- 你有很多 `.ps1` 脚本（例如 Azure、GitHub、系统自动化）。在 macOS 上需要 pwsh。

安装方式：

```bash
brew install --cask powershell
```

替代品：

- 纯 bash/zsh：可行，但跨平台一致性差。
- Python：适合复杂逻辑和可移植工具。

注意事项：

- PowerShell 的 profile 和 zsh 的 profile 是两套：
  - zsh：`~/.zshrc` / `~/.zprofile`
  - PowerShell：`$PROFILE`

---

## 8. .NET SDK & dotnet tools

为什么当时装 dotnet-sdk：

- C# 开发、构建、测试、跑工具（例如 reportgenerator）。

安装：

```bash
brew install --cask dotnet-sdk
```

把 dotnet 全局工具加入 PATH（建议用 `$HOME`，不要写死用户目录）：

```bash
echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile
```

安装 reportgenerator：

```bash
dotnet tool install -g dotnet-reportgenerator-globaltool
```

替代品：

- 直接用官方安装包（也可以）。
- 如果团队需要固定版本，建议使用 `global.json` 固定 SDK。

---

## 9. 让 PowerShell 也能用 nvm（你当时的思路）

结论先说：`nvm` 本质是 bash/zsh 的函数，不是独立可执行文件，所以 **PowerShell 里不能原生直接跑 `nvm`**。

你原来的做法主要有两种用途：

- 让 PowerShell 能用 “nvm 安装出来的 node”（通过导入 env/PATH）
- 或者在 PowerShell 里用 `bash -lc ...` 间接执行 nvm

这可以用，但属于“有点 hack”。更简单的替代：

- 用 fnm 或 volta（对 PowerShell 支持通常更顺）。

如果要继续沿用原方案（更清晰版本）：

1. 创建 PowerShell profile：

```powershell
New-Item -Path $PROFILE -Type File -Force
```

2. 编辑 `$PROFILE`，写入：

```powershell
# Load nvm (via bash)
$nvmInitScript = "/opt/homebrew/opt/nvm/nvm.sh"
if (Test-Path $nvmInitScript) {
    & bash -lc "source $nvmInitScript >/dev/null 2>&1; env" |
    ForEach-Object {
        if ($_ -match "^(.+?)=(.*)$") {
            $name, $value = $matches[1], $matches[2]
            Set-Item -Force -Path "env:$name" -Value $value
        }
    }
}
```

3. 加载 profile：

```powershell
. $PROFILE
```

快速验证（用途：在 pwsh 里间接跑 nvm）：

```powershell
bash -lc 'source /opt/homebrew/opt/nvm/nvm.sh >/dev/null 2>&1; nvm --version; nvm ls'
```

---
