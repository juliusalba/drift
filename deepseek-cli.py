#!/usr/bin/env python3
"""
DeepSeek CLI - A command-line interface for DeepSeek v3.2 API

Usage:
    deepseek-cli chat "Your message"
    deepseek-cli models
    deepseek-cli balance
    deepseek-cli interactive
"""

import os
import sys

# Add current directory to path to find deepseek_agent module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
import click
from typing import Optional, List, Dict, Any
from datetime import datetime


try:
    from openai import OpenAI
except ImportError:
    click.echo("Error: OpenAI SDK not installed. Please run: pip install openai", err=True)
    sys.exit(1)


# Default configuration
DEFAULT_BASE_URL = "https://api.deepseek.com"
DEFAULT_MODEL = "deepseek-chat"
CONFIG_FILE = os.path.expanduser("~/.deepseek_config.json")


class DeepSeekClient:
    """Client for interacting with DeepSeek API"""

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        """Initialize the DeepSeek client"""
        self.api_key = api_key or self._load_api_key()
        self.base_url = base_url or DEFAULT_BASE_URL

        if not self.api_key:
            click.echo(
                "Error: API key not found. Please set DEEPSEEK_API_KEY environment variable "
                "or run 'deepseek-cli config --api-key YOUR_KEY'",
                err=True
            )
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
        # Try environment variable first
        if os.environ.get("DEEPSEEK_API_KEY"):
            return os.environ.get("DEEPSEEK_API_KEY")

        # Try config file
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    config = json.load(f)
                    return config.get("api_key")
            except Exception:
                pass

        return None

    def _save_config(self, api_key: str, base_url: Optional[str] = None):
        """Save configuration to file"""
        config = {"api_key": api_key}
        if base_url:
            config["base_url"] = base_url

        os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        click.echo(f"Configuration saved to {CONFIG_FILE}")

    def list_models(self):
        """List available models"""
        try:
            models = self.client.models.list()
            click.echo("\nAvailable Models:\n")
            for model in models.data:
                click.echo(f"  - {model.id}")
                if hasattr(model, 'description') and model.description:
                    click.echo(f"    {model.description}")
            click.echo()
        except Exception as e:
            click.echo(f"Error fetching models: {e}", err=True)
            sys.exit(1)

    def get_balance(self):
        """Get user balance information"""
        click.echo("Checking account balance...")
        click.echo("Note: Balance checking may require additional API endpoints.")
        click.echo("Please visit: https://platform.deepseek.com/ for account information.")

    def chat_completion(
        self,
        message: str,
        system_message: Optional[str] = None,
        model: str = DEFAULT_MODEL,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        stream: bool = False,
        thinking_mode: bool = False
    ):
        """Send a chat completion request"""

        # Build messages
        messages = []
        if system_message:
            messages.append({"role": "system", "content": system_message})
        messages.append({"role": "user", "content": message})

        # Select model
        if thinking_mode:
            model = "deepseek-reasoner"

        # Prepare request parameters
        params = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "stream": stream
        }

        if max_tokens:
            params["max_tokens"] = max_tokens

        try:
            if stream:
                self._stream_response(params)
            else:
                self._normal_response(params)
        except Exception as e:
            click.echo(f"Error during completion: {e}", err=True)
            sys.exit(1)

    def _normal_response(self, params: Dict[str, Any]):
        """Handle normal (non-streaming) response"""
        response = self.client.chat.completions.create(**params)

        click.echo("\n" + "="*60)
        click.echo(f"Model: {response.model}")
        click.echo(f"Created: {datetime.fromtimestamp(response.created)}")
        click.echo("="*60 + "\n")

        content = response.choices[0].message.content
        click.echo(content)

        # Show usage stats if available
        if hasattr(response, 'usage') and response.usage:
            click.echo("\n" + "="*60)
            click.echo(f"Prompt tokens: {response.usage.prompt_tokens}")
            click.echo(f"Completion tokens: {response.usage.completion_tokens}")
            click.echo(f"Total tokens: {response.usage.total_tokens}")
            click.echo("="*60 + "\n")

    def _stream_response(self, params: Dict[str, Any]):
        """Handle streaming response"""
        click.echo("\n" + "="*60)
        click.echo(f"Model: {params['model']} (Streaming)")
        click.echo("="*60 + "\n")

        stream = self.client.chat.completions.create(**params)

        full_content = ""
        for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                content = chunk.choices[0].delta.content
                click.echo(content, nl=False)
                sys.stdout.flush()
                full_content += content

        click.echo("\n")

        # Note: Usage stats not available for streaming in the same way

    def interactive_mode(self):
        """Start an interactive chat session"""
        click.echo("\n" + "="*60)
        click.echo("DeepSeek Interactive Chat Mode")
        click.echo("Type 'exit' or 'quit' to end the session")
        click.echo("Type 'clear' to clear conversation history")
        click.echo("="*60 + "\n")

        messages = []
        model = DEFAULT_MODEL
        temperature = 0.7

        while True:
            try:
                message = input("\nYou: ").strip()

                if message.lower() in ['exit', 'quit', 'q']:
                    click.echo("\nGoodbye!")
                    break

                if message.lower() == 'clear':
                    messages = []
                    click.echo("Conversation history cleared.")
                    continue

                if message.lower() == 'help':
                    self._show_interactive_help()
                    continue

                # Build messages with history
                request_messages = messages.copy()
                request_messages.append({"role": "user", "content": message})

                # Send request
                params = {
                    "model": model,
                    "messages": request_messages,
                    "temperature": temperature,
                    "stream": False
                }

                response = self.client.chat.completions.create(**params)
                assistant_message = response.choices[0].message.content

                click.echo(f"\nDeepSeek: {assistant_message}")

                # Update conversation history
                messages.append({"role": "user", "content": message})
                messages.append({"role": "assistant", "content": assistant_message})

                # Show token usage occasionally
                if hasattr(response, 'usage') and response.usage:
                    click.echo(f"\n[Tokens: {response.usage.total_tokens}]")

            except KeyboardInterrupt:
                click.echo("\n\nGoodbye!")
                break
            except Exception as e:
                click.echo(f"\nError: {e}", err=True)

    def _show_interactive_help(self):
        """Show help for interactive mode"""
        click.echo("""
Interactive Mode Commands:
  help     - Show this help message
  clear    - Clear conversation history
  exit/quit - Exit interactive mode

Settings (current):
  Model: {model}
  Temperature: {temp}

To change settings, restart and use command-line options.
        """.format(model=DEFAULT_MODEL, temp=0.7))


