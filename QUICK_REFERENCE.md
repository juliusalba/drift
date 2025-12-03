# DeepSeek - Quick Reference

## 🎯 **One Command: `deepseek`**

Just type `deepseek` and you get everything:

```
$ deepseek

[Analyzes your project]

What would you like me to do?
```

---

## 📚 **What You Can Ask**

### **Questions (Get Answers)**
```
What is machine learning?
How does Python's async work?
Explain REST vs GraphQL
What's the difference between SQL and NoSQL?
Can you explain quantum computing?
How do I center a div in CSS?
```

### **Code (Get Code)**
```
Create a Python function to reverse a string
Write a FastAPI endpoint that returns JSON
Build a React component for a button
Make a script that downloads a file
Create a Django model for User
```

### **Commands (Execute)**
```
List all Python files in this directory
Install the requests package
Create a virtual environment
Show me disk usage
Run my tests
```

### **Files (Read/Write)**
```
Show me what's in README.md
Create a new file called utils.py
Find all TODO comments in my code
Read the config.json file
Add error handling to main.py
```

### **Automation (Complex Tasks)**
```
Create a complete REST API
Set up user authentication
Add tests to my project
Create a Docker container
Set up a CI/CD pipeline
```

---

## 💻 **Commands Reference**

### **Main Interface**
```bash
deepseek              # ← Agent mode (ask or do anything)
deepseek --help       # Show help
deepseek version      # Version info
```

### **Chat Mode (Pure Q&A)**
```bash
deepseek chat "question"     # Ask and get answer
deepseek models              # List models
deepseek balance             # Check balance
```

### **Agent Commands**
```bash
deepseek-agent              # Explicit agent
deepseek-agent analyze      # Analyze project
deepseek-agent exec "cmd"   # Execute command
deepseek-agent read <file>  # Read file
deepseek-agent ls <dir>     # List directory
```

### **Configuration**
```bash
deepseek config --api-key X  # Set API key
```

---

## ✨ **How It Works**

### **Default Mode: Agent**

When you type `deepseek`, you get the **agent with project context**:

1. ✅ Analyzes your project
2. ✅ Shows project summary
3. ✅ Understands your language, framework, style
4. ✅ Ready to help with questions OR actions

### **What Makes It Special**

- **Unified**: One command for everything
- **Smart**: Understands your project
- **Safe**: Confirms before executing
- **Flexible**: Ask questions OR do things

---

## 🎓 **Example Workflows**

### **Workflow 1: Learning & Creating**
```
> What is FastAPI?
  [Explains concepts]

> Create a FastAPI app
  [Creates code]

> Run the app
  [Executes it]
```

### **Workflow 2: Exploring & Modifying**
```
> What files do I have?
  [Lists files]

> Show me main.py
  [Displays file]

> Add error handling
  [Modifies file]
```

### **Workflow 3: Debugging**
```
> My code has this error: [paste]
  [Analyzes]

> How do I fix it?
  [Explains]

> Can you fix it?
  [Updates code]
```

---

## 🚀 **Quick Start**

1. **Just type:**
   ```bash
   deepseek
   ```

2. **Ask for anything:**
   ```
   > What is Python?
   > Create a script
   > List my files
   > Explain this error
   ```

3. **Get answers, code, or actions!**

---

## 📖 **Documentation**

- **`DEEPSEEK_AS_AGENT.md`** - Complete guide
- **`ENHANCED_FEATURES.md`** - Technical details
- **`COMPLETE_GUIDE.md`** - Master documentation
- **`QUICK_REFERENCE.md`** - This file

---

## 🎯 **Remember**

**Just type `deepseek` and ask for anything!**

✅ Questions → Answers
✅ Code → Creation
✅ Commands → Execution
✅ Files → Reading/Writing
✅ Tasks → Automation

**Your universal AI terminal!** 🤖
