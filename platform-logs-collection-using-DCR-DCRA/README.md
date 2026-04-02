# Platform Logs Collection using DCR and DCRA

This project provides infrastructure-as-code (IaC) templates to collect **Azure platform logs** using [Azure Monitor Data Collection Rules (DCR)](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview) and [Data Collection Rule Associations (DCRA)](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-associations), and route them to three destinations simultaneously:

| Destination | Purpose |
|---|---|
| **Log Analytics Workspace** | Query, alert, and visualize logs with KQL |
| **Azure Storage Account** | Long-term archival and compliance |
| **Azure Event Hub** | Real-time streaming to SIEM, Splunk, etc. |

Templates are provided in three formats so they work for any Azure operator:

| Format | Files | Best for |
|---|---|---|
| **ARM** | `arm/` | Azure Portal, CI/CD pipelines, Azure DevOps |
| **Bicep** | `bicep/` | Modern Azure-native IaC with type safety |
| **Terraform** | `terraform/` | Multi-cloud teams, GitOps, Terraform Cloud |

---

## Architecture overview

```
  ┌─────────────────────────────────────────────┐
  │          Target Resource (VM / VMSS)         │
  │    Azure Monitor Agent (AMA) installed       │
  └──────────────────┬──────────────────────────┘
                     │  DCRA (association)
                     ▼
  ┌─────────────────────────────────────────────┐
  │        Data Collection Rule (DCR)            │
  │  • Windows Event Logs (Security/System/App)  │
  │  • Linux Syslog                              │
  │  • Data transformation via KQL              │
  └────────┬─────────────────┬──────────────────┘
           │                 │                 │
           ▼                 ▼                 ▼
  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
  │  Log Analytics│ │   Storage    │ │    Event Hub     │
  │  Workspace   │ │   Account    │ │    Namespace     │
  └──────────────┘ └──────────────┘ └──────────────────┘
```

---

## Prerequisites

- An active **Azure subscription**
- **Azure CLI** ≥ 2.50 (for ARM / Bicep deployments)
- **Bicep CLI** ≥ 0.21 (installed automatically with `az bicep install`)
- **Terraform** ≥ 1.3.0 (for Terraform deployments)
- The following resources must exist before deploying:
  - Log Analytics Workspace
  - Storage Account (with a blob container, default: `platform-logs`)
  - Event Hub Namespace (and optionally a specific Event Hub)
  - Azure Monitor Agent installed on target VMs (for DCRA)

---

## Quick start

### ARM templates

```bash
# 1. Edit arm/parameters.json with your resource IDs
# 2. Deploy
chmod +x scripts/deploy-arm.sh
./scripts/deploy-arm.sh \
  --subscription  <subscription-id> \
  --resource-group rg-platform-logs \
  --location eastus
```

### Bicep templates

```bash
# 1. Edit bicep/main.bicepparam with your resource IDs
# 2. Deploy
chmod +x scripts/deploy-bicep.sh
./scripts/deploy-bicep.sh \
  --subscription  <subscription-id> \
  --resource-group rg-platform-logs \
  --location eastus
```

### Terraform

```bash
# 1. Copy and edit the example tfvars file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your values

# 2. Deploy
chmod +x scripts/deploy-terraform.sh
./scripts/deploy-terraform.sh

# Destroy when no longer needed
./scripts/deploy-terraform.sh --destroy
```

---

## Project structure

```
platform-logs-collection-using-DCR-DCRA/
├── README.md                              ← This file
│
├── arm/                                   ← ARM JSON templates
│   ├── datacollectionrule.json            ← Standalone DCR template
│   ├── datacollectionruleassociation.json ← Standalone DCRA template
│   ├── main.json                          ← Orchestration template (DCR + optional DCRA)
│   └── parameters.json                    ← Example parameters
│
├── bicep/                                 ← Bicep templates
│   ├── datacollectionrule.bicep           ← DCR module
│   ├── datacollectionruleassociation.bicep← DCRA module
│   ├── main.bicep                         ← Main entry point (DCR + optional DCRA)
│   └── main.bicepparam                    ← Example parameters file
│
├── terraform/                             ← Terraform configuration
│   ├── providers.tf                       ← AzureRM provider configuration
│   ├── variables.tf                       ← Input variable definitions
│   ├── main.tf                            ← DCR + DCRA resources
│   ├── outputs.tf                         ← Output values
│   └── terraform.tfvars.example           ← Example variable values
│
└── scripts/                               ← Deployment helper scripts
    ├── deploy-arm.sh                      ← Deploy via ARM
    ├── deploy-bicep.sh                    ← Deploy via Bicep
    └── deploy-terraform.sh               ← Deploy via Terraform
```

