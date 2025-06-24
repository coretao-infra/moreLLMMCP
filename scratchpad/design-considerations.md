# Design Considerations for moreLLMMCP

This document outlines the initial design considerations and architectural thoughts for the moreLLMMCP project.

## Project Overview
- **Project:** moreLLMMCP
- **Description:** An MCP Server coded in Python and implemented as Azure Functions, exposing LLM endpoints (like Azure OpenAI) intended to be consumed via GitHub Copilot Chat.

# Design principles
- Do not reinvent the wheel; always check for modern, standard solutions first
- Canonical, atomic code—zero tolerance for duplicity
- Maximize maintainability via separation of concerns and best practices
- Keep a per-file minimal header including version tracking (see below for format)
- Track project version in a central file (e.g., `morellmmcp/__init__.py`)
- Maintain a `CHANGELOG.md` for major project changes

### Per-file header example (add to top of every .py file):
```
# file: handlers/azure_oai.py
# description: Azure OpenAI handler for MCP server
# version: 0.1.0
# last updated: 2025-06-24
```


## Canonical LLM Handler Layer
- Implement one abstract base class (e.g., `AbstractLLMHandler`) with `chat_completion`, `completion`, `embeddings` methods.
- Concrete adapters: `AzureOpenAIHandler`, `OpenAIHandler`, `HuggingFaceHandler`, etc.
- Use a small registry (e.g., `registry.resolve_handler(request)`) to choose the adapter (via header, query parameter, or config default).
- This eliminates duplication and makes it trivial to add/replace providers.

## Folder / Module Layout
```
moreLLMMCP/
├─ handlers/           # provider adapters
│  ├─ base.py
│  ├─ azure_oai.py
│  ├─ openai.py        # Not supported initially
│  └─ hf.py            # not supported initially
├─ registry.py         # handler selection
├─ models.py           # Pydantic MCP request/response
├─ functions/          # Azure Function entry points
│  ├─ chat_completion_fn.py
│  ├─ completion_fn.py
│  └─ embeddings_fn.py
└─ openapi/            # (do not create for now)
```

## Azure Functions Choices
- Use the Python 3.11 Isolated Process worker for cleaner DI and easy unit testing.
- Enable EasyAuth (Azure AD) for inbound auth; fall back to PAT locally.
- Outbound auth: Managed Identity where a provider supports it, else Key Vault–stored API key.

## Azure Functions & MCP Endpoint Design
- Only deploy as an Azure Function; no local emulator or Azurite setup required.
- Expose the MCP endpoint at `/runtime/webhooks/mcp/sse` as per MCP spec.
- Secure the endpoint using Azure Functions system keys (passed as header or query param).
- Use Python 3.11 Isolated Process worker for clean dependency injection and testability.
- Use decorators for Azure Function triggers and bindings, but keep business logic atomic and minimal.
- Avoid sample-specific complexity—implement only what is needed for your LLM handler use case.
- Reference the [architecture diagram](https://github.com/Azure-Samples/remote-mcp-functions-python/blob/main/architecture-diagram.png) for high-level structure, but question any unnecessary abstraction.

## Observability
- Structured logging via `logging.getLogger(__name__)` → Azure Monitor.
- Application Insights traces + custom metrics (e.g., tokens_in, tokens_out).
- Correlate provider latency and errors for each call.

## Implementation Plan

_Phased, actionable, and checkpointed steps for building moreLLMMCP. All testing and validation is done in Azure—no local emulation required. Each phase can be trialed independently. Checkboxes indicate completion status._

### Phase 1: Azure-First Project Scaffold & Core Functionality
- [x] 1. Set up Azure Function App in Azure Portal (Python 3.11, Consumption or Premium plan)
    - Configure storage, identity, and app settings as needed.
- [x] 2. Scaffold minimal codebase locally:
    - Create the function folder (e.g., `mcp_sse/`).
    - Implement a minimal HTTP-triggered function for `/runtime/webhooks/mcp/sse`.
    - Add `handlers/`, `registry.py`, and minimal handler logic (even if stubbed).
- [x] 3. Prepare deployment files:
    - Ensure `requirements.txt` (with `azure-functions`, `pydantic`).
    - Ensure `function.json` and `__init__.py` are correct for your function.
    - Ensure `host.json` exists (even minimal: `{ "version": "2.0" }`).
- [ ] 4. Deploy to Azure (VS Code Azure Functions extension, GitHub Actions, or Portal “Deploy Code” feature).
- [ ] 5. Configure Azure App Settings (environment variables, keys, etc.) in the Azure Portal.
- [ ] 6. Test the endpoint in Azure (Postman, curl, or Copilot Chat) and confirm a valid response.
- [ ] 7. Document the endpoint, deployment process, and any required settings in README/design doc.

**Checkpoint: End-to-end request/response flow with AzureOpenAIHandler, secure and observable, deployed and tested in Azure.**

### Phase 2: Auth, Observability, and CI/CD
- [ ] 10. Enable EasyAuth (Azure AD) for inbound auth; fall back to PAT locally
- [ ] 11. Set up Application Insights for traces and custom metrics (tokens_in, tokens_out)
- [ ] 12. Add GitHub Actions workflow: lint (ruff/black), unit tests (pytest + pytest-asyncio), deploy (`func azure functionapp publish`)
- [ ] 13. Add Bicep/IaC for infrastructure, with environment promotion (dev → test → prod)
- [ ] 14. Add hyperlinks to MCP spec sections in documentation

**Checkpoint: Secure, observable, and CI/CD-enabled deployment pipeline with automated tests and infrastructure as code.**

### Phase 3: Security, Scaling, and Advanced Ops
- [ ] 15. Decide on rate limiting (APIM, Functions Proxies, or code middleware)
- [ ] 16. Determine if Premium plan is needed for VNet/private endpoint access to Azure OpenAI
- [ ] 17. Add usage metering if billing or quotas are required
- [ ] 18. Store all secrets and connection strings in Azure App Settings or Key Vault
- [ ] 19. Use Managed Identity for outbound Azure connections where possible
- [ ] 20. Configure CORS as needed

**Checkpoint: Production-grade security, scaling, and operational readiness.**

### Phase 4: Extensibility & Nice-to-Have Features
- [ ] 21. Add support for additional LLM providers (OpenAIHandler, HuggingFaceHandler, etc.)
- [ ] 22. Implement usage monitoring and metering beyond MVP
- [ ] 23. Add interactive API docs (OpenAPI/Swagger) if/when needed
- [ ] 24. Integrate with Power Platform or Logic Apps connectors
- [ ] 25. Add multi-tenant support
- [ ] 26. Add pluggable analytics/telemetry
- [ ] 27. Implement automated cost reporting

**Checkpoint: Feature-rich, extensible, and ready for broader integration and analytics.**

---

*Add further design notes, decisions, and architectural diagrams below as the project evolves.*

# Refs: 
## Getting Started with Remote MCP Servers using Azure Functions (Python)
https://github.com/Azure-Samples/remote-mcp-functions-python
## Azure Functions developer guide
https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-python
## Azure Functions Python developer guide
https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators
