# OPS Learning Path Template (dev)

Templates will be used for OPS10 - OPS40.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Ftailwind-reference-deployment-sandbox%2Fmaster%2Fdeployment-ops-full%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Browse to the Tailwind website

## Trigger the OPS20 incident logic app

## Browse to the OPS20 Status Page

Find the App Service with a name like `status-` and then a random string.

![Azure portal with an arrow pointing at an app service named status-randomstring](images/status-page.png)

The Tailwind status page can be reached at the App Service URL.

![Azure portal with an arrow pointing at an app service URL](images/url.png)

## Create the OPS40 CI/CD Pipeline

## How is this deployment structured

```
azuredeploy.jsonL parameter value intake and calls all linked deployments
    |_azuredeploy-tailwind.json: deploys an AKS cluster and other infrastructure needed for Tailwind
    |_azuredeploy-azd.json: deploys an Azure DevOps organization and project
    |_azuredeploy-logic-apps.json: deploys the OPS20 logic apps and api connections
    |_azuredeploy-status.json: deploys the OPS20 status page
    |_deploy.sh: runs apps on Kubernetes and some other post-processing items
        |_azure-table.py: Adds the OPS20 `oncall` and `statuses` table
```