---

## Parameters reference

All three template formats expose the same logical parameters:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `dcrName` / `dcr_name` | string | `dcr-platform-logs` | Name of the DCR |
| `location` | string | resource group location | Azure region |
| `logAnalyticsWorkspaceResourceId` | string | — | Full resource ID of the Log Analytics Workspace |
| `storageAccountResourceId` | string | — | Full resource ID of the Storage Account |
| `eventHubNamespaceResourceId` | string | — | Full resource ID of the Event Hub Namespace |
| `eventHubName` / `event_hub_name` | string | `""` | Specific Event Hub name (optional) |
| `storageContainerName` / `storage_container_name` | string | `platform-logs` | Blob container name |
| `collectWindowsEvents` / `collect_windows_events` | bool | `true` | Enable Windows event log collection |
| `collectSyslog` / `collect_syslog` | bool | `true` | Enable Linux Syslog collection |
| `createAssociation` / `create_association` | bool | `false` | Create DCRA linking DCR to a target resource |
| `associationName` / `association_name` | string | `dcra-platform-logs` | Name of the DCRA |
| `targetResourceId` / `target_resource_id` | string | `""` | Resource ID of the target resource for DCRA |
| `tags` | object/map | see defaults | Resource tags |

### Windows event XPath queries (default)

```
Security!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]
System!*[System[(Level=1 or Level=2 or Level=3)]]
Application!*[System[(Level=1 or Level=2 or Level=3)]]
```

### Syslog facilities and levels (default)

| Facilities | Levels |
|---|---|
| auth, authpriv, cron, daemon, kern, syslog, user | Error, Critical, Alert, Emergency, Warning |

---

## Data flows

The DCR defines two data flows:

| Stream | Destinations |
|---|---|
| `Microsoft-Event` (Windows events) | Log Analytics, Storage, Event Hub |
| `Microsoft-Syslog` (Linux syslog) | Log Analytics, Storage, Event Hub |

Both flows use `source` as the KQL transform (pass-through). You can customise the `transformKql` field to filter or enrich data before forwarding.

---

## Creating a DCRA (associating the DCR to a VM)

Set `createAssociation = true` (or `create_association = true` in Terraform) and provide the full resource ID of the target resource:

**ARM / Bicep parameter:**
```json
"createAssociation": { "value": true },
"targetResourceId":  { "value": "/subscriptions/.../virtualMachines/my-vm" }
```

**Terraform tfvars:**
```hcl
create_association = true
target_resource_id = "/subscriptions/.../virtualMachines/my-vm"
```

> **Note:** The Azure Monitor Agent (AMA) must be installed on the target VM before logs can flow.

---

## Outputs

| Output | Description |
|---|---|
| `dcrResourceId` / `dcr_resource_id` | Full resource ID of the DCR |
| `dcrImmutableId` / `dcr_immutable_id` | Immutable ID (used in advanced data pipelines) |
| `dcrName` / `dcr_name` | Name of the DCR |
| `dcra_resource_id` | Full resource ID of the DCRA (Terraform only; empty if not created) |

---

## Security considerations

- Assign the **Monitoring Contributor** role to the identity performing the deployment.
- The Storage Account and Event Hub should have **network rules** restricting access to Azure Monitor service tags.
- Use **Azure Private Link** for Event Hub and Storage to prevent data exfiltration over the public internet.
- Enable **diagnostic settings** on the DCR itself to audit configuration changes.

---

## References

- [Azure Monitor Data Collection Rules overview](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview)
- [Azure Monitor Agent overview](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview)
- [Data Collection Rule REST API](https://learn.microsoft.com/en-us/rest/api/monitor/data-collection-rules)
- [Terraform azurerm_monitor_data_collection_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule)
- [Bicep resource reference – Microsoft.Insights/dataCollectionRules](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/datacollectionrules)
