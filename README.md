# Tailwind Traders Sandbox

Deploys tailwindtraders.com and back-end services in an Azure Kubernetes Service cluster.

## Prerequisites

Service principle client id and secret stored in an Azure Key Vault.

## Deploy

Update `RESOURCE_GROUP` and `KEY_VAULT_NAME` in the deploy.sh script and then run the script. The deployment will take many minutes. All infrastructure is deployed, container images are built and stored in Azure Container Registry, and all services are deployed to the AKS cluster.

```
$ sh deploy.sh
```

Once done, run `kubectl get ingress` and grab any one of the `HOST` names. This address will take you to the tailwindtreaders.com web site.

## Source Repositories

https://github.com/microsoft/TailwindTraders

https://github.com/microsoft/TailwindTraders-Backend

https://github.com/microsoft/TailwindTraders-Website
