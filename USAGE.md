# DeepSeek CLI - Quick Usage Guide

## 🎯 What You Can Do Now

Just type **`deepseek`** in your terminal and start chatting immediately!

### Example Session:
```bash
$ deepseek

============================================================
DeepSeek Interactive Chat Mode
Type 'exit' or 'quit' to end the session
Type 'clear' to clear conversation history
============================================================

You: Hello! What can you help me with?
DeepSeek: Hello! I'm DeepSeek, and I can help you with a wide variety of tasks...

You: Can you write Python code?
DeepSeek: Absolutely! What would you like to build?

You: exit
Goodbye!
```

## 📋 Commands

### Main Interface
- **`deepseek`** - Start chatting immediately (opens interactive mode)
- **`deepseek --help`** - Show all available commands
- **`deepseek version`** - Show version info

### Chat Options
- **`deepseek chat "message"`** - Send single message and exit
- **`deepseek interactive`** - Start interactive mode (same as `deepseek`)
- **`deepseek chat --thinking-mode "question"`** - Use reasoning mode for complex problems
- **`deepseek chat --stream "prompt"`** - Get streaming response
- **`deepseek chat --model deepseek-chat "message"`** - Use specific model
- **`deepseek chat --system "You are a..." "message"`** - Set context

### Other Commands
- **`deepseek models`** - List all available models
- **`deepseek config --api-key YOUR_KEY`** - Configure API key
- **`deepseek balance`** - Check account balance

## 🔑 Setup Required

You need a valid API key:

1. Get one from: https://platform.deepseek.com/api_keys
2. Configure it:
   ```bash
   deepseek config --api-key sk-your-new-key-here
   ```

## 💡 Tips

- Type **`clear`** in chat to start a fresh conversation
- Use **`--thinking-mode`** for complex analysis and reasoning
- Use **`--stream`** to see responses appear in real-time
- Set **`--temperature`** (0.0-2.0) to control creativity (lower = more focused)

## 🆘 Troubleshooting

**"API key not found" or "Authentication Fails"**
→ Get a new API key and run: `deepseek config --api-key YOUR_KEY`

**"command not found: deepseek"**
→ Make sure you have sourced your shell config or restart terminal

**Want to go back to the old deepseek?**
→ It's backed up at: `/Users/juliusalba/.venvs/deepseek/bin/deepseek-old.bak`
