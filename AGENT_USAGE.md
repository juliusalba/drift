# DeepSeek Agent - Agentic Terminal

An intelligent terminal assistant that can execute commands, read/write files, and perform tasks autonomously.

## What is an Agentic Terminal?

Unlike a regular chat interface, an **agentic terminal** can:
- ✅ Execute shell commands
- ✅ Read and write files
- ✅ List directories
- ✅ Perform multi-step tasks
- ✅ Understand natural language requests and convert them to actions

## Usage

### Interactive Mode (Recommended)
```bash
deepseek-agent
```

Then simply describe what you want to do:
```
What would you like me to do? List files in the current directory
DeepSeek wants to execute: ls -la
Execute? (y/N): y
[Directory listing appears]

What would you like me to do? Create a Python script called hello.py that prints "Hello World"
DeepSeek will create the file for you (with confirmation)

What would you like me to do? Find all Python files in this directory
DeepSeek will search and list them
```

### Direct Commands

**Execute a shell command:**
```bash
deepseek-agent exec "ls -la"
deepseek-agent exec "pip install requests"
```

**Read a file:**
```bash
deepseek-agent read README.md
```

**List directory:**
```bash
deepseek-agent ls .
deepseek-agent ls /Users/juliusalba
```

**Execute a task:**
```bash
deepseek-agent do "Create a new directory called test"
deepseek-agent do "Find all .py files and show their sizes"
```

## Examples

### Example 1: File Operations
```bash
$ deepseek-agent

What would you like me to do? Read the contents of deepseek-cli.py
✓ Reads and displays the file

What would you like me to do? Create a backup of this file
✓ Creates deepseek-cli.py.backup
```

### Example 2: Command Execution
```bash
$ deepseek-agent

What would you like me to do? Show me the current directory and list all files
DeepSeek will execute: pwd && ls -la
✓ Shows current path and file listing
```

### Example 3: Task Automation
```bash
$ deepseek-agent

What would you like me to do? Create a Python virtual environment in a folder called myproject
DeepSeek will:
  1. Create the myproject directory
  2. Set up a virtual environment
  3. Show you the commands it ran
```

### Example 4: File Search
```bash
$ deepseek-agent

What would you like me to do? Search for all files containing "deepseek" in the current directory
DeepSeek will search and show matching files
```

## Safety Features

- **Confirmation prompts** before executing commands
- **Shows intended command** before execution
- **Error reporting** if commands fail
- **Safe by default** - won't execute destructive commands without explicit permission

## Commands in Agent Mode

When running `deepseek-agent` interactively:

- **Natural language**: Just describe your task
- **exec <command>**: Execute a command directly
  ```
  exec ls -la
  ```
- **help**: Show help information
- **exit** or **quit**: Exit the agent

## Advanced Features

### Multi-Step Tasks
The agent can handle complex requests:
```
"What would you like me to do? Create a complete Python project structure with src/, tests/, and README.md"
```

The agent will:
1. Create the directory structure
2. Generate appropriate files
3. Show you what was created

### File Operations
```
"What would you like me to do? Read config.json and tell me what's in it"
```
- Reads the file
- Analyzes the content
- Explains what it found

### Search and Discovery
```
"What would you like me to do? Find all Python files larger than 1KB in the current directory"
```
- Searches recursively
- Filters by size
- Shows results with details

## Integration with DeepSeek Chat

The agent uses DeepSeek v3.2 to:
- Understand natural language requests
- Plan the sequence of commands needed
- Execute them safely
- Report results

## Differences from Regular Chat

| Feature | Regular Chat | Agentic Terminal |
|---------|-------------|------------------|
| Execute commands | ❌ No | ✅ Yes |
| Read files | ❌ No | ✅ Yes |
| Write files | ❌ No | ✅ Yes |
| Perform tasks | ❌ No | ✅ Yes |
| Multi-step actions | ❌ No | ✅ Yes |

## Getting Started

1. **Start the agent:**
   ```bash
   deepseek-agent
   ```

2. **Try a simple task:**
   ```
   What would you like me to do? List files in current directory
   ```

3. **Try something advanced:**
   ```
   What would you like me to do? Create a Python script that downloads a file from the internet
   ```

## Troubleshooting

**"command not found: deepseek-agent"**
- Make sure you have sourced your shell config
- Or restart your terminal

**Permission denied errors**
- The agent asks for confirmation before running commands
- Some commands may need your password (sudo, etc.)

**File not found**
- Use full paths or navigate to the correct directory first
- Use `exec pwd` to see where you are

## Examples Gallery

### Development Tasks
```
"Create a new Git repository"
"Install Node.js and npm"
"Set up a Python virtual environment"
"Find all TODO comments in my code"
```

### File Management
```
"Show me the largest files in this directory"
"Create a backup of my project folder"
"Find duplicate files"
"Show me all image files"
```

### System Information
```
"Show me disk usage"
"List running processes"
"Check system memory"
"What ports are being used?"
```

## Tips

1. **Be specific**: "List Python files in /Users/juliusalba" vs "list files"
2. **Natural language**: You can say "show me" instead of "ls"
3. **Confirmation**: The agent will ask before doing anything potentially destructive
4. **Errors**: If a command fails, the agent will explain why and suggest alternatives
5. **Combine tasks**: "Create a directory, then create a file in it, then show me both"

## Next Steps

- Use `exec <command>` for quick direct command execution
- Use natural language for complex multi-step tasks
- Try `deepseek-agent do "<task>"` for single-shot task execution
- Combine with regular `deepseek` command for conversational help

Happy agent-ing! 🤖
