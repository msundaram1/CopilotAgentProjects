##############################################################################
# Data Collection Rule (DCR) – Platform Logs
##############################################################################

locals {
  # Build the data_sources block dynamically based on toggle variables
  windows_event_data_sources = var.collect_windows_events ? [
    {
      name            = "windows-event-logs"
      streams         = ["Microsoft-Event"]
      x_path_queries  = var.windows_event_xpath_queries
    }
  ] : []

  syslog_data_sources = var.collect_syslog ? [
    {
      name           = "linux-syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = var.syslog_facility_names
      log_levels     = var.syslog_log_levels
    }
  ] : []

  event_hub_name = var.event_hub_name != "" ? var.event_hub_name : null
}

resource "azurerm_monitor_data_collection_rule" "platform_logs" {
  name                = var.dcr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  description         = "Data Collection Rule for collecting platform logs and sending to Log Analytics, Storage Account, and Event Hub."

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_resource_id
      name                  = "law-destination"
    }

    storage_blob {
      storage_account_id = var.storage_account_resource_id
      container_name     = var.storage_container_name
      name               = "storage-destination"
    }

    event_hub {
      event_hub_id = var.event_hub_namespace_resource_id
      name         = "eventhub-destination"
    }
  }

  # Windows Event Logs data source (conditional)
  dynamic "data_sources" {
    for_each = length(local.windows_event_data_sources) > 0 ? [1] : []
    content {
      dynamic "windows_event_log" {
        for_each = local.windows_event_data_sources
        content {
          name            = windows_event_log.value.name
          streams         = windows_event_log.value.streams
          x_path_queries  = windows_event_log.value.x_path_queries
        }
      }
    }
  }

  # Syslog data source (conditional)
  dynamic "data_sources" {
    for_each = length(local.syslog_data_sources) > 0 ? [1] : []
    content {
      dynamic "syslog" {
        for_each = local.syslog_data_sources
        content {
          name           = syslog.value.name
          streams        = syslog.value.streams
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
        }
      }
    }
  }

  data_flow {
    streams       = ["Microsoft-Event"]
    destinations  = ["law-destination", "storage-destination", "eventhub-destination"]
    output_stream = "Microsoft-Event"
    transform_kql = "source"
  }

  data_flow {
    streams       = ["Microsoft-Syslog"]
    destinations  = ["law-destination", "storage-destination", "eventhub-destination"]
    output_stream = "Microsoft-Syslog"
    transform_kql = "source"
  }
}

##############################################################################
# Data Collection Rule Association (DCRA) – optional
##############################################################################

resource "azurerm_monitor_data_collection_rule_association" "platform_logs" {
  count = var.create_association && var.target_resource_id != "" ? 1 : 0

  name                    = var.association_name
  target_resource_id      = var.target_resource_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.platform_logs.id
  description             = "Association between target resource and platform logs DCR."
}
