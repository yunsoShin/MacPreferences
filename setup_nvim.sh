#!/bin/bash

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

# init.lua 파일의 local plugins 객체 갱신
sed -i '' 's/local plugins = {}/local plugins = "plugins"/' ~/.config/nvim/lua/config/init.lua

echo "스크립트 실행 완료."
