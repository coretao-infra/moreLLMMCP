# CI/CD Pipeline Design for moreLLMMCP

This document describes the canonical approach to continuous integration and continuous deployment (CI/CD) for the moreLLMMCP project, following strict minimalism, security, and Azure-native best practices.

## Goals
- Automate infrastructure provisioning (Terraform) and code deployment (Azure Functions) using a public repository.
- Ensure all secrets and environment-specific values are managed securely (never in source control).
- Use only natively supported, modern Azure and GitHub features.
- Keep the pipeline logic minimal, robust, and easy to audit.

## Pipeline Overview

### 1. Infrastructure Provisioning (Terraform)
- **Trigger:** Manual or on changes to `terraform/`.
- **Steps:**
  1. Authenticate to Azure using a service principal or OIDC.
  2. Provide `terraform.tfvars` securely (GitHub/Azure pipeline secrets or secure files).
  3. Run `terraform init`, `plan`, and `apply` to provision/update resources.
- **Best Practice:** Do not store `terraform.tfvars` or secrets in the repo. Use example files for documentation.

### 2. MCP Code Deployment (Azure Functions)
- **Trigger:** On push to `main` or release branch, or manually.
- **Steps:**
  1. Build/package the Python Azure Functions app.
  2. Authenticate to Azure.
  3. Deploy code to the provisioned Function App using Azure Functions Core Tools or Azure CLI.
  4. Optionally, run post-deployment tests (curl, Postman, etc.).
- **Best Practice:** Keep code and infrastructure deployment steps separate for clarity and security.

### 3. Secrets & App Settings
- **Never** commit secrets or environment-specific values to the repo.
- Use pipeline secrets, Azure App Settings, or Key Vault for all sensitive values.
- Document required settings in `terraform.tfvars.example` and `README.md`.

## Managing Pipelines with Terraform
- You can use Terraform to manage pipeline/workflow files (e.g., `github_actions_workflow` for GitHub Actions), but the pipeline logic itself is written in YAML and managed as code.
- Secrets for pipelines are managed outside of Terraform (in GitHub or Azure DevOps UI/API).

## Example Pipeline Scenarios
- **GitHub Actions:** Use workflow YAML files in `.github/workflows/` to automate both Terraform and code deployment.
- **Azure DevOps:** Use pipeline YAML files or classic UI for similar automation.

## References
- [Terraform GitHub Provider: github_actions_workflow](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_workflow)
- [Azure DevOps Provider: azuredevops_build_definition](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/build_definition)
- [Azure Functions Python Deployment](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies)

---

*Add further CI/CD design notes, pipeline examples, and decisions below as the project evolves.*
