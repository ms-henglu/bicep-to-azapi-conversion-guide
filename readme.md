# Bicep to AzAPI Terraform Conversion Guide

This document outlines two methods for converting Bicep templates to Terraform configurations using the AzAPI provider: AI-assisted conversion and the Bicep2AzAPI tool.

The conversion process described in this guide is based on static text analysis of the Bicep templates. The templates do not need to be deployed to Azure for the conversion to work.

### Limitations

There are two main categories of limitations when converting Bicep to Terraform:

#### 1. Functions

While Terraform has a rich set of built-in functions, it does not have a 1:1 mapping for every Bicep function. Specifically:

*   **`indexOf`**: Terraform does not have a built-in function to find the index of a substring within a string.
*   **`lastIndexOf`**: Similar to `indexOf`, there is no direct equivalent.
*   **`padLeft` / `padRight`**: String padding functions are not natively available.
*   **`dataUri`**: Converting content to a data URI requires a combination of `base64encode` and string interpolation, but there isn't a single dedicated function.
*   **`dateTimeAdd`**: Date manipulation is limited in Terraform compared to Bicep's date functions.

For these cases, you may need to implement workarounds using `locals` with complex expressions, or handle the logic outside of Terraform (e.g., in a script or pre-processing step).

#### 2. Modules

Bicep modules may not have an exact equivalent in the Terraform Registry. You may need to convert the Bicep module using the methods described in this guide and then use the converted module in your Terraform configuration.

## Expected Mappings

The following table outlines how Bicep concepts are expected to map to Terraform configurations:

| Bicep Concept | Terraform Concept | Description |
| :--- | :--- | :--- |
| **Parameters** (`param`) | **Variables** (`variable`) | Input parameters in Bicep become input variables in Terraform. Decorators like `@allowed` and `@minLength` are converted to `validation` blocks. |
| **Variables** (`var`) | **Locals** (`locals`) | Intermediate variables in Bicep are converted to local values in Terraform. |
| **Resources** (`resource`) | **Resources** (`resource "azapi_resource"`) | Azure resources are mapped to the `azapi_resource` type. The `body` attribute is used to define properties dynamically. |
| **Outputs** (`output`) | **Outputs** (`output`) | Return values are mapped to Terraform outputs. |
| **Modules** (`module`) | **Modules** (`module`) | Bicep modules are converted to Terraform module blocks. |
| **Existing Resources** (`existing`) | **Data Sources** (`data`) | References to pre-existing resources are converted to Terraform data sources (e.g., `data "azapi_resource"`). |
| **Functions** | **Built-in Functions** | Bicep functions are mapped to their Terraform equivalents (e.g., `toLower` -> `lower`, `format` -> `format`). |

### Mapping Examples

The following examples demonstrate how specific Bicep keywords translate to Terraform configuration using the AzAPI provider.

#### Parameters (`param`)

**Bicep:**
```bicep
param location string = 'eastus'
```

**Terraform:**
```hcl
variable "location" {
  type    = string
  default = "eastus"
}
```

#### Variables (`var`)

**Bicep:**
```bicep
var storageName = 'st${uniqueString(resourceGroup().id)}'
```

**Terraform:**
```hcl
locals {
  # Note: uniqueString logic may need adjustment in Terraform
  storage_name = "st${substr(sha256(data.azurerm_resource_group.example.id), 0, 13)}"
}
```

#### Resources (`resource`)

**Bicep:**
```bicep
resource st 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name = 'examplestorage'
  location = 'eastus'
  sku = {
    name = 'Standard_LRS'
  }
  kind = 'StorageV2'
}
```

**Terraform:**
```hcl
resource "azapi_resource" "st" {
  type      = "Microsoft.Storage/storageAccounts@2021-04-01"
  name      = "examplestorage"
  location  = "eastus"
  parent_id = data.azurerm_resource_group.example.id

  body = {
    sku = {
      name = "Standard_LRS"
    }
    kind = "StorageV2"
  }
}
```

#### Existing Resources (`existing`)

**Bicep:**
```bicep
resource st 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name = 'existingstorage'
}
```

**Terraform:**
```hcl
data "azapi_resource" "st" {
  type      = "Microsoft.Storage/storageAccounts@2021-04-01"
  name      = "existingstorage"
  parent_id = data.azurerm_resource_group.example.id
}
```

