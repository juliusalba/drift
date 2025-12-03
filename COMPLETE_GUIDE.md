# DeepSeek CLI & Agent - Complete Guide

You now have a **complete DeepSeek terminal system** with both chat and agentic capabilities!

## 🎯 What You Have

### Two Interfaces:

1. **`deepseek`** - Chat Mode (just talk)
2. **`deepseek-agent`** - Agentic Mode (does things)

---

## 📋 Quick Reference

### Chat Mode (`deepseek`)

```bash
# Start chatting immediately
deepseek

# Single message
deepseek chat "Hello"

# With thinking mode
deepseek chat --thinking-mode "Explain quantum computing"

# Streaming response
deepseek chat --stream "Tell me a story"

# Other commands
deepseek models              # List models
deepseek version             # Version info
deepseek config --api-key X  # Configure
```

### Agentic Mode (`deepseek-agent`)

```bash
# Start interactive agent
deepseek-agent

# Then just describe what you want:
# "List files in current directory"
# "Create a Python script"
# "Install the requests package"
# "Find all .py files"

# Or use direct commands:
deepseek-agent exec "ls -la"           # Execute shell command
deepseek-agent read file.txt           # Read a file
deepseek-agent ls /path/to/dir         # List directory
deepseek-agent do "create test.py"     # Execute a task
```

---

## 🔍 What's the Difference?

| Feature | `deepseek` (Chat) | `deepseek-agent` (Agent) |
|---------|-------------------|--------------------------|
| **Answers questions** | ✅ Yes | ✅ Yes |
| **Execute commands** | ❌ No | ✅ Yes |
| **Read files** | ❌ No | ✅ Yes |
| **Write files** | ❌ No | ✅ Yes |
| **List directories** | ❌ No | ✅ Yes |
| **Multi-step tasks** | ❌ No | ✅ Yes |
| **Natural language to actions** | ❌ No | ✅ Yes |

---

## 🚀 How to Use

### Use Chat Mode When:
- You want information or explanations
- You need help understanding something
- You want to have a conversation
- You're learning or exploring concepts

**Example:**
```bash
deepseek
> "How do neural networks work?"
> "Explain the difference between Python lists and tuples"
> "What is Docker?"
```

### Use Agentic Mode When:
- You want to **do** something, not just learn
- You need to execute commands
- You want to automate tasks
- You need to create, read, or modify files
- You want multi-step task automation

**Example:**
```bash
deepseek-agent
> "List all Python files in the current directory"
> "Create a virtual environment for my project"
> "Find all TODO comments in my code"
> "Install Node.js and create a new project"
> "Create a backup of my project folder"
```

---

## 📝 Detailed Examples

### Example 1: Learning vs Doing

**Learning (use `deepseek`):**
```bash
$ deepseek
> "How do I reverse a string in Python?"
DeepSeek explains the concept, methods, and gives examples
```

**Doing (use `deepseek-agent`):**
```bash
$ deepseek-agent
> "Create a Python script that reverses a string"
Agent creates the file with working code
```

### Example 2: Explore vs Execute

**Explore (use `deepseek`):**
```bash
$ deepseek
> "What are the best practices for Python projects?"
DeepSeek explains best practices
```

**Execute (use `deepseek-agent`):**
```bash
$ deepseek-agent
> "Create a Python project structure with src/, tests/, and docs/"
Agent creates the complete directory structure
```

### Example 3: File Operations

**Read (use `deepseek-agent`):**
```bash
$ deepseek-agent read README.md
[Shows file contents]

$ deepseek-agent
> "Show me what's in the config file"
[Agent reads and explains the file]
```

**Write (use `deepseek-agent`):**
```bash
$ deepseek-agent
> "Create a Python script that downloads a file from the internet"
Agent creates the script, asks for confirmation, then writes it
```

---

## 🔧 Advanced Features

### Agentic Mode Capabilities

1. **Command Execution**
   - Execute any shell command
   - See output in real-time
   - Safety confirmation for dangerous commands

2. **File Operations**
   - Read any file
   - Write new files
   - Create backups
   - Search for text in files

3. **Directory Operations**
   - List directory contents
   - Find files by name, size, type
   - Navigate directories

4. **Task Automation**
   - Multi-step task execution
   - Natural language to commands
   - Error handling and recovery

