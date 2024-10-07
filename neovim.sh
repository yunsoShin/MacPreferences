#!/bin/bash

# 운영체제 확인
OS=$(uname -s)
ARCH=$(uname -m) # 시스템 아키텍처 확인

# Homebrew 설치 여부 확인 (Mac과 Linux 모두에 적용)
if ! command -v brew &> /dev/null
then
    echo "Homebrew가 설치되어 있지 않습니다. 설치를 진행합니다..."
    if [[ "$OS" == "Linux" && "$ARCH" != "arm64" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ "$OS" == "Darwin" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew가 이 아키텍처에서는 지원되지 않습니다. apt를 이용해 Neovim을 설치합니다..."
        # Ubuntu 버전 확인
        UBUNTU_VERSION=$(lsb_release -r | awk '{print $2}')
        if [[ $(echo "$UBUNTU_VERSION >= 18.04" | bc -l) -eq 1 ]]; then
            # 최신 Ubuntu 버전
            sudo add-apt-repository ppa:neovim-ppa/stable
            sudo apt-get update
            sudo apt-get install -y neovim
        else
            # 이전 Ubuntu 버전
            sudo apt-get update
            sudo apt-get install -y python-dev python-pip python3-dev
            sudo apt-get install -y python3-setuptools
            sudo easy_install3 pip
            sudo apt-get install -y neovim
        fi
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
    if [[ "$OS" == "Linux" && "$ARCH" != "arm64" ]]; then
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




# globals.lua, keymaps.lua, options.lua 파일 생성
echo "globals.lua, keymaps.lua, options.lua 파일 생성..."
touch ~/.config/nvim/lua/config/globals.lua || { echo "globals.lua 파일 생성 실패"; exit 1; }
touch ~/.config/nvim/lua/config/keymaps.lua || { echo "keymaps.lua 파일 생성 실패"; exit 1; }
touch ~/.config/nvim/lua/config/options.lua || { echo "options.lua 파일 생성 실패"; exit 1; }

echo "globals.lua, keymaps.lua, options.lua 파일이 생성되었습니다."

# 키매퍼 파일 생성
echo "keyMapper.lua 파일 생성..."
touch ~/.config/nvim/lua/utils/keyMapper.lua || { echo "keyMapper.lua 파일 생성 실패"; exit 1; }

echo "keyMapper.lua 파일이 생성되었습니다."




# keyMapper.lua  내용 추가
echo "keyMapper.lua 파일 작성 중..."
cat <<EOL > ~/.config/nvim/lua/utils/keyMapper.lua
local keyMapper = function(from, to, mode, opts)
    local options = { noremap = true, silent = true }
    mode = mode or "n"
    
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end

    vim.keymap.set(mode, from, to, options)
end

return { mapKey = keyMapper }
EOL

echo "keyMapper.lua 파일이 작성되었습니다."



# globals.lua 파일 작성 및 내용 추가
echo "globals.lua 파일 작성 중..."
cat <<EOL > ~/.config/nvim/lua/config/globals.lua
vim.g.mapleader = " "  -- global leader
vim.g.maplocalleader = " "  -- local leader
EOL

echo "globals.lua 파일이 작성되었습니다."



# keymaps.lua 파일 작성 및 내용 추가
echo "keymaps.lua 파일 작성 중..."
cat <<EOL > ~/.config/nvim/lua/config/keymaps.lua
local mapKey = require("utils.keyMapper").mapKey

-- Neotree toggle
mapKey('<leader>e', ':Neotree toggle<cr>')

-- pane navigation
mapKey('<C-h>', '<C-w>h')  -- Left
mapKey('<C-j>', '<C-w>j')  -- Down
mapKey('<C-k>', '<C-w>k')  -- Up
mapKey('<C-l>', '<C-w>l')  -- Right

-- clear search hl
mapKey('<leader>h', ':nohlsearch<CR>')
EOL

echo "keymaps.lua 파일이 작성되었습니다."



# options.lua 파일 작성 및 내용 추가
echo "options.lua 파일 작성 중..."
cat <<EOL > ~/.config/nvim/lua/config/options.lua
local opt = vim.opt

-- tab/indent
opt.tabstop = 2           -- 탭 간격을 2칸으로 설정
opt.shiftwidth = 2        -- 코드 블록을 들여쓰기 할 때, 2칸 간격 사용
opt.softtabstop = 2       -- Soft 탭 간격을 2칸으로 설정
opt.expandtab = true      -- 탭을 스페이스로 변환
opt.smartindent = true    -- 자동으로 들여쓰기 추가
opt.wrap = false          -- 줄이 길어지더라도 자동으로 개행하지 않음

-- search
opt.incsearch = true      -- 검색할 때 입력할 때마다 즉시 결과 표시
opt.ignorecase = true     -- 대소문자 구분 없이 검색
opt.smartcase = true      -- 대소문자를 입력하면 구분하여 검색

-- visual
opt.number = true         -- 줄 번호 표시
opt.relativenumber = true -- 상대적인 줄 번호 표시
opt.termguicolors = true  -- 터미널 GUI 색상 활성화
opt.signcolumn = "yes"    -- 좌측에 시그널 열을 항상 표시

-- etc
opt.encoding = "UTF-8"    -- 파일 인코딩을 UTF-8로 설정
opt.cmdheight = 1         -- 명령어 입력창의 높이를 1줄로 설정
opt.scrolloff = 10        -- 화면의 상하단에서 10줄 이상 남도록 스크롤
opt.mouse:append("a")     -- 마우스 모든 모드에서 활성화
EOL

echo "options.lua 파일이 작성되었습니다."



# init.lua 파일에 필요한 require() 구문 추가
echo "init.lua 파일에서 lazy.nvim 설정 전에 require() 구문 추가 중..."

# 임시 파일에 init.lua를 작성하되, lazy.nvim 설정 전 require 구문 삽입
cat <<EOL > ~/.config/nvim/lua/config/init_temp.lua
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

-- Load additional configurations
require("config.globals")
require("config.keymaps")
require("config.options")

local plugins = "plugins"
local opts = {}

require("lazy").setup(plugins, opts)
EOL

# 기존 init.lua를 덮어씌움
mv ~/.config/nvim/lua/config/init_temp.lua ~/.config/nvim/lua/config/init.lua

echo "init.lua 파일에 require() 구문이 추가되었습니다."

echo "plugins/telescope.lua 파일 생성 및 설정 추가 중..."

# telescope.lua 파일 임시 작성
cat <<EOL > ~/.config/nvim/lua/plugins/telescope_temp.lua
local mapKey = require("utils.keyMapper").mapKey

return {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local builtin = require("telescope.builtin")
        
        -- 키 매핑 설정
        mapKey('<leader>ff', builtin.find_files)
        mapKey('<leader>fg', builtin.live_grep)
        mapKey('<leader>fb', builtin.buffers)
        mapKey('<leader>fh', builtin.help_tags)
    end,
}
EOL

# 기존 telescope.lua 파일 덮어씌움
mv ~/.config/nvim/lua/plugins/telescope_temp.lua ~/.config/nvim/lua/plugins/telescope.lua

echo "plugins/telescope.lua 파일이 덮어씌워졌습니다."


# nvim-treesitter.lua 파일 생성 및 설정 추가
echo "nvim-treesitter.lua 파일 생성 및 설정 추가 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/nvim-treesitter.lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = { "lua", "javascript", "html", "css" , "typescript" },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}
EOL

echo "nvim-treesitter.lua 파일이 생성되었습니다."



# indent-blankline.lua 파일 생성 및 설정 추가
echo "indent-blankline.lua 파일 생성 및 설정 추가 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/indent-blankline.lua
return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
}
EOL

echo "indent-blankline.lua 파일이 생성되었습니다."




echo "keymaps.lua 파일에 indent 관련 키매핑 추가 중..."

# 임시 파일에 keymaps.lua 내용을 작성하고 indent 키매핑 추가
cat <<EOL > ~/.config/nvim/lua/config/keymaps_temp.lua
local mapKey = require("utils.keyMapper").mapKey

-- Neotree toggle
mapKey('<leader>e', ':Neotree toggle<cr>')

-- pane navigation
mapKey('<C-h>', '<C-w>h')  -- Left
mapKey('<C-j>', '<C-w>j')  -- Down
mapKey('<C-k>', '<C-w>k')  -- Up
mapKey('<C-l>', '<C-w>l')  -- Right

-- clear search hl
mapKey('<leader>h', ':nohlsearch<CR>')

-- indent
mapKey('<', '<gv', 'v')   -- Indent left in visual mode
mapKey('>', '>gv', 'v')   -- Indent right in visual mode
EOL

# 기존 keymaps.lua 파일 덮어씌움
mv ~/.config/nvim/lua/config/keymaps_temp.lua ~/.config/nvim/lua/config/keymaps.lua

echo "keymaps.lua 파일에 indent 관련 키매핑이 추가되었습니다."



# comment.lua 파일 생성 및 설정 추가
echo "comment.lua 파일 생성 및 설정 추가 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/comment.lua
return {
    'numToStr/Comment.nvim',
    opts = {
        -- add any options here
    },
    lazy = false,
}
EOL

echo "comment.lua 파일이 생성되었습니다."

# lualine.lua 파일 생성 및 설정 추가
echo "lualine.lua 파일 생성 및 설정 추가 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/lualine.lua
return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require("lualine").setup({
            options = {
                theme = "gruvbox"
            }
        })
    end
}
EOL

