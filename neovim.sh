#!/bin/bash

# 운영체제 확인
OS=$(uname -s)


# Homebrew 설치 여부 확인 (Mac과 Linux 모두에 적용)
if ! command -v brew &> /dev/null
then
    echo "Homebrew가 설치되어 있지 않습니다. 설치를 진행합니다..."
    if [[ "$OS" == "Linux" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ "$OS" == "Darwin" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
else
    echo "Homebrew가 이미 설치되어 있습니다."
    brew --version
fi

# Neovim 버전 확인 및 최신 버전 설치
if command -v nvim &> /dev/null
then
    NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}')
    REQUIRED_VERSION="0.10.0"

    # Neovim 버전이 REQUIRED_VERSION보다 낮을 때만 업데이트
    if [[ $(echo -e "$REQUIRED_VERSION\n$NVIM_VERSION" | sort -V | head -n 1) == "$NVIM_VERSION" && "$NVIM_VERSION" != "$REQUIRED_VERSION" ]]; then
        echo "Neovim 버전이 $NVIM_VERSION이므로 업데이트가 필요합니다..."
        if [[ "$OS" == "Linux" ]]; then
            brew update
            brew upgrade neovim
        elif [[ "$OS" == "Darwin" ]]; then
            brew update
            brew upgrade neovim
        fi
    else
        echo "Neovim이 최신 버전입니다."
    fi
else
    echo "Neovim이 설치되어 있지 않습니다. 설치를 진행합니다..."
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update
        sudo apt install -y neovim
    elif [[ "$OS" == "Darwin" ]]; then
        brew install neovim
    fi
fi


# Git 설치 여부 확인
if ! command -v git &> /dev/null
then
    echo "Git이 설치되어 있지 않습니다. 설치를 진행합니다..."
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update
        sudo apt install -y git
    elif [[ "$OS" == "Darwin" ]]; then
        brew install git
    fi
else
    echo "Git이 이미 설치되어 있습니다."
    git --version
fi



# ripgrep 설치 여부 확인
if ! command -v rg &> /dev/null
then
    echo "ripgrep이 설치되어 있지 않습니다. 설치를 진행합니다..."
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update
        sudo apt install -y ripgrep
    elif [[ "$OS" == "Darwin" ]]; then
        brew install ripgrep
    fi
else
    echo "ripgrep이 이미 설치되어 있습니다."
    rg --version
fi

echo "사용자 홈 디렉토리로 이동..."
cd ~ || { echo "홈 디렉토리로 이동 실패"; exit 1; }

echo "기존 nvim 설정 삭제..."
rm -rf .config/nvim || { echo "기존 nvim 설정 삭제 실패"; exit 1; }

echo ".config/nvim 디렉토리 생성..."
mkdir -p .config/nvim || { echo ".config/nvim 디렉토리 생성 실패"; exit 1; }

echo "lua 디렉토리 및 하위 디렉토리 생성..."
mkdir -p .config/nvim/lua/config .config/nvim/lua/plugins .config/nvim/lua/utils || { echo "lua 디렉토리 및 하위 디렉토리 생성 실패"; exit 1; }

echo "nvim/init.lua 파일 생성 및 초기화..."
touch .config/nvim/init.lua || { echo "nvim/init.lua 파일 생성 실패"; exit 1; }

echo "nvim을 이용해 init.lua 파일을 열고 require('config') 추가..."
nvim -c 'normal ggOrequire("config")' -c 'wq' .config/nvim/init.lua || { echo "init.lua 파일 편집 실패"; exit 1; }

echo "lua/config/init.lua 파일에 추가 설정 작성..."
cat <<EOL > .config/nvim/lua/config/init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {}
local opts = {}

require("lazy").setup(plugins, opts)
EOL
echo "lua/config/init.lua 파일 작성 완료."

# .lazy_check 파일 초기화
echo "" > ~/.lazy_check

echo "nvim을 이용해 :Lazy 명령어 실행..."
nvim -c 'Lazy' -c 'w ~/.lazy_check' -c 'q' || { echo "nvim :Lazy 명령어 실행 실패"; exit 1; }

# .lazy_check 파일 확인
if grep -q 'Loaded plugins' ~/.lazy_check; then
  echo "success"
else
  echo "Lazy.nvim 설치 검증 실패"
fi

# .lazy_check 파일 삭제
rm ~/.lazy_check

echo "plugins/gruvbox.lua 파일 생성 및 설정 추가..."
cat <<EOL > ~/.config/nvim/lua/plugins/gruvbox.lua
return {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    lazy = false,
    config = function()
        vim.cmd([[colorscheme gruvbox]])
    end
}
EOL

# # init.lua 파일의 local plugins 객체 갱신
# sed -i 's/local plugins = {}/local plugins = "plugins"/' ~/.config/nvim/lua/config/init.lua

echo "plugins/NeoTree.lua 파일 생성 및 설정 추가..."
cat <<EOL > ~/.config/nvim/lua/plugins/neo-tree.lua
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    }
} 
EOL


echo "plugins/telescope.lua 파일 생성 및 설정 추가..."
cat <<EOL > ~/.config/nvim/lua/plugins/telescope.lua
return {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' }
}
EOL


# 운영체제에 따라 다른 sed 명령어 실행
if [[ "$OS" == "Linux" ]]; then
    sed -i 's/local plugins = {}/local plugins = "plugins"/' ~/.config/nvim/lua/config/init.lua || { echo "sed 명령어 실행 실패"; exit 1; }
elif [[ "$OS" == "Darwin" ]]; then
    sed -i '' 's/local plugins = {}/local plugins = "plugins"/' ~/.config/nvim/lua/config/init.lua || { echo "sed 명령어 실행 실패"; exit 1; }
fi

echo "Neovim 상태 점검을 위해 :checkhealth 명령어 실행..."
nvim -c 'checkhealth' || { echo "Neovim 상태 점검 실패"; exit 1; }

echo "스크립트 실행 완료."
