# Variables for moreLLMMCP Terraform deployment

variable "resource_group_name" {
  description = "Name of the Azure Resource Group. Must be globally unique."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Storage Account (3-24 lowercase letters/numbers). Must be globally unique."
  type        = string
}

variable "function_app_name" {
  description = "Name of the Function App (1-60 lowercase letters/numbers/hyphens). Must be globally unique."
  type        = string
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan."
  type        = string
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (e.g., FC1, Y1)."
  type        = string
}

variable "identity_name" {
  description = "Name of the User Assigned Managed Identity."
  type        = string
}

variable "app_insights_name" {
  description = "Name of the Application Insights resource."
  type        = string
}

variable "app_insights_retention_days" {
  description = "Retention in days for Application Insights logs."
  type        = number
  default     = 90
}

variable "function_app_runtime" {
  description = "Linux FX version for the Function App (e.g., Python|3.11)."
  type        = string
  default     = "Python|3.11"
}

variable "function_app_worker_runtime" {
  description = "Worker runtime for the Function App (e.g., python)."
  type        = string
  default     = "python"
}

variable "action_group_name" {
  description = "Name of the Action Group for monitoring."
  type        = string
}

variable "action_group_short_name" {
  description = "Short name for the Action Group."
  type        = string
  default     = "SmartDetect"
}

variable "subscription_id" {
  description = "The Azure Subscription ID to use for deployments."
  type        = string
}
