#!/bin/bash

# 사용자 홈 디렉토리로 이동
cd ~

# 기존 nvim 설정 삭제
rm -rf .config/nvim

# .config/nvim 디렉토리 생성
mkdir -p .config/nvim

# lua 디렉토리 및 하위 디렉토리 생성
mkdir -p .config/nvim/lua/config .config/nvim/lua/plugins .config/nvim/lua/utils

# nvim/init.lua 파일 생성 및 초기화
touch .config/nvim/init.lua

# nvim을 이용해 init.lua 파일을 열고 require("config") 추가
nvim -c 'normal ggOrequire("config")' -c 'wq' .config/nvim/init.lua || true


# lua/config/init.lua 파일에 추가 설정 작성
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

