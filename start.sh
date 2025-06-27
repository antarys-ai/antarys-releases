#!/bin/bash

set -e

INSTALL_DIR="/usr/bin"
BINARY_NAME="antarys"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

detect_platform() {
    OS=$(uname -s)
    ARCH=$(uname -m)

    case "$OS" in
        Darwin)
            if [[ "$ARCH" == "arm64" ]]; then
                echo "apple-arm"
            else
                echo "Unsupported: macOS requires ARM architecture (M1/M2/M3)"
                exit 1
            fi
            ;;
        Linux)
            if [[ "$ARCH" == "x86_64" ]]; then
                echo "linux-x64"
            else
                echo "Unsupported: Linux requires x86_64 architecture"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

download_and_extract() {
    local platform=$1
    local url="https://github.com/antarys-ai/antarys-releases/releases/download/preview/antarys-${platform}.zip"
    local zip_file="$TEMP_DIR/antarys-${platform}.zip"

    echo "Downloading Antarys for $platform..."
    curl -L -o "$zip_file" "$url"

    echo "Extracting archive..."
    cd "$TEMP_DIR"
    unzip -q "$zip_file"

    if [[ ! -f "$TEMP_DIR/$BINARY_NAME" ]]; then
        echo "Error: Binary not found in archive"
        exit 1
    fi
}

install_binary() {
    echo "Installing Antarys to $INSTALL_DIR..."

    if [[ -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
        echo "Existing Antarys installation found, replacing..."
        sudo rm -f "$INSTALL_DIR/$BINARY_NAME"
    fi

    sudo cp "$TEMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

    echo "Antarys installed successfully"
}

verify_installation() {
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        echo "Antarys is now available in PATH"
        antarys --version 2>/dev/null || echo "Antarys binary installed"
    else
        echo "Warning: Antarys may not be in PATH"
    fi
}

main() {
    echo "Antarys Preview Installer"

    PLATFORM=$(detect_platform)
    echo "Detected platform: $PLATFORM"

    download_and_extract "$PLATFORM"
    install_binary
    verify_installation

    echo "Installation complete"
}

main "$@"
