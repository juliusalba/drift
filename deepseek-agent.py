#!/usr/bin/env python3
"""
DeepSeek Agent Enhanced - Agentic Terminal with Project Context
Now with codebase understanding and intelligent execution!
"""

import os
import sys
import json
import subprocess
import click
from typing import Optional, List, Dict, Any
from datetime import datetime
import re
import glob


try:
    from openai import OpenAI
except ImportError:
    click.echo("Error: OpenAI SDK not installed. Please run: pip install openai", err=True)
    sys.exit(1)


# Default configuration
DEFAULT_BASE_URL = "https://api.deepseek.com"
DEFAULT_MODEL = "deepseek-chat"
CONFIG_FILE = os.path.expanduser("~/.deepseek_config.json")


class ProjectAnalyzer:
    """Analyzes project structure and context"""

    def __init__(self, project_path: str = "."):
        self.project_path = os.path.abspath(project_path)
        self.info = None

    def analyze(self) -> Dict[str, Any]:
        """Full project analysis"""
        if self.info:
            return self.info

        self.info = {
            'path': self.project_path,
            'language': self._detect_language(),
            'framework': self._detect_framework(),
            'dependencies': self._read_dependencies(),
            'structure': self._analyze_structure(),
            'code_style': self._analyze_code_style(),
            'existing_patterns': self._analyze_patterns(),
            'git_info': self._get_git_info(),
            'has_docker': self._check_docker(),
            'has_tests': self._check_tests(),
        }

        return self.info

    def _detect_language(self) -> str:
        """Detect primary programming language"""
        extensions = {
            '.py': 'python',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.java': 'java',
            '.cpp': 'cpp',
            '.c': 'c',
            '.go': 'go',
            '.rs': 'rust',
            '.rb': 'ruby',
            '.php': 'php',
            '.swift': 'swift',
            '.kt': 'kotlin',
            '.scala': 'scala'
        }

        counts = {}
        for root, dirs, files in os.walk(self.project_path):
            # Skip hidden and build directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__', 'build', 'dist', 'target']]

            for file in files:
                ext = os.path.splitext(file)[1]
                if ext in extensions:
                    lang = extensions[ext]
                    counts[lang] = counts.get(lang, 0) + 1

        if counts:
            return max(counts, key=counts.get)
        return 'unknown'

    def _detect_framework(self) -> List[str]:
        """Detect frameworks in use"""
        frameworks = []

        # Python frameworks
        if os.path.exists(os.path.join(self.project_path, 'manage.py')):
            frameworks.append('django')
        if os.path.exists(os.path.join(self.project_path, 'app.py')) or os.path.exists(os.path.join(self.project_path, 'main.py')):
            if any('fastapi' in f.lower() for f in os.listdir(self.project_path)):
                frameworks.append('fastapi')
            if any('flask' in f.lower() for f in os.listdir(self.project_path)):
                frameworks.append('flask')

        # JavaScript frameworks
        package_json = os.path.join(self.project_path, 'package.json')
        if os.path.exists(package_json):
            try:
                with open(package_json, 'r') as f:
                    pkg = json.load(f)
                    deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}

                    if 'react' in deps:
                        frameworks.append('react')
                    if 'vue' in deps:
                        frameworks.append('vue')
                    if 'express' in deps:
                        frameworks.append('express')
                    if 'next' in deps:
                        frameworks.append('nextjs')
            except:
                pass

        return list(set(frameworks))

    def _read_dependencies(self) -> Dict[str, Any]:
        """Read dependency information"""
        deps = {}

        # Python
        req_txt = os.path.join(self.project_path, 'requirements.txt')
        if os.path.exists(req_txt):
            try:
                with open(req_txt, 'r') as f:
                    deps['python'] = [line.strip() for line in f if line.strip() and not line.startswith('#')]
            except:
                pass

        pyproject_toml = os.path.join(self.project_path, 'pyproject.toml')
        if os.path.exists(pyproject_toml):
            deps['python_toml'] = True

        # JavaScript
        package_json = os.path.join(self.project_path, 'package.json')
        if os.path.exists(package_json):
            try:
                with open(package_json, 'r') as f:
                    pkg = json.load(f)
                    deps['node'] = {
                        'dependencies': list(pkg.get('dependencies', {}).keys()),
                        'devDependencies': list(pkg.get('devDependencies', {}).keys())
                    }
            except:
                pass

        # Java
        pom_xml = os.path.join(self.project_path, 'pom.xml')
        if os.path.exists(pom_xml):
            deps['maven'] = True

        build_gradle = os.path.join(self.project_path, 'build.gradle')
        if os.path.exists(build_gradle):
            deps['gradle'] = True

        return deps

    def _analyze_structure(self) -> Dict[str, Any]:
        """Analyze project structure"""
        structure = {
            'has_src_dir': False,
            'has_tests_dir': False,
            'has_docs_dir': False,
            'has_config_dir': False,
            'main_files': [],
            'config_files': []
        }

        for root, dirs, files in os.walk(self.project_path):
            # Skip hidden directories
            dirs[:] = [d for d in dirs if not d.startswith('.')]

            rel_path = os.path.relpath(root, self.project_path)

            if 'src' in rel_path.lower() and not structure['has_src_dir']:
                structure['has_src_dir'] = True
            if 'test' in rel_path.lower() or rel_path == 'tests':
                structure['has_tests_dir'] = True
            if 'doc' in rel_path.lower():
                structure['has_docs_dir'] = True
            if 'config' in rel_path.lower():
                structure['has_config_dir'] = True

            # Find main files
            for file in files:
                if file in ['main.py', 'app.py', 'index.js', 'index.ts', 'App.js', 'main.java']:
                    structure['main_files'].append(os.path.join(rel_path, file))

                # Config files
                if file.endswith(('.json', '.yaml', '.yml', '.conf', '.config.js')):
                    structure['config_files'].append(os.path.join(rel_path, file))

        return structure

    def _analyze_code_style(self) -> Dict[str, Any]:
        """Detect code style conventions"""
        style = {
            'uses_type_hints': False,
            'uses_docstrings': False,
            'line_ending': 'lf',
            'indent_style': 'spaces',
            'indent_size': 4
        }

        # Check for Python type hints
        for root, dirs, files in os.walk(self.project_path):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__']]
            for file in files:
                if file.endswith('.py'):
                    try:
                        with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read(10000)  # Read first 10KB
                            if 'def ' in content and ':' in content:
                                if any(word in content for word in ['str', 'int', 'bool', 'List', 'Dict']):
                                    style['uses_type_hints'] = True
                            if '"""' in content or "'''" in content:
                                style['uses_docstrings'] = True
                    except:
                        pass

        # Check for .editorconfig
        if os.path.exists(os.path.join(self.project_path, '.editorconfig')):
            try:
                with open(os.path.join(self.project_path, '.editorconfig'), 'r') as f:
                    content = f.read()
                    if 'indent_size' in content:
                        match = re.search(r'indent_size\s*=\s*(\d+)', content)
                        if match:
                            style['indent_size'] = int(match.group(1))
            except:
                pass

        return style

    def _analyze_patterns(self) -> Dict[str, Any]:
        """Analyze existing code patterns"""
        patterns = {
            'naming_convention': 'unknown',
            'common_functions': [],
            'import_patterns': [],
            'error_handling': False
        }

        # Count naming conventions
        snake_case = 0
        camelCase = 0
        PascalCase = 0

        for root, dirs, files in os.walk(self.project_path):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__']]
            for file in files:
                if file.endswith('.py') or file.endswith('.js') or file.endswith('.ts'):
                    # Check file names
                    if '_' in file:
                        snake_case += 1
                    elif file[0].isupper():
                        PascalCase += 1
                    else:
                        camelCase += 1

                    # Check file content
                    try:
                        with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read(5000)
                            if 'def ' in content or 'function ' in content:
                                patterns['common_functions'].append(file)
                            if 'import ' in content or 'from ' in content:
                                patterns['import_patterns'].append(file)
                            if 'try:' in content or 'try {' in content:
                                patterns['error_handling'] = True
                    except:
                        pass

        if snake_case > max(camelCase, PascalCase):
            patterns['naming_convention'] = 'snake_case'
        elif camelCase > PascalCase:
            patterns['naming_convention'] = 'camelCase'
        elif PascalCase > 0:
            patterns['naming_convention'] = 'PascalCase'

        return patterns

    def _get_git_info(self) -> Dict[str, Any]:
        """Get Git repository information"""
        info = {'has_git': False, 'has_gitignore': False}

        if os.path.exists(os.path.join(self.project_path, '.git')):
            info['has_git'] = True

        if os.path.exists(os.path.join(self.project_path, '.gitignore')):
            info['has_gitignore'] = True

        return info

    def _check_docker(self) -> bool:
        """Check if project uses Docker"""
        return os.path.exists(os.path.join(self.project_path, 'Dockerfile')) or \
               os.path.exists(os.path.join(self.project_path, 'docker-compose.yml'))

    def _check_tests(self) -> bool:
        """Check if project has tests"""
        test_patterns = ['test_*.py', '*_test.py', 'tests/*.py', 'spec/*.js']
        for pattern in test_patterns:
            if glob.glob(os.path.join(self.project_path, pattern)):
                return True
        return False

    def get_summary(self) -> str:
        """Get a human-readable project summary"""
        info = self.analyze()

        summary = f"\n{'='*60}\n"
        summary += f"Project Analysis: {info['path']}\n"
        summary += f"{'='*60}\n\n"

        summary += f"Language: {info['language']}\n"

        if info['framework']:
            summary += f"Frameworks: {', '.join(info['framework'])}\n"

        summary += f"\nStructure:\n"
        summary += f"  - Source directory: {'✓' if info['structure']['has_src_dir'] else '✗'}\n"
        summary += f"  - Tests directory: {'✓' if info['structure']['has_tests_dir'] else '✗'}\n"
        summary += f"  - Docs directory: {'✓' if info['structure']['has_docs_dir'] else '✗'}\n"
        summary += f"  - Docker: {'✓' if info['has_docker'] else '✗'}\n"
        summary += f"  - Git: {'✓' if info['git_info']['has_git'] else '✗'}\n"

        summary += f"\nDependencies:\n"
        if 'python' in info['dependencies']:
            summary += f"  - Python packages: {len(info['dependencies']['python'])}\n"
        if 'node' in info['dependencies']:
            summary += f"  - Node packages: {len(info['dependencies']['node']['dependencies'])}\n"

        summary += f"\nCode Style:\n"
        summary += f"  - Naming: {info['code_style']['naming_convention']}\n"
        summary += f"  - Type hints: {'✓' if info['code_style']['uses_type_hints'] else '✗'}\n"
        summary += f"  - Docstrings: {'✓' if info['code_style']['uses_docstrings'] else '✗'}\n"

        summary += f"\n{'='*60}\n"

        return summary


