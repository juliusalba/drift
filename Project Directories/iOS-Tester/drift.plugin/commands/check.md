---
description: Analyze build vs design — single pass
---
Run a single drift analysis pass on the current project.

1. Find the Xcode project in the workspace
2. Build to simulator
3. Capture all discoverable screens
4. Fetch design references (Figma MCP -> Refero MCP -> local designs/ folder)
5. Compare each screen against its design reference using VLM
6. Generate a compliance report
