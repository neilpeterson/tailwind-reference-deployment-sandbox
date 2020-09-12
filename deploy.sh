#!/bin/bash

# Update resource group name and Key Vault name where service principal  credentials are stored
RESOURCE_GROUP=tailwind-dot-com
KEY_VAULT_NAME=nepeters-keyvault

# These do not need updating
CONTAINER_TAG=v1
CHARTS=./TailwindTraders-Backend/Deploy/helm/
CHART_VALUES=./TailwindTraders-Backend/Deploy/powershell/twt-backend.yaml
WEB_SITE_IMAGES=/TailwindTraders-Backend/Deploy/tt-images

# Get service principle from Key Vault
CLIENT_ID=$(az keyvault secret show --name aksClisntId --vault-name $KEY_VAULT_NAME --query value -o tsv)
CLIENT_SECRET=$(az keyvault secret show --name aksclientSecret --vault-name $KEY_VAULT_NAME --query value -o tsv)

# Get Tailwind Backend repository
git clone https://github.com/microsoft/TailwindTraders-Backend.git
cd TailwindTraders-Backend

# Deploy cluster and other resources
az group create --name $RESOURCE_GROUP --location eastus
az deployment group create --template-file ./TailwindTraders-Backend/Deploy/arm/deployment.json --resource-group=$RESOURCE_GROUP --parameters servicePrincipalId=$CLIENT_ID --parameters servicePrincipalSecret=$CLIENT_SECRET --parameters aksVersion=1.18.6

# Generate values file
pwsh ./TailwindTraders-Backend/Deploy/powershell/Generate-Config.ps1 -RESOURCE_GROUP $RESOURCE_GROUP -outputFile ./twt-backend.yaml

# Get AKS credentials
AKS_NAME=$(az aks list --resource-group $RESOURCE_GROUP --query [0].name -o tsv)
az aks get-credentials --name $AKS_NAME --resource-group $RESOURCE_GROUP

# Create AKS secrets / configure auth with ACR_NAME
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query [0].name -o tsv)
pwsh ./TailwindTraders-Backend/Deploy/powershell/Create-Secret.ps1 -RESOURCE_GROUP $RESOURCE_GROUP -acrName $ACR_NAME

# Build images and store in ACR_NAME
cd ./TailwindTraders-Backend/Source # Dockerfile ADD issue, fix later
az acr build -t cart.api:$CONTAINER_TAG -r $ACR_NAME ./Services/Tailwind.Traders.Cart.Api/
az acr build -t coupon.api:$CONTAINER_TAG -r $ACR_NAME ./Services/Tailwind.Traders.Coupon.Api/
az acr build -t image-classifier.api:$CONTAINER_TAG -r $ACR_NAME -f ./Services/Tailwind.Traders.ImageClassifier.Api/Dockerfile .
az acr build -t login.api:$CONTAINER_TAG -r $ACR_NAME -f ./Services/Tailwind.Traders.Login.Api/Dockerfile .
az acr build -t popular-product.api:$CONTAINER_TAG -r $ACR_NAME -f ./Services/Tailwind.Traders.PopularProduct.Api/Dockerfile .
az acr build -t product.api:$CONTAINER_TAG -r $ACR_NAME -f ./Services/Tailwind.Traders.Product.Api/Dockerfile .
az acr build -t profile.api:$CONTAINER_TAG -r $ACR_NAME -f ./Services/Tailwind.Traders.Profile.Api/Dockerfile .
az acr build -t stock.api:$CONTAINER_TAG -r $ACR_NAME ./TailwindTraders-BackendServices/Tailwind.Traders.Stock.Api/
az acr build -t mobileapigw:$CONTAINER_TAG -r $ACR_NAME -f ./ApiGWs/Tailwind.Traders.Bff/Dockerfile .
az acr build -t webapigw:$CONTAINER_TAG -r $ACR_NAME -f ./ApiGWs/Tailwind.Traders.WebBff/Dockerfile .
cd ../../ # Dockerfile ADD issue, fix later

# Get Application Insights key
APP_INSIGHTS_KEY=$(az monitor app-insights component show --resource-group $RESOURCE_GROUP --query [0].instrumentationKey -o tsv)

# Get Ingress value
INGRESS=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query addonProfiles.httpapplicationrouting.config.httpapplicationroutingzonename -o tsv)

# Install backend
helm install my-tt-product -f $CHART_VALUES --set az.productvisitsurl=http://your-product-visits-af-here --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/product.api --set image.tag=$CONTAINER_TAG $CHARTS/products-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-coupon -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/coupon.api --set image.tag=$CONTAINER_TAG $CHARTS/coupons-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-profile -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/profile.api --set image.tag=$CONTAINER_TAG $CHARTS/profiles-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-popular-product -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/popular-product.api --set image.tag=$CONTAINER_TAG --set initImage.repository=$ACR_NAME.azurecr.io/popular-product-seed.api --set initImage.tag=latest $CHARTS/popular-products-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-stock -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/stock.api --set image.tag=$CONTAINER_TAG $CHARTS/stock-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-image-classifier -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/image-classifier.api --set image.tag=$CONTAINER_TAG $CHARTS/image-classifier-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-cart -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/cart.api --set image.tag=$CONTAINER_TAG $CHARTS/cart-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-login -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/login.api --set image.tag=$CONTAINER_TAG $CHARTS/login-api --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-mobilebff -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/mobileapigw --set image.tag=$CONTAINER_TAG $CHARTS/mobilebff --set inf.appinsights.id=$APP_INSIGHTS_KEY
helm install my-tt-webbff -f $CHART_VALUES --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/webapigw --set image.tag=$CONTAINER_TAG $CHARTS/webbff --set inf.appinsights.id=$APP_INSIGHTS_KEY

# Deploy website images to storage
STORAGE_ACCT_NAME=$(az storage account list -g $RESOURCE_GROUP -o table --query [].name -o tsv)
pwsh ./TailwindTraders-Backend/Deploy/powershell/Deploy-Pictures-Azure.ps1 -RESOURCE_GROUP $RESOURCE_GROUP -storageName $STORAGE_ACCT_NAME

# Clone website repository
# Pinning this to a fork until this PR has been merged https://github.com/microsoft/TailwindTraders-Website/pull/153
git clone https://github.com/neilpeterson/TailwindTraders-Website.git
cd TailwindTraders-Website
git checkout api-version-update

# Build image and store in ACR_NAME
az acr build -t web:$CONTAINER_TAG -r $ACR_NAME ./Source/Tailwind.Traders.Web
helm install web -f Deploy/helm/gvalues.yaml -f Deploy/helm/values.b2c.yaml  --set ingress.protocol=http --set ingress.hosts={$INGRESS} --set image.repository=$ACR_NAME.azurecr.io/web --set image.tag=v1 Deploy/helm/web/

# Remove repositories
cd ../
rm -rf TailwindTraders-Website
rm -rf TailwindTraders-Backend