@click.group(invoke_without_command=True)
@click.pass_context
def cli(ctx):
    """DeepSeek v3.2 CLI - Interact with DeepSeek AI models"""
    if ctx.invoked_subcommand is None:
        # Default to agentic terminal when no command is specified
        from deepseek_agent import DeepSeekAgentEnhanced
        agent = DeepSeekAgentEnhanced()
        agent.run()


@cli.command()
@click.argument('message', required=False)
@click.option('--model', '-m', default=DEFAULT_MODEL,
              type=click.Choice(['deepseek-chat', 'deepseek-reasoner']),
              help='Model to use for completion')
@click.option('--system', '-s', help='System message to set context')
@click.option('--temperature', '-t', default=0.7,
              help='Sampling temperature (0.0-2.0)')
@click.option('--max-tokens', '-M', type=int,
              help='Maximum number of tokens to generate')
@click.option('--stream', is_flag=True,
              help='Enable streaming response')
@click.option('--thinking-mode', is_flag=True,
              help='Enable thinking mode (uses deepseek-reasoner model)')
def chat(message: Optional[str], model: str, system: Optional[str],
          temperature: float, max_tokens: Optional[int], stream: bool,
          thinking_mode: bool):
    """Send a chat message to DeepSeek"""

    if thinking_mode:
        model = "deepseek-reasoner"

    if not message:
        message = click.prompt('Enter your message')

    client = DeepSeekClient()

    click.echo(f"\nSending request to DeepSeek using model: {model}")
    if thinking_mode:
        click.echo("Thinking mode enabled")
    click.echo("")

    client.chat_completion(
        message=message,
        system_message=system,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
        stream=stream,
        thinking_mode=thinking_mode
    )


@cli.command()
def models():
    """List available DeepSeek models"""
    client = DeepSeekClient()
    client.list_models()


@cli.command()
def balance():
    """Check account balance and usage"""
    client = DeepSeekClient()
    client.get_balance()


@cli.command()
@click.option('--api-key', help='API key for DeepSeek')
@click.option('--base-url', default=DEFAULT_BASE_URL,
              help=f'Base URL (default: {DEFAULT_BASE_URL})')
def config(api_key: Optional[str], base_url: str):
    """Configure DeepSeek CLI settings"""
    if not api_key:
        api_key = click.prompt('Enter your DeepSeek API key', hide_input=True)

    client = DeepSeekClient()
    client._save_config(api_key, base_url)


@cli.command()
@click.option('--model', '-m', default=DEFAULT_MODEL,
              type=click.Choice(['deepseek-chat', 'deepseek-reasoner']),
              help='Model to use')
@click.option('--temperature', '-t', default=0.7,
              help='Sampling temperature (0.0-2.0)')
def interactive(model: str, temperature: float):
    """Start an interactive chat session"""
    client = DeepSeekClient()
    client.interactive_mode()


@cli.command()
def version():
    """Show version information"""
    click.echo("DeepSeek CLI v1.0.0")
    click.echo("Built for DeepSeek v3.2 API")


if __name__ == '__main__':
    cli()
