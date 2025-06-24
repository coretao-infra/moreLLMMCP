# Design Considerations for moreLLMMCP

**Project structure and guidance are up to date as of June 2025. All MCP apps are under `apps/`, each as a self-contained Azure Function App. See below for canonical structure and best practices.**

This document outlines the design philosophy and architectural decisions for the moreLLMMCP project.

## Project Overview
- **Project:** moreLLMMCP
- **Description:** An MCP Server coded in Python and implemented as Azure Functions, exposing LLM endpoints (like Azure OpenAI) intended to be consumed via GitHub Copilot Chat.

# Design Principles
- **Always use the most recent, natively supported Azure and Terraform features.**
- **No legacy ARM/JSON or PowerShell deployment artifacts.**
- **All infrastructure is managed as native Terraform, with only essential resources.**
- Do not reinvent the wheel; always check for modern, standard solutions first.
- Canonical, atomic code—zero tolerance for duplicity.
- Maximize maintainability via separation of concerns and best practices.
- Keep a per-file minimal header including version tracking (see below for format).
- Track project version in a central file (e.g., `morellmmcp/__init__.py`).
- Maintain a `CHANGELOG.md` for major project changes.

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

## Project Structure (Current as of June 2025)

```
moreLLMMCP/
├─ apps/            # All MCP apps (each is a Function App)
│  └─ mcp_server1/  # First MCP app
│      ├─ functions/
│      │   ├─ sse/
│      │   ├─ batch/
│      │   ├─ admin/
│      │   ├─ __init__.py
│      │   ├─ chat_completion_fn.py
│      │   ├─ completion_fn.py
│      │   └─ embeddings_fn.py
│      ├─ mcp/
│      │   ├─ handlers/
│      │   ├─ registry.py
│      │   ├─ models.py
│      │   └─ __init__.py
│      ├─ requirements.txt
│      ├─ host.json
│      └─ ...
├─ mcpdeploy/       # Code deployment scripts/configs
├─ terraform/       # Infra-as-code (Terraform)
├─ scratchpad/      # Design docs, CI/CD, etc.
├─ .github/
├─ .vscode/
├─ .gitignore
├─ .funcignore
├─ README.md
└─ ...
```

**Note:**
- `scratchpad/` contains design docs and CI/CD notes (serves as `docs/` in earlier diagrams).
- `terraform/` and `mcpdeploy/` together serve as `infra/` in earlier diagrams.
- No `shared/` folder is present; add if you need to share code/utilities between apps in the future.

### Rationale & Best Practices
- **Strong Top-Level Folders:**
  - `apps/` for all MCP apps (each is a deployable Function App, cleanly separated).
  - `mcpdeploy/` for code deployment scripts and configurations.
  - `terraform/` for all infrastructure-as-code and deployment automation.
  - `scratchpad/` for design docs, CI/CD notes, and other temporary files.
- **App Isolation:**
  - Each MCP app is self-contained: its own `functions/`, `mcp/`, `requirements.txt`, and `host.json`.
  - Easy to add, remove, or promote MCP apps independently.
- **Discoverability & Maintainability:**
  - Clear boundaries between apps, infra, shared code, and docs.
  - No clutter at the repo root—everything is grouped by purpose.
- **Scalability:**
  - Supports any number of MCP apps, each with any number of endpoints.
  - Shared code is optional and explicit.
- **Azure Functions Compliance:**
  - Each app is deployable as a standard Azure Function App (requirements and host config at app root).

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

## Infrastructure as Code (IaC) Philosophy
- **Only use native Terraform for Azure deployments.**
- **No ARM templates, Bicep, or PowerShell deployment scripts in production.**
- **All environment-specific values are variables; no secrets or IDs are hardcoded.**
- **No orphaned or legacy files in the repo.**
- **.gitignore is strictly enforced for all sensitive, state, and local files.**

## Observability
- Structured logging via `logging.getLogger(__name__)` → Azure Monitor.
- Application Insights traces + custom metrics (e.g., tokens_in, tokens_out).
- Correlate provider latency and errors for each call.

## Canonical MCP Code Deployment
- Deploy the MCP (Azure Functions) code to the provisioned Function App using either:
  - Azure Functions Core Tools:
    ```
    func azure functionapp publish <function_app_name> --python
    ```
  - Azure CLI:
    ```
    az functionapp deployment source config-zip --resource-group <resource_group> --name <function_app_name> --src <zip_file>
    ```
