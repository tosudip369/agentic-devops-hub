#!/bin/bash
# Universal Unix Bootstrapper for Agentic DevOps Hub
echo "🚀 Bootstrapping Agentic Hub for Unix/macOS..."
if ! command -v pwsh &> /dev/null; then
    echo "⚠️ PowerShell Core not found. Auto-installing for cross-platform parity..."
    if [[ "\" == "darwin"* ]]; then
        brew install --cask powershell
    elif [[ -f /etc/os-release ]]; then
        # Standard Ubuntu/Debian install
        sudo apt-get update && sudo apt-get install -y wget apt-transport-https software-properties-common
        wget -q "https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb"
        sudo dpkg -i packages-microsoft-prod.deb
        sudo apt-get update && sudo apt-get install -y powershell
    else
        echo "❌ Unsupported Unix variant for auto-install. Please install 'pwsh' manually."
        exit 1
    fi
fi
echo "✅ Environment Ready. Activating Hub..."
pwsh -File ./activate.ps1
