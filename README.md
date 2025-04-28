# Azure Infrastructure as Code (IaC) with Bicep

This repository contains Bicep templates for deploying a complete infrastructure setup on Azure. The templates are modular and designed to provision resources such as Virtual Networks, Application Gateway, AKS Cluster, PostgreSQL Flexible Server, Azure Container Registry (ACR), Key Vault, and Network Security Groups (NSGs).

## Table of Contents

-   [Overview](#overview)
-   [Prerequisites](#prerequisites)
-   [Modules](#modules)
-   [Deployment](#deployment)
-   [Outputs](#outputs)
-   [CI/CD Workflow](#cicd-workflow)

---

## Overview

This project uses Bicep, a domain-specific language (DSL) for deploying Azure resources declaratively. The infrastructure is modularized into separate Bicep files for better maintainability and reusability.

### Key Features:

-   **Virtual Network (VNet)** with public, private, and PostgreSQL subnets.
-   **Application Gateway** with Web Application Firewall (WAF) enabled.
-   **AKS Cluster** integrated with Application Gateway Ingress Controller (AGIC).
-   **Azure Container Registry (ACR)** for container image storage.
-   **Azure Key Vault** for secure secret management.
-   **PostgreSQL Flexible Server** with private endpoint and DNS zone delegation.
-   **Network Security Groups (NSGs)** for securing subnets with granular rules.

---

## Prerequisites

1. **Azure CLI**: Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
2. **Bicep CLI**: Install the [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install).
3. **Azure Subscription**: Ensure you have an active Azure subscription.
4. **GitHub Secrets**: Set the following secrets in your GitHub repository for the CI/CD workflow:
    - `AZURE_CLIENT_ID`
    - `AZURE_TENANT_ID`
    - `AZURE_SUBSCRIPTION_ID`

---

## Modules

### 1. **[main.bicep](main.bicep)**

-   Orchestrates the deployment by referencing all other modules.

### 2. **[network.bicep](network.bicep)**

-   Creates a Virtual Network with public, private, and PostgreSQL subnets.
-   Includes subnet delegation for PostgreSQL Flexible Server.

### 3. **[publicip.bicep](publicip.bicep)**

-   Provisions a static public IP address for the Application Gateway.

### 4. **[appgateway.bicep](appgateway.bicep)**

-   Deploys an Application Gateway with WAF enabled.
-   Configures backend pools, HTTP settings, listeners, and routing rules.

### 5. **[aks.bicep](aks.bicep)**

-   Deploys an AKS cluster with AGIC enabled.
-   Configures private cluster access and assigns a role to the Application Gateway.

### 6. **[acr.bicep](acr.bicep)**

-   Creates an Azure Container Registry and assigns pull permissions to the AKS cluster.

### 7. **[keyvault.bicep](keyvault.bicep)**

-   Deploys an Azure Key Vault and grants access to the AKS cluster.

### 8. **[postgres.bicep](postgres.bicep)**

-   Provisions a PostgreSQL Flexible Server with private endpoint and DNS zone delegation.

### 9. **[nsg.bicep](nsg.bicep)**

-   Configures Network Security Groups for public, private, and PostgreSQL subnets.
-   Includes rules for AKS, Application Gateway, and PostgreSQL communication.

---

## Deployment

### 1. **Manual Deployment**

Use the Azure CLI to deploy the infrastructure:

```bash
az deployment group create \
  --resource-group <your-resource-group-name> \
  --template-file main.bicep \
  --parameters location=<location> postgresAdminPassword=<secure-password>
```

---

## Outputs

The deployment generates the following outputs:

-   **Virtual Network**:

    -   `vnetId`: ID of the Virtual Network.
    -   `publicSubnetId`: ID of the public subnet.
    -   `privateSubnetId`: ID of the private subnet.
    -   `postgresSubnetId`: ID of the PostgreSQL subnet.

-   **Application Gateway**:

    -   `appGwId`: ID of the Application Gateway.

-   **AKS Cluster**:

    -   `aksPrincipalId`: Principal ID of the AKS cluster.

-   **Azure Container Registry**:

    -   `acrId`: ID of the ACR.
    -   `acrLoginServer`: Login server URL of the ACR.

-   **Key Vault**:

    -   `keyVaultUri`: URI of the Key Vault.

-   **PostgreSQL Server**:
    -   `postgresServerId`: ID of the PostgreSQL server.
    -   `postgresFullyQualifiedDomainName`: FQDN of the PostgreSQL server.

---

## CI/CD Workflow

This repository includes a GitHub Actions workflow to automate the validation and deployment of the Bicep templates.

### Workflow Features:

1. **Validation**: Ensures the Bicep templates are syntactically correct.
2. **Deployment**: Deploys the templates to the specified Azure resource group.

### Trigger:

-   The workflow is triggered on push or pull requests to the `main` branch.

### Configuration:

-   Ensure the following GitHub Secrets are set in your repository:
    -   `AZURE_CLIENT_ID`
    -   `AZURE_TENANT_ID`
    -   `AZURE_SUBSCRIPTION_ID`

### Workflow File:

-   The workflow file is located at `.github/workflows/deploy-infra.yaml`.
