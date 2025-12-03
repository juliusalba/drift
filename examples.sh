#!/bin/bash

# DeepSeek CLI Examples
# This script demonstrates various uses of the DeepSeek CLI

echo "=========================================="
echo "  DeepSeek CLI Examples"
echo "=========================================="
echo ""

# Check if CLI exists
if [ ! -f "deepseek-cli.py" ]; then
    echo "Error: deepseek-cli.py not found in current directory"
    exit 1
fi

echo "These examples show how to use the DeepSeek CLI"
echo "Make sure you've configured your API key first!"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 1
echo ""
echo "=========================================="
echo "Example 1: Simple Chat"
echo "=========================================="
echo "Command:"
echo '  ./deepseek-cli.py chat "Hello! How are you?"'
echo ""
read -p "Run this example? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deepseek-cli.py chat "Hello! How are you?"
fi

# Example 2
echo ""
echo "=========================================="
echo "Example 2: Interactive Mode"
echo "=========================================="
echo "Command:"
echo "  ./deepseek-cli.py interactive"
echo ""
echo "This starts a chat session where you can have"
echo "a conversation with the AI. Type 'exit' to quit."
echo ""
read -p "Start interactive mode? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deepseek-cli.py interactive
fi

# Example 3
echo ""
echo "=========================================="
echo "Example 3: With System Message"
echo "=========================================="
echo "Command:"
echo '  ./deepseek-cli.py chat --system "You are a helpful assistant" "What is Python?"'
echo ""
read -p "Run this example? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deepseek-cli.py chat --system "You are a helpful assistant" "What is Python?"
fi

# Example 4
echo ""
echo "=========================================="
echo "Example 4: Thinking Mode"
echo "=========================================="
echo "Command:"
echo '  ./deepseek-cli.py chat --thinking-mode "Explain how neural networks work"'
echo ""
read -p "Run this example? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deepseek-cli.py chat --thinking-mode "Explain how neural networks work"
fi

# Example 5
echo ""
echo "=========================================="
echo "Example 5: List Models"
echo "=========================================="
echo "Command:"
echo "  ./deepseek-cli.py models"
echo ""
read -p "Run this example? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./deepseek-cli.py models
fi

echo ""
echo "=========================================="
echo "  End of Examples"
echo "=========================================="
echo ""
echo "For more examples, check out:"
echo "  - README.md (complete documentation)"
echo "  - QUICKSTART.md (getting started guide)"
echo ""