#### Outputs (`output`)

**Bicep:**
```bicep
output storageId string = st.id
```

**Terraform:**
```hcl
output "storage_id" {
  value = azapi_resource.st.id
}
```

## Test Cases

The following Bicep templates were used to evaluate both conversion methods:

*   Canonical Anbox (`canonical-anbox/`)
*   Analysis Services (`analysis-services-create/`)
*   API Center (`azure-api-center-create/`)
*   API Management (`azure-api-management-create/`)
*   Simple Linux VM (`vm-simple-linux/`)
*   Storage Account (`storage-account-create/`)
*   Web App (`webapp-basic-linux/`)
*   Key Vault (`key-vault-create/`)
*   Bicep Functions (`bicep-functions/`)

## Option 1: AI-Assisted Conversion

This approach utilizes AI to directly convert Bicep templates into Terraform code, splitting the output into standard module files (`main.tf`, `variables.tf`, `outputs.tf`).

### Methodology

**Prompt Used:**
```text
Convert this Bicep template to a Terraform configuration using the azapi provider. Please split the result into main.tf, variables.tf, and outputs.tf.

**Important Requirement:** Do not use jsonencode or jsondecode functions for the body or output attributes. Instead, treat them as dynamic attributes (native HCL maps/objects) as supported by the latest version of the provider.
```

### Evaluation Results

All test cases were successfully converted.

### Observations

*   **Structure:** Correctly follows standard Terraform module structure (`main.tf`, `variables.tf`, `outputs.tf`).
*   **AzAPI Usage:** `azapi_resource` is correctly implemented with appropriate types, versions, and properties.
*   **Body Attributes:** Uses native HCL maps/objects as requested.
*   **Variables & Outputs:** Bicep parameters and outputs are accurately mapped to Terraform variables (including validation) and outputs.
*   **Function Limitations:** Terraform lacks a direct built-in equivalent for Bicep's `indexOf` function when used with strings.

## Option 2: Bicep2AzAPI Tool

This approach uses the [`Bicep2AzAPI`](https://github.com/ms-henglu/bicep2azapi) tool to automate the conversion process.

**Note:** This project is currently a Proof of Concept (POC) and is not yet finished. It requires manual implementation for all Bicep functions to be fully supported.

### Evaluation Results

The tool successfully converted all test cases in the `using-bicep2azapi` directory.

### Observations

*   **File Structure:** Generates `main.tf` and `provider.tf`. Variables and outputs are included within `main.tf` rather than split into separate files.
*   **AzAPI Usage:** Correctly maps resource types and API versions.
*   **Body Attributes:** Populates `body` using native HCL maps/objects.
*   **Logic Conversion:** Successfully converts Bicep conditional logic (ternary operators) to Terraform expressions.
*   **Limitations:** Some complex default values resulted in warnings (e.g., `//[WARN] Variables not allowed as default input value`).

### Known Limitations

*   **Parameter Validation:** `@minLength` and `@maxLength` are not fully supported.
*   **Functions:** Limited support for Bicep functions (e.g., `contains`, `take`, `indexOf`, `length` only support arrays).
*   **Type Conversion:** The `any` function is ignored.
*   **Expressions:** Map keys cannot be expressions (e.g., in tags).
*   **Multi-line Strings:** Multi-line strings are not supported.

## Summary and Recommendation

Based on the evaluation results, the **AI-Assisted Conversion (Option 1)** is the recommended approach for converting Bicep templates to Terraform configurations using the AzAPI provider.

**Key Advantages of AI-Assisted Conversion:**

*   **Better Code Structure:** Automatically splits code into standard `main.tf`, `variables.tf`, and `outputs.tf` files, promoting better maintainability.
*   **Superior Logic Handling:** More effectively translates Bicep logic and functions into their Terraform equivalents.
*   **Cleaner Output:** Produces more idiomatic Terraform code with fewer limitations compared to the automated tool.
*   **Flexibility:** Can adapt to complex scenarios that might trip up a static analysis tool.

While the `Bicep2AzAPI` tool provides a quick starting point, the AI-assisted method delivers a higher-quality, more complete result that requires less manual cleanup.


