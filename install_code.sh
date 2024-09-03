#!/bin/bash

# VS Code executable path
VSCODE_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# Destination path in /usr/local/bin
DEST_PATH="/usr/local/bin/code"

# Check if the code command is already linked
if [ ! -f "$DEST_PATH" ]; then
    echo "Installing 'code' command in PATH..."
    sudo ln -s "$VSCODE_PATH" "$DEST_PATH"
    echo "'code' command has been installed."
else
    echo "'code' command is already installed."
fi