- Do not mix deployment methods for the same environment. Pick one canonical approach (CLI or Core Tools) and document it.
- CI/CD pipeline implementation is parked for now; revisit after direct deployment is validated.

## Implementation Plan

_Phased, actionable, and checkpointed steps for building moreLLMMCP. All testing and validation is done in Azure—no local emulation required. Each phase can be trialed independently. Checkboxes indicate completion status._

### Phase 1: Azure-First Project Scaffold & Core Functionality
- [x] 1. Set up Azure Function App in Azure Portal (Python 3.11, Consumption plan)
    - Configure storage, identity, and app settings as needed.
- [x] 2. Scaffold minimal codebase locally:
    - Create the function folder (e.g., `mcp_sse/`).
    - Implement a minimal HTTP-triggered function for `/runtime/webhooks/mcp/sse`.
    - Add `handlers/`, `registry.py`, and minimal handler logic (even if stubbed).
- [x] 3. Prepare deployment files:
    - Ensure `requirements.txt` (with `azure-functions`, `pydantic`).
    - Ensure `function.json` and `__init__.py` are correct for your function.
    - Ensure `host.json` exists (even minimal: `{ "version": "2.0" }`).
- [x] 4. Migrate all infrastructure to **native Terraform**:
    - Remove all ARM templates, Bicep, and PowerShell deployment scripts.
    - Create minimal `main.tf`, `variables.tf`, and example `.tfvars` for only essential resources (Function App, Storage, App Service Plan, Managed Identity, Application Insights, Action Group).
    - Ensure all environment-specific values are variables; no secrets or IDs are hardcoded.
    - Strictly enforce `.gitignore` for all sensitive, state, and local files.
- [x] 5. Refactor and robustify deployment scripts:
    - Implement canonical, stepwise `deploy.ps1` with canonical log naming and import logic.
    - Ensure all logs, state, and plan files are excluded from git.
    - Remove orphaned and legacy files from the repo.
- [x] 6. Validate and test Terraform deployment:
    - Confirm only required Azure resource providers are registered.
    - Ensure plan/apply works with classic Consumption plan and Linux Function App.
    - Confirm no Flex Consumption or unsupported blocks remain.
- [ ] 7. Deploy to Azure the MCP code using Azure Functions Core Tools.

    **Canonical MCP Code Deployment (Azure Functions Core Tools)**
    - Use Azure Functions Core Tools (`func azure functionapp publish`) as the single, canonical method for deploying the MCP Python code to the provisioned Function App.
    - This approach is minimal, robust, and natively supported by Azure for Python Functions.
    - **Steps:**
      1. Ensure all code, dependencies (`requirements.txt`), and function metadata (`function.json`, `host.json`) are present and correct in your local workspace.
      2. Authenticate to Azure (e.g., `az login` or via environment variables/service principal if in CI).
      3. Run the following command from the project root:
         ```sh
         func azure functionapp publish <function_app_name> --python
         ```
         - Replace `<function_app_name>` with the name of your Azure Function App provisioned by Terraform.
      4. The tool will build, package, and deploy your code in one step, handling all Python-specific requirements.
      5. After deployment, verify the Function App in the Azure Portal and proceed to configure App Settings as needed.
    - **Best Practices:**
      - Do not mix deployment methods (CLI, zip, or pipelines) for the same environment.
      - Document the deployment command and any required environment variables in the README.
      - Use the same method for both manual and automated (CI/CD) deployments for consistency.
    - **Pros:**
      - Minimal, one-command deployment.
      - Handles Python-specific build logic automatically.
      - Natively supported and well-documented by Azure.
    - **Cons:**
      - Requires Core Tools to be installed on the deployment machine or runner.
      - Less flexible for custom build steps (but ideal for canonical Python Azure Functions).
- [ ] 8. Configure Azure App Settings for the MCP Server (environment variables, keys, etc.) in the Azure Portal.
- [ ] 9. Test the endpoint in Azure (Postman, curl, or Copilot Chat) and confirm a valid response.
- [ ] 10. Document the endpoint, deployment process, and any required settings in README/design doc.

**Checkpoint:**  
End-to-end request/response flow with AzureOpenAIHandler, secure and observable, deployed and tested in Azure, with all infrastructure managed natively via Terraform.

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
