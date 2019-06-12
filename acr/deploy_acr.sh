#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -euo pipefail

# Get this script's path
DIR="$( cd "$( dirname "$BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Read in config file and assign variables for the non-container case
configFile="${DIR}/config.json"

echo "--> Reading configuration from ${configFile}"

AKS_NODE_COUNT=`jq -r '.azure .node_count' ${configFile}`
AKS_NODE_VM_SIZE=`jq -r '.azure .vm_size' ${configFile}`
AZURE_SUBSCRIPTION=`jq -r '.azure .subscription' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`
CONTACT_EMAIL=`jq -r '.binderhub .contact_email' ${configFile}`
CONTAINER_REGISTRY=`jq -r '.container_registry' ${configFile}`
DOCKER_IMAGE_PREFIX=`jq -r '.docker .image_prefix' ${configFile}`
RESOURCE_GROUP_LOCATION=`jq -r '.azure .location' ${configFile}`
RESOURCE_GROUP_NAME=`jq -r '.azure .res_grp_name' ${configFile}`
SP_APP_ID=`jq -r '.azure .sp_app_id' ${configFile}`
SP_APP_KEY=`jq -r '.azure .sp_app_key' ${configFile}`
SP_TENANT_ID=`jq -r '.azure .sp_tenant_id' ${configFile}`

# Check that the variables are all set non-zero, non-null
REQUIREDVARS=" \
        AKS_NODE_COUNT \
        AKS_NODE_VM_SIZE \
        AZURE_SUBSCRIPTION \
        BINDERHUB_NAME \
        BINDERHUB_VERSION \
        CONTACT_EMAIL \
        CONTAINER_REGISTRY \
        DOCKER_IMAGE_PREFIX \
        RESOURCE_GROUP_NAME \
        RESOURCE_GROUP_LOCATION \
        "

for required_var in $REQUIREDVARS ; do
  if [ -z "${!required_var}" ] || [ x${required_var} == 'xnull' ] ; then
    echo "--> ${required_var} must be set for deployment" >&2
    exit 1
  fi
done

# Test value of CONTAINER_REGISTRY. Must be either "dockerhub" or "acr"
if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ] ; then
  echo "--> Getting DockerHub requirements"

  # Check if any optional variables are set null; if so, reset them to a
  # zero-length string for later checks. If they failed to read at all,
  # possibly due to an invalid json file, they will be returned as a
  # zero-length string -- this is attempting to make the 'not set'
  # value the same in either case
  if [ x${SP_APP_ID} == 'xnull' ] ; then SP_APP_ID='' ; fi
  if [ x${SP_APP_KEY} == 'xnull' ] ; then SP_APP_KEY='' ; fi
  if [ x${SP_TENANT_ID} == 'xnull' ] ; then SP_TENANT_ID='' ; fi

  # Read Docker credentials from config file
  DOCKER_ORGANISATION=`jq -r '.docker .org' ${configFile}`
  DOCKER_PASSWORD=`jq -r '.docker .password' ${configFile}`
  DOCKER_USERNAME=`jq -r '.docker .username' ${configFile}`

  # Check that Docker credentials have been set
  if [ x${DOCKER_ORGANISATION} == 'xnull' ] ; then DOCKER_ORGANISATION='' ; fi
  if [ x${DOCKER_PASSWORD} == 'xnull' ] ; then DOCKER_PASSWORD='' ; fi
  if [ x${DOCKER_USERNAME} == 'xnull' ] ; then DOCKER_USERNAME='' ; fi

  # Check/get the user's Docker credentials
  if [ -z $DOCKER_USERNAME ] ; then
    if [ ! -z "$DOCKER_ORGANISATION" ] ; then
      echo "--> Your Docker IS must be a member of the ${DOCKER_ORGANISATION} organisation"
    fi
    read -p "DockerHub ID: " DOCKER_USERNAME
    read -sp "DockerHub password: " DOCKER_PASSWORD
    echo
  else
    if [ -z $DOCKER_PASSWORD ] ; then
      read -sp "DockerHub password for ${DOCKER_USERNAME}: " DOCKER_PASSWORD
      echo
    fi
  fi

  # Normalise resource group location to remove spaces and have lowercase
  RESOURCE_GROUP_LOCATION=`echo ${RESOURCE_GROUP_LOCATION//[[:blank::]]/} | tr '[:upper:]' '[:lower:]'`

  echo "--> Configuration read in:
    AKS_NODE_COUNT: ${AKS_NODE_COUNT}
    AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
    AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
    BINDERHUB_NAME: ${BINDERHUB_NAME}
    BINDERHUB_VERSION: ${BINDERHUB_VERSION}
    CONTACT_EMAIL: ${CONTACT_EMAIL}
    CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
    DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
    DOCKER_ORGANISATION: ${DOCKER_ORGANISATION}
    DOCKER_PASSWORD: ${DOCKER_PASSWORD}
    DOCKER_USERNAME: ${DOCKER_USERNAME}
    RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
    RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
    SP_APP_ID: ${SP_APP_ID}
    SP_APP_KEY: ${SP_APP_KEY}
    SP_TENANT_ID: ${SP_TENANT_ID}
    "