echo "lualine.lua 파일이 생성되었습니다."



# lsp.lua 파일 생성 및 설정 추가
echo "lsp.lua 파일 생성 및 설정 추가 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/lsp.lua
return {
    {
        "williamboman/mason.nvim",
        config = function()
            require('mason').setup()
        end
    },
}
EOL

echo "lsp.lua 파일이 생성되었습니다."



# lsp.lua 파일 덮어쓰기
echo "lsp.lua 파일 덮어쓰기 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/lsp.lua

local keyMapper = require('utils.keyMapper').mapKey

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require('mason').setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = { "lua_ls", "ts_ls"  }
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require('lspconfig')
            lspconfig.lua_ls.setup({})
            lspconfig.ts_ls.setup({})

            -- LSP key mappings
            keyMapper('K', vim.lsp.buf.hover)           -- hover documentation
            keyMapper('gd', vim.lsp.buf.definition)      -- go to definition
            keyMapper('<leader>ca', vim.lsp.buf.code_action) -- code action
        end
    },
}
EOL


echo "lsp.lua 파일이 덮어씌워졌습니다."



# telescope.lua 파일 덮어쓰기
echo "telescope.lua 파일 덮어쓰기 중..."
cat <<EOL > ~/.config/nvim/lua/plugins/telescope_temp.lua
local mapKey = require("utils.keyMapper").mapKey

return {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope-ui-select.nvim' },  -- ui-select 확장을 추가
    config = function()
        local builtin = require("telescope.builtin")
        
        -- 키 매핑 설정
        mapKey('<leader>ff', builtin.find_files)
        mapKey('<leader>fg', builtin.live_grep)
        mapKey('<leader>fb', builtin.buffers)
        mapKey('<leader>fh', builtin.help_tags)

        -- 첫 번째 이미지의 설정 추가
        require('telescope').setup({
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown {}
                }
            }
        })
        require("telescope").load_extension("ui-select")
    end
}
EOL

# 기존 telescope.lua 파일 덮어씌움
mv ~/.config/nvim/lua/plugins/telescope_temp.lua ~/.config/nvim/lua/plugins/telescope.lua

echo "plugins/telescope.lua 파일이 덮어씌워졌습니다."




echo "스크립트 실행 완료."