class DeepSeekAgentEnhanced:
    """Enhanced agent with project context awareness"""

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None, project_path: str = "."):
        """Initialize the enhanced agent"""
        self.api_key = api_key or self._load_api_key()
        self.base_url = base_url or DEFAULT_BASE_URL
        self.conversation_history = []
        self.project_analyzer = ProjectAnalyzer(project_path)
        self.project_info = None

        if not self.api_key:
            click.echo("Error: API key not found", err=True)
            sys.exit(1)

        try:
            self.client = OpenAI(
                api_key=self.api_key,
                base_url=self.base_url
            )
        except Exception as e:
            click.echo(f"Error initializing client: {e}", err=True)
            sys.exit(1)

    def _load_api_key(self) -> Optional[str]:
        """Load API key from config file or environment"""
        if os.environ.get("DEEPSEEK_API_KEY"):
            return os.environ.get("DEEPSEEK_API_KEY")

        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    config = json.load(f)
                    return config.get("api_key")
            except Exception:
                pass

        return None

    def analyze_project(self):
        """Analyze the project"""
        click.echo("\nAnalyzing project...")
        self.project_info = self.project_analyzer.analyze()
        click.echo(self.project_analyzer.get_summary())
        return self.project_info

    def run(self):
        """Start the enhanced agent"""
        # Analyze project on startup
        self.analyze_project()

        click.echo("\n" + "="*60)
        click.echo("DeepSeek Agent Enhanced - Agentic Terminal with Context")
        click.echo("Type 'exit' or 'quit' to end")
        click.echo("Type 'help' for information")
        click.echo("Type 'analyze' to re-analyze project")
        click.echo("Type 'context' to see project summary")
        click.echo("Type 'exec <command>' to execute a command")
        click.echo("="*60 + "\n")

        while True:
            try:
                task = input("\nWhat would you like me to do? ").strip()

                if task.lower() in ['exit', 'quit', 'q']:
                    click.echo("\nGoodbye!")
                    break

                if task.lower() == 'help':
                    self._show_enhanced_help()
                    continue

                if task.lower() == 'analyze':
                    self.analyze_project()
                    continue

                if task.lower() == 'context':
                    click.echo(self.project_analyzer.get_summary())
                    continue

                if task.startswith('exec '):
                    command = task[5:]
                    self._execute_direct(command)
                    continue

                # Process with AI and project context
                self._process_task_with_context(task)

            except KeyboardInterrupt:
                click.echo("\n\nGoodbye!")
                break
            except Exception as e:
                click.echo(f"\nError: {e}", err=True)

    def _show_enhanced_help(self):
        """Show enhanced help information"""
        click.echo("""
DeepSeek Agent Enhanced - Intelligent Coding Assistant

Context-Aware Commands:
  analyze       - Re-analyze project structure
  context       - Show current project summary
  exec <cmd>    - Execute command directly
  help          - Show this help
  exit/quit     - Exit

The agent understands your project and can:
  - Create files in the right locations
  - Use your existing code patterns
  - Follow your coding style
  - Integrate with your dependencies
  - Avoid conflicts with existing code

Example Requests:
  "Create a new API endpoint"
  "Add user authentication to my project"
  "Create a test file for this module"
  "Set up a CI/CD pipeline"
  "Refactor this function to use type hints"
  "Create a Docker container for this app"
  "Add logging to my application"
        """)

    def _execute_direct(self, command: str):
        """Execute a command directly"""
        click.echo(f"\n$ {command}")
        click.echo("-"*60)
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=self.project_analyzer.project_path
            )
            if result.stdout:
                click.echo(result.stdout)
            if result.stderr:
                click.echo(f"Error: {result.stderr}", err=True)
        except Exception as e:
            click.echo(f"Error executing command: {e}", err=True)
        click.echo("-"*60 + "\n")

    def _process_task_with_context(self, task: str):
        """Process a task using AI with project context"""
        context_str = self._format_project_context()

        system_prompt = f"""You are an intelligent coding assistant with deep project knowledge.

Project Context:
{context_str}

You can:
1. Execute shell commands
2. Read files
3. Write files
4. Analyze code
5. Create new features

When you need to execute a command, respond with:
```tool
execute
command: "the command"
description: "what this does"
```

When you need to read a file:
```tool
read_file
path: "path to file"
```

When you need to write a file:
```tool
write_file
path: "path to file"
content: "content"
force: false
```

IMPORTANT: Always consider the project context. Create files in appropriate locations, use existing patterns, and integrate with the current codebase."""

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": task}
        ]

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=messages,
                temperature=0.3,
                max_tokens=1500
            )

            content = response.choices[0].message.content

            # Check if response contains tool commands
            if "```tool" in content:
                self._execute_tool_commands_with_context(content)
            else:
                click.echo(f"\nDeepSeek: {content}\n")

        except Exception as e:
            click.echo(f"Error: {e}", err=True)

    def _format_project_context(self) -> str:
        """Format project context for AI"""
        if not self.project_info:
            self.project_info = self.project_analyzer.analyze()

        info = self.project_info

        context = f"""
Project: {info['path']}
Language: {info['language']}
Frameworks: {', '.join(info['framework']) if info['framework'] else 'None detected'}

Structure:
  - Has src/ directory: {info['structure']['has_src_dir']}
  - Has tests/ directory: {info['structure']['has_tests_dir']}
  - Uses Docker: {info['has_docker']}
  - Has tests: {info['has_tests']}

Dependencies:
{json.dumps(info['dependencies'], indent=2)}

Code Style:
  - Naming convention: {info['code_style']['naming_convention']}
  - Uses type hints: {info['code_style']['uses_type_hints']}
  - Uses docstrings: {info['code_style']['uses_docstrings']}

Patterns:
  - Common functions found in: {len(info['existing_patterns']['common_functions'])} files
  - Import patterns in: {len(info['existing_patterns']['import_patterns'])} files
  - Error handling: {info['existing_patterns']['error_handling']}

Main files:
{chr(10).join(f"  - {f}" for f in info['structure']['main_files'][:5])}

Config files:
{chr(10).join(f"  - {f}" for f in info['structure']['config_files'][:5])}
"""
        return context

    def _execute_tool_commands_with_context(self, content: str):
        """Execute tool commands with project awareness"""
        if "execute" in content and "command:" in content:
            self._extract_and_execute_with_context(content)
        elif "read_file" in content:
            self._extract_and_read_with_context(content)
        elif "write_file" in content:
            self._extract_and_write_with_context(content)
        else:
            click.echo(f"\nDeepSeek: {content}\n")

    def _extract_and_execute_with_context(self, content: str):
        """Extract and execute command with project context"""
        import re

        # Find command in markdown code block
        match = re.search(r'command:\s*"([^"]+)"', content, re.IGNORECASE)
        desc_match = re.search(r'description:\s*"([^"]*)"', content, re.IGNORECASE)

        if match:
            command = match.group(1)
            description = desc_match.group(1) if desc_match else "Execute command"

            click.echo(f"\nDeepSeek wants to: {description}")
            click.echo(f"Command: {command}")

            # Add context-aware suggestions
            if self.project_info:
                if command.startswith('pip install') or command.startswith('npm install'):
                    click.echo(f"\nNote: Project uses {self.project_info['language']}")
                    click.echo("Will update dependency files appropriately")

            # Ask for confirmation
            confirm = input("\nExecute? (y/N): ").strip().lower()
            if confirm == 'y':
                self._execute_direct(command)
            else:
                click.echo("Command cancelled.\n")
        else:
            click.echo(f"\nDeepSeek: {content}\n")

    def _extract_and_read_with_context(self, content: str):
        """Extract and read file with context awareness"""
        import re

        match = re.search(r'path:\s*"([^"]+)"', content, re.IGNORECASE)
        if match:
            filepath = match.group(1)

            # If relative path, make it relative to project
            if not filepath.startswith('/'):
                filepath = os.path.join(self.project_analyzer.project_path, filepath)

            click.echo(f"\nDeepSeek wants to read: {filepath}")

            if os.path.exists(filepath):
                try:
                    with open(filepath, 'r') as f:
                        content = f.read()
                    click.echo(f"\n{'='*60}")
                    click.echo(f"File: {filepath}")
                    click.echo(f"Size: {len(content)} bytes")
                    click.echo('='*60)
                    # Show first 50 lines
                    lines = content.split('\n')[:50]
                    click.echo('\n'.join(lines))
                    if len(content.split('\n')) > 50:
                        click.echo(f"\n... ({len(content.split('\n')) - 50} more lines)")
                    click.echo('='*60 + "\n")
                except Exception as e:
                    click.echo(f"Error reading file: {e}", err=True)
            else:
                click.echo(f"File not found: {filepath}", err=True)
        else:
            click.echo(f"\nDeepSeek: {content}\n")

    def _extract_and_write_with_context(self, content: str):
        """Extract and write file with project awareness"""
        import re

        path_match = re.search(r'path:\s*"([^"]+)"', content, re.IGNORECASE)
        content_match = re.search(r'content:\s*"([^"]*)"', content, re.IGNORECASE)
        force_match = re.search(r'force:\s*(true|false)', content, re.IGNORECASE)

        if path_match and content_match:
            filepath = path_match.group(1)
            filecontent = content_match.group(1)
            force = force_match and force_match.group(1).lower() == 'true' if force_match else False

            # If relative path, make it relative to project
            if not filepath.startswith('/'):
                filepath = os.path.join(self.project_analyzer.project_path, filepath)

            click.echo(f"\nDeepSeek wants to write to: {filepath}")
            click.echo(f"Content preview: {filecontent[:100]}...")

            # Add context-aware suggestions
            if self.project_info:
                if filepath.endswith('.py') and self.project_info['code_style']['uses_type_hints']:
                    click.echo("\nNote: Project uses type hints - content should include type annotations")
                if filepath.endswith('.py') and self.project_info['code_style']['uses_docstrings']:
                    click.echo("Note: Project uses docstrings - consider adding documentation")
                if self.project_info['structure']['has_src_dir'] and '/src/' not in filepath:
                    click.echo(f"Note: Project has src/ directory at {self.project_info['path']}/src/")
                if self.project_info['structure']['has_tests_dir'] and filepath.endswith('.py') and 'test' not in filepath.lower():
                    click.echo("Note: Consider adding tests for this file")

            # Check if file exists
            if os.path.exists(filepath) and not force:
                click.echo(f"\n⚠️  File already exists!", err=True)
                confirm = input("Overwrite? (y/N): ").strip().lower()
                if confirm != 'y':
                    click.echo("Write cancelled.\n")
                    return

            confirm = input("\nWrite file? (y/N): ").strip().lower()
            if confirm == 'y':
                try:
                    os.makedirs(os.path.dirname(filepath), exist_ok=True)
                    with open(filepath, 'w') as f:
                        f.write(filecontent)
                    click.echo(f"✓ File written successfully to {filepath}\n")
                except Exception as e:
                    click.echo(f"Error writing file: {e}", err=True)
            else:
                click.echo("Write cancelled.\n")
        else:
            click.echo(f"\nDeepSeek: {content}\n")


