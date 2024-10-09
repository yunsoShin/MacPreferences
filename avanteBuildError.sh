#!/bin/bash

# 운영체제 확인
OS=$(uname -s)  # 운영체제를 uname으로 확인

# Rust 설치 여부 확인 및 설치
if [[ "$OS" == "Linux" ]]; then
    if ! command -v rustc &> /dev/null; then
        echo "Rust가 설치되어 있지 않습니다. 설치를 진행합니다..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"  # Rust 환경 변수 로드
    else
        echo "Rust가 이미 설치되어 있습니다."
        rustc --version
    fi
fi

# Rust 설치 후 필수 패키지 설치
if [[ "$OS" == "Linux" ]]; then
    echo "필수 패키지(pkg-config, libssl-dev) 설치 중..."
    sudo apt update
    sudo apt install -y pkg-config libssl-dev
fi
