##############################################################################
# Outputs – Platform Logs DCR / DCRA
##############################################################################

output "dcr_resource_id" {
  description = "Full Azure resource ID of the Data Collection Rule."
  value       = azurerm_monitor_data_collection_rule.platform_logs.id
}

output "dcr_immutable_id" {
  description = "Immutable ID of the Data Collection Rule (used when referencing the DCR in data flows)."
  value       = azurerm_monitor_data_collection_rule.platform_logs.immutable_id
}

output "dcr_name" {
  description = "Name of the Data Collection Rule."
  value       = azurerm_monitor_data_collection_rule.platform_logs.name
}

output "dcra_resource_id" {
  description = "Full Azure resource ID of the Data Collection Rule Association (empty if not created)."
  value       = var.create_association && var.target_resource_id != "" ? azurerm_monitor_data_collection_rule_association.platform_logs[0].id : ""
}
