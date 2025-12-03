#!/bin/bash

# DeepSeek CLI Setup Script

echo "=========================================="
echo "  DeepSeek CLI Installation"
echo "=========================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed."
    echo "Please install Python 3.7 or higher."
    exit 1
fi

echo "✓ Python 3 found"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is not installed."
    echo "Please install pip3."
    exit 1
fi

echo "✓ pip3 found"

# Install dependencies
echo ""
echo "Installing dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "✗ Failed to install dependencies"
    exit 1
fi

# Make CLI executable
echo ""
echo "Making CLI executable..."
chmod +x deepseek-cli.py

if [ $? -eq 0 ]; then
    echo "✓ CLI made executable"
else
    echo "✗ Failed to make CLI executable"
    exit 1
fi

# Optionally move to /usr/local/bin
echo ""
read -p "Move deepseek-cli.py to /usr/local/bin for system-wide access? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if sudo mv deepseek-cli.py /usr/local/bin/deepseek-cli; then
        echo "✓ Moved to /usr/local/bin/deepseek-cli"
        echo ""
        echo "You can now use 'deepseek-cli' from anywhere!"
        echo ""
        echo "Next steps:"
        echo "  1. Get your API key: https://platform.deepseek.com/api_keys"
        echo "  2. Configure: deepseek-cli config --api-key YOUR_KEY"
        echo "  3. Start chatting: deepseek-cli chat 'Hello!'"
    else
        echo "✗ Failed to move to /usr/local/bin"
        echo "You can still use: ./deepseek-cli.py"
    fi
else
    echo "Keeping deepseek-cli.py in current directory"
    echo ""
    echo "Next steps:"
    echo "  1. Get your API key: https://platform.deepseek.com/api_keys"
    echo "  2. Configure: ./deepseek-cli.py config --api-key YOUR_KEY"
    echo "  3. Start chatting: ./deepseek-cli.py chat 'Hello!'"
fi

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "For help, run: ./deepseek-cli.py --help"
echo ""