elif [ x${CONTAINER_REGISTRY} == 'xacr' ] ; then
  echo "--> Getting configuration for Azure Container Registry"

  # Read in ACR configuration
  REGISTRY_NAME=`jq -r '.acr .registry_name' ${configFile}`
  REGISTRY_SKU=`jq -r '.acr .sku' ${configFile}`

  # Checking required variables
  REQUIREDVARS=" \
      REGISTRY_NAME \
      REGISTRY_SKU \
      SP_APP_ID \
      SP_APP_KEY \
      SP_TENANT_ID \
      "

  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] || [ x${required_var} == 'xnull' ] ; then
      echo "--> ${required_var} must be set for deployment" >&2
      exit 1
    fi
  done

  echo "--> Configuration read in:
    AKS_NODE_COUNT: ${AKS_NODE_COUNT}
    AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
    AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
    BINDERHUB_NAME: ${BINDERHUB_NAME}
    BINDERHUB_VERSION: ${BINDERHUB_VERSION}
    CONTACT_EMAIL: ${CONTACT_EMAIL}
    CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
    DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
    REGISTRY_NAME: ${REGISTRY_NAME}
    REGISTRY_SKU: ${REGISTRY_SKU}
    RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
    RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
    SP_APP_ID: ${SP_APP_ID}
    SP_APP_KEY: ${SP_APP_KEY}
    SP_TENANT_ID: ${SP_TENANT_ID}
    "

else
  echo "--> Please provide a valid option for CONTAINER_REGISTRY.
    Options are: 'dockerhub' or 'acr'."
fi

# Generate a valid names for Azure. ACR name must be alphanumeric only.
AKS_NAME=`echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-' | cut -c 1-59`-AKS
REGISTRY_NAME=`echo ${REGISTRY_NAME} | tr -cd '[:alnum:]' | cut -c -50`

# Azure login will be different depending on whether this script is running
# with or without service principal details supplied.
#
# If all the SP environments are set, use those. Otherwise, fall back to an
# interactive login.

if [ -z $SP_APP_ID ] || [ -z $SP_APP_KEY ] || [ -z $SP_TENANT_ID ] ; then
  echo "--> Attempting to log in to Azure as a user"
  if ! az login -o none; then
      echo "--> Unable to connect to Azure" >&2
      exit 1
  else
      echo "--> Logged in to Azure"
  fi
else
  echo "--> Attempting to log in to Azure with provided Service Principal"
  if ! az login -o none --service-principal -u "${SP_APP_ID}" -p "${SP_APP_KEY}" -t "${SP_TENANT_ID}"; then
    echo "--> Unable to connect to Azure" >&2
    exit 1
  else
      echo "--> Logged in to Azure"
      # Use this service principal for AKS creation
      AKS_SP="--service-principal ${SP_APP_ID} --client-secret ${SP_APP_KEY}"
  fi
fi

# Activate chosen subscription
echo "--> Activating Azure subscription: ${AZURE_SUBSCRIPTION}"
az account set -s "$AZURE_SUBSCRIPTION"

# Create a new resource group if necessary
echo "--> Checking if resource group exists: ${RESOURCE_GROUP_NAME}"
if [[ $(az group exists --name $RESOURCE_GROUP_NAME) == false ]] ; then
  echo "--> Creating new resource group: ${RESOURCE_GROUP_NAME}"
  az group create -n $RESOURCE_GROUP_NAME --location $RESOURCE_GROUP_LOCATION -o table | tee rg-create.log
else
  echo "--> Resource group ${RESOURCE_GROUP_NAME} found"
fi

# If Azure container registry is required, create an ACR and give Service Principal AcrPush role.
if [ x${CONTAINER_REGISTRY} == 'xacr' ] ; then
  echo "--> Checking ACR name availability"
  REGISTRY_NAME_AVAIL=`az acr check-name -n ${REGISTRY_NAME} --query nameAvailable -o tsv`
  while [ ${REGISTRY_NAME_AVAIL} == false ]
  do
    echo "--> Name ${REGISTRY_NAME} not available. Appending 4 random characters."
    REGISTRY_NAME="$(echo ${REGISTRY_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -50)$(openssl rand -hex 2)"
    echo "--> New name: ${REGISTRY_NAME}"
    REGISTRY_NAME_AVAIL=`az acr check-name -n ${REGISTRY_NAME} --query nameAvailable -o tsv`
  done

  echo "--> Creating ACR"
  az acr create -n $REGISTRY_NAME -g $RESOURCE_GROUP_NAME --sku $REGISTRY_SKU --admin-enabled true -o table

  echo "--> Logging in to ${REGISTRY_NAME}"
  az acr login -n $REGISTRY_NAME

  # Populating some variables
  ACR_LOGIN_SERVER=`az acr list -g ${RESOURCE_GROUP_NAME} --query '[].{acrLoginServer:loginServer}' -o tsv`
  ACR_ID=`az acr show -n ${REGISTRY_NAME} -g ${RESOURCE_GROUP_NAME} --query 'id' -o tsv`

  # Assigning AcrPush role to Service Principal using AcrPush's specific object-ID
  echo "--> Assigning AcrPush role to Service Principal"
  az role assignment create --assignee ${SP_APP_ID} --role 8311e382-0749-4cb8-b61a-304f252e45ec --scope $ACR_ID
fi