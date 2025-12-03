# DeepSeek CLI - Quick Start Guide

Get up and running with DeepSeek CLI in 3 minutes!

## 1. Install (One-time setup)

```bash
# Run the setup script
./setup.sh

# Or manual installation
pip3 install openai click
chmod +x deepseek-cli.py
```

## 2. Get API Key

1. Go to [DeepSeek Platform](https://platform.deepseek.com/api_keys)
2. Sign up or log in
3. Create a new API key
4. Copy it (you won't see it again!)

## 3. Configure

```bash
# Set your API key
./deepseek-cli.py config --api-key sk-your-key-here
```

Or use environment variable:
```bash
export DEEPSEEK_API_KEY="sk-your-key-here"
```

## 4. Start Using!

### Simple Chat
```bash
./deepseek-cli.py chat "Hello! How are you?"
```

### Interactive Mode
```bash
./deepseek-cli.py interactive
```
Type messages, press Enter. Type `exit` to quit.

### Advanced Examples

**1. Using Thinking Mode (for complex problems):**
```bash
./deepseek-cli.py chat --thinking-mode "Explain the implications of quantum computing on cryptography"
```

**2. Set Context with System Message:**
```bash
./deepseek-cli.py chat --system "You are a helpful Python coding assistant" "How do I write a decorator?"
```

**3. Streaming Response:**
```bash
./deepseek-cli.py chat --stream "Tell me a story about a robot learning to paint"
```

**4. Control Creativity:**
```bash
# Low temperature = more focused/consistent
./deepseek-cli.py chat --temperature 0.3 "What is 2+2?"

# High temperature = more creative
./deepseek-cli.py chat --temperature 1.5 "Write a poem about coding"
```

**5. Limit Response Length:**
```bash
./deepseek-cli.py chat --max-tokens 100 "Summarize machine learning"
```

## 5. Useful Commands

```bash
# List all models
./deepseek-cli.py models

# Check account balance
./deepseek-cli.py balance

# Show version
./deepseek-cli.py version

# Get full help
./deepseek-cli.py --help
```

## Interactive Mode Tips

Once in interactive mode:
- **Regular messages**: Just type and press Enter
- **Clear history**: Type `clear`
- **Help**: Type `help`
- **Exit**: Type `exit`, `quit`, or `q`

## Troubleshooting

### "API key not found"
```bash
# Set it manually
export DEEPSEEK_API_KEY="your-key-here"

# Or use config
./deepseek-cli.py config --api-key your-key-here
```

### "No module named 'openai'"
```bash
pip3 install openai click
```

### Command not found
```bash
# Use full path
./deepseek-cli.py chat "Hello"

# Or install system-wide
sudo cp deepseek-cli.py /usr/local/bin/deepseek-cli
```

## Examples Gallery

### Example 1: Code Review
```bash
./deepseek-cli.py chat --system "You are a senior software engineer" "Can you review this Python code?"
```

### Example 2: Learning Assistant
```bash
./deepseek-cli.py chat --system "You are a patient teacher explaining concepts to beginners" "What is a hash table?"
```

### Example 3: Creative Writing
```bash
./deepseek-cli.py chat --temperature 1.2 "Write a short story about a time-traveling programmer"
```

### Example 4: Technical Analysis
```bash
./deepseek-cli.py chat --thinking-mode "Analyze the trade-offs between microservices and monolithic architecture"
```

### Example 5: Interactive Q&A
```bash
./deepseek-cli.py interactive --model deepseek-reasoner
# Now chat with the AI, building on previous answers
```

## Configuration File

Your settings are saved to: `~/.deepseek_config.json`

```json
{
  "api_key": "sk-your-key-here",
  "base_url": "https://api.deepseek.com"
}
```

## Next Steps

- Read the full [README.md](README.md) for complete documentation
- Explore different models with `--model` flag
- Experiment with temperature and other parameters
- Try interactive mode for multi-turn conversations

## Need Help?

- DeepSeek API Docs: https://api-docs.deepseek.com/
- Platform: https://platform.deepseek.com/
- Support: api-service@deepseek.com

Happy chatting! 🚀