5. **Safety Features**
   - Confirmation before executing
   - Shows intended commands
   - Error reporting
   - Safe defaults

---

## 📚 File Locations

### Core Files:
- `/Users/juliusalba/deepseek-cli.py` - Chat interface
- `/Users/juliusalba/deepseek-agent.py` - Agent interface
- `/Users/juliusalba/.deepseek_config.json` - API key storage
- `/Users/juliusalba/.venvs/deepseek/bin/deepseek` - Chat wrapper
- `/Users/juliusalba/.venvs/deepseek/bin/deepseek-agent` - Agent wrapper

### Documentation:
- `/Users/juliusalba/COMPLETE_GUIDE.md` - This file
- `/Users/juliusalba/AGENT_USAGE.md` - Detailed agent docs
- `/Users/juliusalba/USAGE.md` - Chat mode docs
- `/Users/juliusalba/README.md` - Complete documentation
- `/Users/juliusalba/QUICKSTART.md` - Quick start guide

### Scripts:
- `/Users/juliusalba/AGENT_EXAMPLES.sh` - Agent examples demo
- `/Users/juliusalba/examples.sh` - Chat examples demo
- `/Users/juliusalba/setup.sh` - Installation script

---

## 💡 Pro Tips

### Chat Mode Tips:
- Use `--thinking-mode` for complex reasoning
- Use `--stream` to see responses in real-time
- Use `--system` to set context
- Use `--temperature` to control creativity

### Agent Mode Tips:
- Be specific: "List Python files in /Users/juliusalba" vs "list files"
- Use natural language: "show me" instead of "ls"
- Combine tasks: "create a directory, then create a file in it"
- The agent asks for confirmation before doing anything

### When to Use Which:
- **Learning/Questions** → `deepseek`
- **Doing/Automation** → `deepseek-agent`
- **Both** → Use both! Chat to understand, agent to execute

---

## 🆘 Troubleshooting

### "command not found: deepseek"
- Restart your terminal OR run: `source ~/.zshrc`

### "command not found: deepseek-agent"
- The command should be available
- Check: `/Users/juliusalba/.venvs/deepseek/bin/deepseek-agent`
- Restart terminal

### API key issues
- Your key is in: `/Users/juliusalba/.deepseek_config.json`
- Update with: `deepseek config --api-key YOUR_KEY`
- Make sure the key is valid at: https://platform.deepseek.com/api_keys

### Agent permissions
- Agent asks confirmation before running commands
- For direct execution without prompt: `deepseek-agent exec "command"`
- Some commands may need your password (sudo, etc.)

---

## 🎓 Learning Path

### Beginner:
1. Start with: `deepseek` (chat mode)
2. Try: `deepseek --help`
3. Ask questions and learn

### Intermediate:
1. Try: `deepseek-agent` (agent mode)
2. Use: `exec` for direct commands
3. Practice: file operations, directory listing

### Advanced:
1. Use natural language: "create a Python project"
2. Combine tasks: multi-step automation
3. Use thinking mode: `deepseek chat --thinking-mode`

### Expert:
1. Automate your workflow
2. Create complex scripts with agent
3. Integrate into your development process

---

## 🔗 Command Reference

### DeepSeek Chat Commands:
```bash
deepseek                    # Start interactive chat
deepseek chat "message"     # Single message
deepseek models             # List models
deepseek version            # Version info
deepseek config --api-key X # Configure
deepseek balance            # Check balance
```

### DeepSeek Agent Commands:
```bash
deepseek-agent              # Start interactive agent
deepseek-agent exec "cmd"   # Execute command
deepseek-agent read <file>  # Read file
deepseek-agent ls <path>    # List directory
deepseek-agent do <task>    # Execute task
deepseek-agent version      # Version info
```

---

## ✅ You're Ready!

You now have:
- ✅ A working chat interface (`deepseek`)
- ✅ A fully functional agent (`deepseek-agent`)
- ✅ API key configured and working
- ✅ Complete documentation
- ✅ Example scripts

**Start using:**
```bash
deepseek              # For questions and chat
deepseek-agent        # For doing and automation
```

**Documentation:**
- `/Users/juliusalba/COMPLETE_GUIDE.md` (this file)
- `/Users/juliusalba/AGENT_USAGE.md` (agent details)
- `/Users/juliusalba/USAGE.md` (chat details)

Happy coding! 🚀
