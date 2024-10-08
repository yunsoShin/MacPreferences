#!/bin/bash

# 0. Neovim 및 관련 설정 제거
echo "기존의 Neovim 설정 및 설치를 제거합니다..."
rm -rf ~/.local/share/nvim
rm -rf ~/.config/nvim
rm -rf ~/.cache/nvim
sudo rm -rf /usr/local/bin/nvim
sudo rm -rf /usr/bin/nvim

# 1. 기본 패키지 업데이트 및 Git 설치
echo "기본 패키지를 업데이트하고 Git을 설치합니다..."
sudo apt-get update

# Git 설치 여부 확인 및 설치
if ! command -v git &> /dev/null
then
    echo "Git이 설치되어 있지 않습니다. 설치를 진행합니다..."
    sudo apt-get install -y git
else
    echo "Git이 이미 설치되어 있습니다."
fi

# 2. Neovim 빌드에 필요한 의존성 설치
echo "Neovim 빌드에 필요한 의존성을 설치합니다..."
sudo apt-get install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen

# 3. 추가 의존성 설치
echo "추가 의존성을 설치합니다..."
sudo apt-get install -y make gcc g++ pkg-config libtool libtool-bin unzip gettext

# 4. Neovim 소스 코드 클론
echo "Neovim 소스 코드를 클론합니다..."
git clone https://github.com/neovim/neovim
cd neovim

# 5. Neovim v0.10.0 태그로 체크아웃
echo "Neovim v0.10.0 버전으로 체크아웃합니다..."
git checkout tags/v0.10.0 -b 0.10.0v

# 6. Neovim 빌드 및 설치
echo "Neovim을 빌드하고 설치합니다..."
make -j$(nproc)
sudo make install

# 7. 설치 확인
echo "Neovim 설치 버전을 확인합니다..."
nvim_version=$(nvim --version 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "Neovim이 /usr/local/bin에 설치되지 않았습니다. 설치 경로를 확인합니다..."
    
    # Neovim 설치 경로 확인
    if [ -f "/usr/local/bin/nvim" ]; then
        echo "Neovim이 /usr/local/bin에 설치되었습니다."
    else
        echo "/usr/local/bin에 Neovim이 설치되지 않았습니다. 설치된 경로를 확인합니다..."
        nvim_path=$(find / -name nvim 2>/dev/null | grep bin/nvim)
        if [ -n "$nvim_path" ]; then
            echo "Neovim이 $nvim_path에 설치되었습니다."
            
            # 경로에 추가
            sudo ln -s "$nvim_path" /usr/local/bin/nvim
            echo "Neovim이 /usr/local/bin으로 심볼릭 링크되었습니다."
        else
            echo "Neovim 설치에 실패했습니다. 경로를 찾을 수 없습니다."
            exit 1
        fi
    fi
else
    echo "Neovim이 설치되었습니다: $nvim_version"
fi

# 8. PATH에 /usr/local/bin이 추가되어 있는지 확인
echo "PATH에 /usr/local/bin이 포함되어 있는지 확인합니다..."
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo "/usr/local/bin을 PATH에 추가합니다..."
    export PATH=$PATH:/usr/local/bin
    echo "export PATH=\$PATH:/usr/local/bin" >> ~/.bashrc
    source ~/.bashrc
else
    echo "/usr/local/bin이 이미 PATH에 추가되어 있습니다."
fi

# 9. 최종 설치 확인
nvim --version

echo "Neovim 설치가 완료되었습니다. 버전을 확인하세요."
