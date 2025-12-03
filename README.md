# DeepSeek CLI

A powerful command-line interface for interacting with DeepSeek v3.2 AI models.

## Features

- **Chat Completions**: Send individual messages or have conversations
- **Interactive Mode**: Chat continuously with conversation history
- **Multiple Models**: Support for both `deepseek-chat` and `deepseek-reasoner`
- **Thinking Mode**: Enable reasoning mode for complex tasks
- **Streaming**: Real-time streaming responses
- **Configurable**: Easy API key setup and configuration
- **Token Tracking**: Monitor token usage

## Installation

### Prerequisites

- Python 3.7+
- pip

### Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Make the CLI executable (optional):**
   ```bash
   chmod +x deepseek-cli.py
   ```

3. **Get your API key:**
   - Visit [DeepSeek Platform](https://platform.deepseek.com/api_keys)
   - Create an API key

## Configuration

### Method 1: Environment Variable
```bash
export DEEPSEEK_API_KEY="your-api-key-here"
```

### Method 2: Config Command
```bash
./deepseek-cli.py config --api-key your-api-key-here
```

## Usage

### Quick Chat
```bash
# Simple chat with default model
./deepseek-cli.py chat "Hello, how are you?"

# Chat with specific model
./deepseek-cli.py chat --model deepseek-reasoner "Explain quantum physics"

# With system message
./deepseek-cli.py chat --system "You are a helpful assistant" "What is 2+2?"

# Streaming response
./deepseek-cli.py chat --stream "Tell me a story"

# Thinking mode
./deepseek-cli.py chat --thinking-mode "Solve this complex problem"
```

### Interactive Mode
```bash
# Start interactive chat
./deepseek-cli.py interactive

# With specific model
./deepseek-cli.py interactive --model deepseek-reasoner
```

**Interactive Commands:**
- `help` - Show help
- `clear` - Clear conversation history
- `exit` or `quit` - Exit interactive mode

### List Models
```bash
./deepseek-cli.py models
```

### Check Balance
```bash
./deepseek-cli.py balance
```

## Command Reference

### chat
Send a single chat message.

**Options:**
- `--model, -m`: Model to use (`deepseek-chat` or `deepseek-reasoner`)
- `--system, -s`: System message for context
- `--temperature, -t`: Sampling temperature (0.0-2.0, default: 0.7)
- `--max-tokens, -M`: Maximum tokens to generate
- `--stream`: Enable streaming response
- `--thinking-mode`: Enable thinking mode (uses deepseek-reasoner)

### interactive
Start an interactive chat session with conversation history.

**Options:**
- `--model, -m`: Default model to use
- `--temperature, -t`: Default temperature

### models
List all available DeepSeek models.

### balance
Check account balance and usage information.

### config
Configure API key and settings.

**Options:**
- `--api-key`: Your DeepSeek API key
- `--base-url`: API base URL (default: https://api.deepseek.com)

### version
Show version information.

## Examples

### Example 1: Simple Question
```bash
$ ./deepseek-cli.py chat "What is machine learning?"

============================================================
Model: deepseek-chat
Created: 2025-12-03 10:30:00
============================================================

Machine learning is a subset of artificial intelligence...
```

### Example 2: With System Context
```bash
$ ./deepseek-cli.py chat --system "You are a Python expert" "How do I reverse a list?"

# DeepSeek will respond with Python-specific guidance
```

### Example 3: Thinking Mode
```bash
$ ./deepseek-cli.py chat --thinking-mode "Analyze the pros and cons of microservices architecture"

# Uses deepseek-reasoner for deeper analysis
```

### Example 4: Interactive Session
```bash
$ ./deepseek-cli.py interactive

You: What is Python?
DeepSeek: Python is a high-level, interpreted programming language...
You: Tell me more about its features
DeepSeek: Python has several key features...
[Tokens: 1250]
```

## Models

### deepseek-chat
- Non-thinking mode of DeepSeek-V3.2
- Fast responses
- Best for general conversations and tasks
- Default model

### deepseek-reasoner
- Thinking mode of DeepSeek-V3.2
- Uses reasoning for complex problems
- Best for complex analysis and problem-solving
- Enable with `--thinking-mode` flag

## Environment Variables

- `DEEPSEEK_API_KEY`: Your API key (alternative to config file)

## Configuration File

The CLI saves configuration to `~/.deepseek_config.json`:
```json
{
  "api_key": "your-api-key-here",
  "base_url": "https://api.deepseek.com"
}
```

## Troubleshooting

### "API key not found" error
- Set `DEEPSEEK_API_KEY` environment variable, or
- Run `./deepseek-cli.py config --api-key YOUR_KEY`

### ImportError: No module named 'openai'
- Run: `pip install -r requirements.txt`

### Connection errors
- Check your internet connection
- Verify API key is correct
- Ensure you have access to DeepSeek API

## License

MIT

## Support

- DeepSeek API Documentation: https://api-docs.deepseek.com/
- DeepSeek Platform: https://platform.deepseek.com/
- Email: api-service@deepseek.com
