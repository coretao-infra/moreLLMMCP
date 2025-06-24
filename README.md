# moreLLMMCP

An MCP Server coded in Python and implemented as Azure Functions, exposing LLM endpoints (like Azure OpenAI) intended to be consumed via GitHub Copilot Chat.

## Project Highlights
- Minimal, maintainable, and production-ready design
- Canonical handler layer for easy LLM provider extension
- Secure, Azure-only deployment (no local emulator)
- Atomic, testable, and observable endpoints
- **Always use the most recent, natively supported Azure and Terraform features**
- **No legacy ARM/JSON or PowerShell deployment artifacts**
- **All infrastructure is managed as native Terraform, with only essential resources**

## Quick Start
1. Clone the repo
2. See `scratchpad/design-considerations.md` for architecture and implementation plan
3. Follow the Implementation Plan phases for setup and deployment

## Project Structure (2025+)
- All MCP apps are under `apps/`, each in its own folder (e.g., `apps/mcp_server1/`).
- Each app is a self-contained Azure Function App with its own endpoints, business logic, requirements, and config.
- Shared code (if any) goes in `shared/`. Infra and docs are in their own top-level folders.
- See `scratchpad/design-considerations.md` for the canonical structure, rationale, and best practices.

## Deployment Model: One or Many Function Apps (Slots)

- **Current model:** By default, all deployments target a single Azure Function App (the current "slot"). Multiple MCP Server codebases exist in `apps/`, but only one is live at a time per Function App.
- **Future-proof:** You can provision additional Function Apps (slots) via Terraform at any time. Each slot can run a different MCP Server for true isolation or multi-app scenarios.
- **Switching servers:** To change which MCP Server is live in a slot, deploy a different app folder to that Function App using the deployment script and config for that slot.
- **Isolation:** For side-by-side isolation, simply add more Function Apps in Terraform and deploy each MCP Server to its own slot.

### How to Deploy
1. Place your deployment config (copied from the sample) in the root of your MCP Server app folder (e.g., `apps/mcp_server_helloworld/`).
2. Run the deployment script and specify the app name and (optionally) the config for the target slot:
   ```pwsh
   pwsh mcpdeploy/mcpcodedeploy.ps1 -AppName mcp_server_helloworld
   # or, for a different slot/config:
   pwsh mcpdeploy/mcpcodedeploy.ps1 -AppName mcp_server1 -ConfigPath apps/mcp_server1/mcpcodedeploy.config.json
   ```
3. The script will deploy the endpoints in that app to the specified Function App slot.

See the config sample files in `mcpdeploy/` for the required format.

## Documentation
- **Design & Architecture:** See [`scratchpad/design-considerations.md`](scratchpad/design-considerations.md)
- **Contributing:** See [`CONTRIBUTING.md`](CONTRIBUTING.md)
- **Code of Conduct:** See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)

## Community & Support
- Open issues for bugs, questions, or feature requests
- PRs welcome! Please read the contributing guidelines first

## License
[MIT](LICENSE)
