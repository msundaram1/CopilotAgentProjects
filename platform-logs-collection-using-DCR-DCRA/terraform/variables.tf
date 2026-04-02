##############################################################################
# Core resource variables
##############################################################################

variable "resource_group_name" {
  type        = string
  description = "Name of the existing Resource Group where the DCR will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region for the Data Collection Rule."
  default     = "eastus"
}

variable "dcr_name" {
  type        = string
  description = "Name of the Data Collection Rule."
  default     = "dcr-platform-logs"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
  default = {
    purpose    = "platform-logs-collection"
    managed_by = "azure-monitor"
  }
}

##############################################################################
# Destination – Log Analytics Workspace
##############################################################################

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Full resource ID of the Log Analytics Workspace destination."
}

##############################################################################
# Destination – Storage Account
##############################################################################

variable "storage_account_resource_id" {
  type        = string
  description = "Full resource ID of the Storage Account destination."
}

variable "storage_container_name" {
  type        = string
  description = "Name of the blob container in the Storage Account for platform logs."
  default     = "platform-logs"
}

##############################################################################
# Destination – Event Hub
##############################################################################

variable "event_hub_namespace_resource_id" {
  type        = string
  description = "Full resource ID of the Event Hub Namespace destination."
}

variable "event_hub_name" {
  type        = string
  description = "Optional: specific Event Hub name within the namespace. Leave empty to use the namespace default."
  default     = ""
}

##############################################################################
# Data Sources
##############################################################################

variable "collect_windows_events" {
  type        = bool
  description = "Whether to collect Windows Security, System and Application event logs."
  default     = true
}

variable "collect_syslog" {
  type        = bool
  description = "Whether to collect Linux Syslog data."
  default     = true
}

variable "windows_event_xpath_queries" {
  type        = list(string)
  description = "XPath queries that define which Windows events to collect."
  default = [
    "Security!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]",
    "System!*[System[(Level=1 or Level=2 or Level=3)]]",
    "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
  ]
}

variable "syslog_facility_names" {
  type        = list(string)
  description = "Syslog facility names to collect."
  default     = ["auth", "authpriv", "cron", "daemon", "kern", "syslog", "user"]
}

variable "syslog_log_levels" {
  type        = list(string)
  description = "Syslog log levels to collect."
  default     = ["Error", "Critical", "Alert", "Emergency", "Warning"]
}

##############################################################################
# DCRA (optional)
##############################################################################

variable "create_association" {
  type        = bool
  description = "Set to true to create a DCRA linking the DCR to a target Azure resource."
  default     = false
}

variable "association_name" {
  type        = string
  description = "Name of the Data Collection Rule Association (used when create_association = true)."
  default     = "dcra-platform-logs"
}

variable "target_resource_id" {
  type        = string
  description = "Full resource ID of the target resource (e.g., VM) to associate with the DCR."
  default     = ""
}
