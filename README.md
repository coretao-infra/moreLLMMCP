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

## Documentation
- **Design & Architecture:** See [`scratchpad/design-considerations.md`](scratchpad/design-considerations.md)
- **Contributing:** See [`CONTRIBUTING.md`](CONTRIBUTING.md)
- **Code of Conduct:** See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)

## Community & Support
- Open issues for bugs, questions, or feature requests
- PRs welcome! Please read the contributing guidelines first

## License
[MIT](LICENSE)
