#!/usr/bin/env bash

set -e

RAW_BASE="https://raw.githubusercontent.com/h0jicha/setup/HEAD"

# OS 判定
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v apt &> /dev/null; then
    OS_TYPE="debian"
  else
    OS_TYPE="linux"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ $(uname -m) == "arm64" ]]; then
    OS_TYPE="mac_arm64"
  else
    echo "Unsupported Mac architecture: $(uname -m)"
    exit 1
  fi
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

echo "Detected OS: $OS_TYPE"

# Ansible / curl / git が未インストールの場合にインストール
install_prereqs() {
  case "$OS_TYPE" in
    debian)
      sudo apt update
      sudo apt install -y ansible curl git
      ;;
    mac)
      # Homebrew が無い場合はインストール
      if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing..."
        yes "" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo >> ~/.zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        source ~/.zprofile
      fi
      brew install ansible curl git
      ;;
    linux)
      # 上記以外の Linux ディストリビューション向けの処理を追加
      sudo apt update || true
      sudo apt install -y ansible curl git || true
      ;;
  esac
}

install_prereqs

# Ansible Playbook のダウンロード先
PLAYBOOK="${OS_TYPE}_setup.yml"
TMP_PLAYBOOK="/tmp/${PLAYBOOK}"

echo "Downloading $PLAYBOOK from $RAW_BASE/ansible/${PLAYBOOK} ..."
curl -fsSL "$RAW_BASE/ansible/${PLAYBOOK}" -o "$TMP_PLAYBOOK"
curl -fsSL "$RAW_BASE/Brewfile" -o /tmp/Brewfile

# ansible-playbook 実行
echo "Running ansible-playbook $TMP_PLAYBOOK ..."
ansible-playbook "$TMP_PLAYBOOK" --ask-become-pass

echo "Setup completed successfully!"