@click.group(invoke_without_command=True)
@click.pass_context
@click.option('--project', '-p', default='.', help='Project path to analyze')
def cli(ctx, project):
    """DeepSeek Agent Enhanced - Intelligent Terminal Assistant with Project Context"""
    if ctx.invoked_subcommand is None:
        agent = DeepSeekAgentEnhanced(project_path=project)
        agent.run()


@cli.command()
@click.argument('task')
@click.option('--project', '-p', default='.', help='Project path to analyze')
@click.option('--model', '-m', default=DEFAULT_MODEL,
              type=click.Choice(['deepseek-chat', 'deepseek-reasoner']),
              help='Model to use')
def do(task: str, project: str, model: str):
    """Execute a task with project context"""
    agent = DeepSeekAgentEnhanced(project_path=project)
    agent.analyze_project()
    agent._process_task_with_context(task)


@cli.command()
@click.argument('command')
@click.option('--project', '-p', default='.', help='Project path to analyze')
def exec(command: str, project: str):
    """Execute a shell command directly"""
    agent = DeepSeekAgentEnhanced(project_path=project)
    agent._execute_direct(command)


@cli.command()
@click.argument('file')
@click.option('--project', '-p', default='.', help='Project path to analyze')
def read(file: str, project: str):
    """Read a file with project context"""
    if not file.startswith('/'):
        file = os.path.join(project, file)

    if os.path.exists(file):
        try:
            with open(file, 'r') as f:
                content = f.read()
            click.echo(content)
        except Exception as e:
            click.echo(f"Error reading file: {e}", err=True)
    else:
        click.echo(f"File not found: {file}", err=True)


@cli.command()
@click.argument('path', default='.')
@click.option('--project', '-p', default='.', help='Project path to analyze')
def ls(path: str, project: str):
    """List directory contents with project context"""
    full_path = path
    if not full_path.startswith('/'):
        full_path = os.path.join(project, path)

    if os.path.exists(full_path):
        try:
            items = os.listdir(full_path)
            for item in sorted(items):
                full_item_path = os.path.join(full_path, item)
                if os.path.isdir(full_item_path):
                    click.echo(f"{item}/")
                else:
                    click.echo(item)
        except Exception as e:
            click.echo(f"Error listing directory: {e}", err=True)
    else:
        click.echo(f"Directory not found: {path}", err=True)


@cli.command()
@click.option('--project', '-p', default='.', help='Project path to analyze')
def analyze(project: str):
    """Analyze project structure and context"""
    agent = DeepSeekAgentEnhanced(project_path=project)
    agent.analyze_project()


@cli.command()
def version():
    """Show version information"""
    click.echo("DeepSeek Agent Enhanced v2.0.0")
    click.echo("Agentic Terminal with Project Context Awareness")


if __name__ == '__main__':
    cli()
