# Hugging Face MCP Server for Cursor and Trae

This setup provides a Model Context Protocol (MCP) server that integrates Hugging Face capabilities with both Cursor and Trae.

## What's Installed

1. **Python 3.11**: Required for MCP (installed via Homebrew)
2. **MCP Package**: The base Model Context Protocol library
3. **Hugging Face Libraries**: `huggingface_hub` and `transformers` for model access
4. **Custom MCP Server**: `hf_mcp_server.py` - A custom server providing Hugging Face integration

## Available Tools

The MCP server provides these tools to Cursor:

- **search_models**: Search for models on Hugging Face Hub
- **search_datasets**: Search for datasets on Hugging Face Hub  
- **get_model_info**: Get detailed information about a specific model
- **run_pipeline**: Run Hugging Face pipelines (text generation, classification, etc.)

## Configuration

### Cursor Configuration
The server is configured in Cursor's settings at:
`~/Library/Application Support/Cursor/User/settings.json`

```json
{
  "mcp.servers": {
    "huggingface": {
      "command": "/opt/homebrew/bin/python3.11",
      "args": ["/Users/juliusalba/hf_mcp_server.py"]
    }
  }
}
```

### Trae Configuration  
The server was added to Trae using:
```bash
trae --add-mcp '{"name":"huggingface","command":"/opt/homebrew/bin/python3.11","args":["/Users/juliusalba/hf_mcp_server.py"]}'
```

✅ **Status**: Both Cursor and Trae are configured and ready to use!

## Usage

### Cursor
After restarting Cursor, you should be able to:
1. Search for Hugging Face models and datasets
2. Get information about specific models
3. Run basic text processing pipelines

### Trae
You can immediately start using Hugging Face functionality:
1. Use `trae chat` to interact with Hugging Face models
2. Search and explore the model hub
3. Run text processing pipelines

## Files

- `hf_mcp_server.py`: The MCP server implementation
- `README_HF_MCP.md`: This documentation

## Next Steps

### For Cursor:
1. **Restart Cursor** to load the MCP configuration
2. **Test the integration** by asking Cursor to search for Hugging Face models

### For Trae:
1. **Test immediately** - no restart needed!
2. Try: `trae chat "Search for GPT models on Hugging Face"`

### Optional:
3. **Install PyTorch/TensorFlow** if you want to run model pipelines locally:
   ```bash
   /opt/homebrew/bin/python3.11 -m pip install torch
   ```

## Example Usage

### In Cursor:
- "Search for GPT models on Hugging Face"
- "Find sentiment analysis models"
- "Get information about the BERT model"
- "Run text classification on this sentence: 'I love this product'"

### In Trae:
```bash
trae chat "Search for GPT models on Hugging Face"
trae chat "Find the best sentiment analysis models"
trae chat "What models are good for text summarization?"
```

The MCP server will handle these requests and provide Hugging Face integration directly within both tools.
