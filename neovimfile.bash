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
nvim -c 'normal ggOrequire("config")' -c 'wq' lua/config/init.lua
