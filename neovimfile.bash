#!/bin/bash

# 사용자 홈 디렉토리로 이동
cd ~

# .config/nvim 디렉토리 생성
mkdir -p .config/nvim
cd .config/nvim

# lua 디렉토리 및 하위 디렉토리 생성
mkdir -p lua/config lua/plugins lua/utils

# lua/config/init.lua 파일 생성
touch lua/config/init.lua

# nvim을 이용해 lua/config/init.lua 파일을 열고 require("config") 추가
nvim -c 'normal ggOrequire("config")' -c 'wq' lua/config/init.lua || true

# 에러에서 벗어나도록 엔터 키 입력
echo -e "\n\n" | read -p "Press Enter to continue..."

# lua/config/init.lua 파일에 추가 설정 작성
cat <<EOL >> lua/config/init.lua
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

# nvim을 실행하고 :Lazy 명령어 실행
nvim -c 'Lazy'
