# scripts/aksBuildDeployRetail.ps1 -SUBSCRIPTION_ID <SUBSCRIPTION-ID> -AKS_RESOURCE_GROUP_NAME <AKS-RESOURCE-GROUP-NAME> -AKS_CLUSTER_NAME <AKS-CLUSTER-NAME> -ACR_NAME <ACR-NAME>

param (
    [Parameter(Mandatory=$true)][string]$SUBSCRIPTION_ID,
    [Parameter(Mandatory=$true)][string]$AKS_RESOURCE_GROUP_NAME,
    [Parameter(Mandatory=$true)][string]$AKS_CLUSTER_NAME,
    [Parameter(Mandatory=$true)][string]$ACR_NAME
)
function Invoke-Command {
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Command,
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )

    & $Command

    if ($LASTEXITCODE -ne 0) {
        Write-Error $ErrorMessage
        exit $LASTEXITCODE
    }
}

# Initialize AKS cluster and ACR

Write-Host "Initializing AKS cluster and ACR..."
Invoke-Command { az account set --subscription $SUBSCRIPTION_ID } "Failed to set subscription."
Invoke-Command { az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME } "Failed to get AKS credentials."
Invoke-Command { az acr login --name $ACR_NAME } "Failed to log in to ACR."

# Build deployment images

Write-Host ""
Write-Host "Building deployment images..."
Invoke-Command { docker build -t confighub:latest -f src/config_hub/Dockerfile src } "Failed to build the confighub image."
Invoke-Command { docker build -t data:latest -f src/data/Dockerfile src } "Failed to build the data image."
Invoke-Command { docker build -t orchestrator-retail:latest -f src/orchestrator_retail/Dockerfile src } "Failed to build the orchestrator-retail image."
Invoke-Command { docker build -t session-manager:latest -f src/session_manager/Dockerfile src } "Failed to build the session-manager image."
Invoke-Command { docker build -t search:latest -f src/skills/search/Dockerfile src } "Failed to build the search image."
Invoke-Command { docker build -t ingestion:latest -f src/skills/ingestion/Dockerfile src } "Failed to build the ingestion image."
Invoke-Command { docker build -t image-describer:latest -f src/skills/image_describer/Dockerfile src } "Failed to build the image-describer image."
Invoke-Command { docker build -t recommender:latest -f src/skills/recommender/Dockerfile src } "Failed to build the recommender image."


# Tag and push images to ACR

Write-Host ""
Write-Host "Tagging and pushing images to ACR..."

Invoke-Command { docker tag confighub:latest "${ACR_NAME}.azurecr.io/confighub:latest" } "Failed to tag the confighub image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/confighub:latest" } "Failed to push the confighub image."

Invoke-Command { docker tag data:latest "${ACR_NAME}.azurecr.io/data:latest" } "Failed to tag the data image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/data:latest" } "Failed to push the data image."

Invoke-Command { docker tag orchestrator-retail:latest "${ACR_NAME}.azurecr.io/orchestrator-retail:latest" } "Failed to tag the orchestrator-retail image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/orchestrator-retail:latest" } "Failed to push the orchestrator-retail image."

Invoke-Command { docker tag session-manager:latest "${ACR_NAME}.azurecr.io/session-manager:latest" } "Failed to tag the session-manager image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/session-manager:latest" } "Failed to push the session-manager image."

Invoke-Command { docker tag search:latest "${ACR_NAME}.azurecr.io/search:latest" } "Failed to tag the search image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/search:latest" } "Failed to push the search image."

Invoke-Command { docker tag ingestion:latest "${ACR_NAME}.azurecr.io/ingestion:latest" } "Failed to tag the ingestion image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/ingestion:latest" } "Failed to push the ingestion image."

Invoke-Command { docker tag image-describer:latest "${ACR_NAME}.azurecr.io/image-describer:latest" } "Failed to tag the image-describer image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/image-describer:latest" } "Failed to push the image-describer image."

Invoke-Command { docker tag recommender:latest "${ACR_NAME}.azurecr.io/recommender:latest" } "Failed to tag the recommender image."
Invoke-Command { docker push "${ACR_NAME}.azurecr.io/recommender:latest" } "Failed to push the recommender image."

# Deploy to AKS and update images

Write-Host ""
Write-Host "Deploying to AKS and updating images..."

Invoke-Command { kubectl apply -f src/config_hub/k8s_manifest.yaml --validate=false } "Failed to deploy confighub."
Invoke-Command { kubectl set image deployment/confighub-deployment confighub-container="${ACR_NAME}.azurecr.io/confighub:latest" } "Failed to update confighub image."

Invoke-Command { kubectl apply -f src/data/k8s_manifest.yaml --validate=false } "Failed to deploy data."
Invoke-Command { kubectl set image deployment/data-deployment data-container="${ACR_NAME}.azurecr.io/data:latest" } "Failed to update data image."

Invoke-Command { kubectl apply -f src/orchestrator_retail/k8s_manifest.yaml --validate=false } "Failed to deploy orchestrator-retail."
Invoke-Command { kubectl set image deployment/orchestrator-retail-deployment orchestrator-retail-container="${ACR_NAME}.azurecr.io/orchestrator-retail:latest" } "Failed to update orchestrator-retail image."

Invoke-Command { kubectl apply -f src/session_manager/k8s_manifest.yaml --validate=false } "Failed to deploy session-manager."
Invoke-Command { kubectl set image deployment/session-manager-deployment session-manager-container="${ACR_NAME}.azurecr.io/session-manager:latest" } "Failed to update session-manager image."

Invoke-Command { kubectl apply -f src/skills/search/k8s_manifest.yaml --validate=false } "Failed to deploy search."
Invoke-Command { kubectl set image deployment/search-deployment search-container="${ACR_NAME}.azurecr.io/search:latest" } "Failed to update search image."

Invoke-Command { kubectl apply -f src/skills/ingestion/k8s_manifest.yaml --validate=false } "Failed to deploy ingestion."
Invoke-Command { kubectl set image deployment/ingestion-deployment ingestion-container="${ACR_NAME}.azurecr.io/ingestion:latest" } "Failed to update ingestion image."

Invoke-Command { kubectl apply -f src/skills/image_describer/k8s_manifest.yaml --validate=false } "Failed to deploy image-describer."
Invoke-Command { kubectl set image deployment/image-describer-deployment image-describer-container="${ACR_NAME}.azurecr.io/image-describer:latest" } "Failed to update image-describer image."

Invoke-Command { kubectl apply -f src/skills/recommender/k8s_manifest.yaml --validate=false } "Failed to deploy recommender."
Invoke-Command { kubectl set image deployment/recommender-deployment recommender-container="${ACR_NAME}.azurecr.io/recommender:latest" } "Failed to update recommender image."

Write-Host "Deployment completed. Please check the AKS cluster for the status of the pods."