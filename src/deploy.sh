#!/bin/bash
# shellcheck disable=SC2086

# Exit immediately if a pipeline returns a non-zero status
set -eo pipefail

# Get this script's path
DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

## Detection of the deploy mode
#
# This script should handle both interactive deployment when run by a user
# on their local system, and also running as a container entrypoint when
# used either for a container-based local deployment or when deployed via an
# Azure blue button setup.
#
# Check whether BINDERHUB_CONTAINER_MODE is set, and if so assume running
# as a container-based install, checking that all required input is present
# in the form of environment variables

if [[ -n $BINDERHUB_CONTAINER_MODE ]]; then
	echo "--> Deployment operating in container mode"
	echo "--> Checking required environment variables"
	# Set out a list of required variables for this script
	REQUIREDVARS=" \
          AKS_NODE_COUNT \
          AKS_NODE_VM_SIZE \
          AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
          CONTAINER_REGISTRY \
          DOCKER_IMAGE_PREFIX \
          ENABLE_HTTPS \
          RESOURCE_GROUP_LOCATION \
          RESOURCE_GROUP_NAME \
          SP_APP_ID \
          SP_APP_KEY \
          SP_TENANT_ID \
          "
	for required_var in $REQUIREDVARS; do
		if [ -z "${!required_var}" ]; then
			echo "--> ${required_var} must be set for container-based setup" >&2
			exit 1
		fi
	done

	# Logs will automatically be saved for containerized
	# deployments.  This will ensure that an environment
	# variable exists as if it was run from the command-line
	# which in turn allows the check at the end to
	# complete successfully.
	LOG_TO_BLOB_STORAGE='true'

	if [ "$CONTAINER_REGISTRY" == 'dockerhub' ]; then

		REQUIREDVARS=" \
            DOCKERHUB_USERNAME \
            DOCKERHUB_PASSWORD \
            "

		for required_var in $REQUIREDVARS; do
			if [ -z "${!required_var}" ]; then
				echo "--> ${required_var} must be set for container-based setup" >&2
				exit 1
			fi
		done

		echo "--> Configuration parsed from blue button:
			AKS_NODE_COUNT: ${AKS_NODE_COUNT}
			AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
			AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
			BINDERHUB_NAME: ${BINDERHUB_NAME}
			BINDERHUB_VERSION: ${BINDERHUB_VERSION}
			CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
			DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
			DOCKERHUB_ORGANISATION: ${DOCKERHUB_ORGANISATION}
			DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}
			LOG_TO_BLOB_STORAGE: ${LOG_TO_BLOB_STORAGE}
			RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
			RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
			SP_APP_ID: ${SP_APP_ID}
			SP_APP_KEY: ${SP_APP_KEY}
			SP_TENANT_ID: ${SP_TENANT_ID}
			" | tee read-config.log

		# Check if DOCKERHUB_ORGANISATION is set to null. Return empty string if true.
		if [ x${DOCKERHUB_ORGANISATION} == 'xnull' ]; then DOCKERHUB_ORGANISATION=''; fi

	elif [ "$CONTAINER_REGISTRY" == 'azurecr' ]; then

		REQUIREDVARS=" \
            REGISTRY_NAME \
            REGISTRY_SKU \
            "

		for required_var in $REQUIREDVARS; do
			if [ -z "${!required_var}" ]; then
				echo "--> ${required_var} must be set for container-based setup" >&2
				exit 1
			fi
		done

		echo "--> Configuration parsed from blue button:
			AKS_NODE_COUNT: ${AKS_NODE_COUNT}
			AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
			AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
			BINDERHUB_NAME: ${BINDERHUB_NAME}
			BINDERHUB_VERSION: ${BINDERHUB_VERSION}
			CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
			DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
			LOG_TO_BLOB_STORAGE: ${LOG_TO_BLOB_STORAGE}
			REGISTRY_NAME: ${REGISTRY_NAME}
			REGISTRY_SKU: ${REGISTRY_SKU}
			RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
			RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
			SP_APP_ID: ${SP_APP_ID}
			SP_APP_KEY: ${SP_APP_KEY}
			SP_TENANT_ID: ${SP_TENANT_ID}
			" | tee read-config.log

	else
		echo "--> Please provide a valid option for CONTAINER_REGISTRY."
		echo "    Options are 'dockerhub' or 'azurecr'."
		exit 1
	fi

	if [[ -n $ENABLE_HTTPS ]]; then

		REQUIREDVARS="\
			CERTMANAGER_VERSION \
			CONTACT_EMAIL \
			DOMAIN_NAME \
			NGINX_VERSION \
			"

		for required_var in $REQUIREDVARS; do
			if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ]; then
				echo "--> ${required_var} must be set for container-based setup" >&2
				exit 1
			fi
		done

		# Configure URL for Custom Resource Definitions
		STRIPPED_VERSION=$(echo "${CERTMANAGER_VERSION}" | tr -d 'v')
		SHORT_VERSION=${STRIPPED_VERSION%.*}
		CERTMANAGER_CRDS="https://raw.githubusercontent.com/jetstack/cert-manager/release-${SHORT_VERSION}/deploy/manifests/00-crds.yaml"

	else
		if [ x${CONTACT_EMAIL} == 'xnull' ]; then CONTACT_EMAIL=''; fi
		if [ x${DOMAIN_NAME} == 'xnull' ]; then DOMAIN_NAME=''; fi
		if [ x${CERTMANAGER_VERSION} == 'xnull' ]; then CERTMANAGER_VERSION=''; fi
		if [ x${NGINX_VERSION} == 'xnull' ]; then NGINX_VERSION=''; fi
	fi

	# Azure blue-button prepends '/subscription/' to AZURE_SUBSCRIPTION
	AZURE_SUBSCRIPTION=$(echo $AZURE_SUBSCRIPTION | sed -r "s/^\/subscriptions\///")

	echo "--> Configuration parsed from blue button:
      AKS_NODE_COUNT: ${AKS_NODE_COUNT}
      AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
      AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
      BINDERHUB_NAME: ${BINDERHUB_NAME}
      BINDERHUB_VERSION: ${BINDERHUB_VERSION}
      CERTMANAGER_VERSION: ${CERTMANAGER_VERSION}
      CONTACT_EMAIL: ${CONTACT_EMAIL}
      CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
      DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
      DOCKERHUB_ORGANISATION: ${DOCKERHUB_ORGANISATION}
      DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}
      DOMAIN_NAME: ${DOMAIN_NAME}
      ENABLE_HTTPS: ${ENABLE_HTTPS}
      NGINX_VERSION: ${NGINX_VERSION}
      REGISTRY_NAME: ${REGISTRY_NAME}
      REGISTRY_SKU: ${REGISTRY_SKU}
      RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
      RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
      SP_APP_ID: ${SP_APP_ID}
      SP_TENANT_ID: ${SP_TENANT_ID}
      " | tee read-config.log

else

	# Read in config file and assign variables for the non-container case
	configFile="${DIR}/config.json"

	echo "--> Reading configuration from ${configFile}"

	AKS_NODE_COUNT=$(jq -r '.azure .node_count' ${configFile})
	AKS_NODE_VM_SIZE=$(jq -r '.azure .vm_size' ${configFile})
	AZURE_SUBSCRIPTION=$(jq -r '.azure .subscription' ${configFile})
	BINDERHUB_NAME=$(jq -r '.binderhub .name' ${configFile})
	BINDERHUB_VERSION=$(jq -r '.binderhub .version' ${configFile})
	CONTAINER_REGISTRY=$(jq -r '.container_registry' ${configFile})
	DOCKER_IMAGE_PREFIX=$(jq -r '.binderhub .image_prefix' ${configFile})
	ENABLE_HTTPS=$(jq -r '.enable_https' ${configFile})
	LOG_TO_BLOB_STORAGE=$(jq -r '.azure .log_to_blob_storage' ${configFile})
	RESOURCE_GROUP_LOCATION=$(jq -r '.azure .location' ${configFile})
	RESOURCE_GROUP_NAME=$(jq -r '.azure .res_grp_name' ${configFile})
	SP_APP_ID=$(jq -r '.azure .sp_app_id' ${configFile})
	SP_APP_KEY=$(jq -r '.azure .sp_app_key' ${configFile})
	SP_TENANT_ID=$(jq -r '.azure .sp_tenant_id' ${configFile})

	# Check that the variables are all set non-zero, non-null
	REQUIREDVARS=" \
		AKS_NODE_COUNT \
		AKS_NODE_VM_SIZE \
		AZURE_SUBSCRIPTION \
		BINDERHUB_NAME \
		BINDERHUB_VERSION \
		CONTAINER_REGISTRY \
		DOCKER_IMAGE_PREFIX \
		ENABLE_HTTPS \
		RESOURCE_GROUP_LOCATION \
		RESOURCE_GROUP_NAME \
		SP_APP_ID \
		SP_APP_KEY \
		SP_TENANT_ID \
		"

	for required_var in $REQUIREDVARS; do
		if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ]; then
			echo "--> ${required_var} must be set for deployment" >&2
			exit 1
		fi
	done

	# Check if any optional variables are set null; if so, reset them to a
	# zero-length string for later checks. If they failed to read at all,
	# possibly due to an invalid json file, they will be returned as a
	# zero-length string -- this is attempting to make the 'not set'
	# value the same in either case
	if [ x${LOG_TO_BLOB_STORAGE} == 'xnull' ]; then LOG_TO_BLOB_STORAGE=''; fi

	# Test value of CONTAINER_REGISTRY. Must be either "dockerhub" or "azurecr"
	if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ]; then
		echo "--> Getting DockerHub requirements"

		# Read Docker credentials from config file
		DOCKERHUB_ORGANISATION=$(jq -r '.docker .org' ${configFile})
		DOCKERHUB_PASSWORD=$(jq -r '.docker .password' ${configFile})
		DOCKERHUB_USERNAME=$(jq -r '.docker .username' ${configFile})

		# Check that Docker Hub credentials have been set
		if [ x${DOCKERHUB_ORGANISATION} == 'xnull' ]; then DOCKERHUB_ORGANISATION=''; fi
		if [ x${DOCKERHUB_PASSWORD} == 'xnull' ]; then DOCKERHUB_PASSWORD=''; fi
		if [ x${DOCKERHUB_USERNAME} == 'xnull' ]; then DOCKERHUB_USERNAME=''; fi

		# Check/get the user's Docker Hub credentials
		if [ -z $DOCKERHUB_USERNAME ]; then
			if [ -n "$DOCKERHUB_ORGANISATION" ]; then
				echo "--> Your Docker ID must be a member of the ${DOCKERHUB_ORGANISATION} organisation"
			fi
			read -rp "DockerHub ID: " DOCKERHUB_USERNAME
			read -rsp "DockerHub password: " DOCKERHUB_PASSWORD
			echo
		else
			if [ -z $DOCKERHUB_PASSWORD ]; then
				read -rsp "Docker Hub password for ${DOCKERHUB_USERNAME}: " DOCKERHUB_PASSWORD
				echo
			fi
		fi

	elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then
		echo "--> Getting configuration for Azure Container Registry"

		# Read in ACR configuration
		REGISTRY_NAME=$(jq -r '.acr .registry_name' ${configFile})
		REGISTRY_SKU=$(jq -r '.acr .sku' ${configFile})

		# Checking required variables
		REQUIREDVARS=" \
			REGISTRY_NAME \
			REGISTRY_SKU \
			"

		for required_var in $REQUIREDVARS; do
			if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ]; then
				echo "--> ${required_var} must be set for deployment" >&2
				exit 1
			fi
		done

		# ACR name must be alphanumeric only and 50 characters or less
		REGISTRY_NAME=$(echo ${REGISTRY_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -50)

		echo "--> Configuration read in:
			AKS_NODE_COUNT: ${AKS_NODE_COUNT}
			AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
			AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
			BINDERHUB_NAME: ${BINDERHUB_NAME}
			BINDERHUB_VERSION: ${BINDERHUB_VERSION}
			CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
			DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
			LOG_TO_BLOB_STORAGE: ${LOG_TO_BLOB_STORAGE}
			REGISTRY_NAME: ${REGISTRY_NAME}
			REGISTRY_SKU: ${REGISTRY_SKU}
			RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
			RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
			SP_APP_ID: ${SP_APP_ID}
			SP_APP_KEY: ${SP_APP_KEY}
			SP_TENANT_ID: ${SP_TENANT_ID}
			" | tee read-config.log

	else
		echo "--> Please provide a valid option for CONTAINER_REGISTRY."
		echo "    Options are: 'dockerhub' or 'azurecr'."
	fi

	if [[ -n $ENABLE_HTTPS ]]; then

		# Read in cert-manager config
		CERTMANAGER_VERSION=$(jq -r '.https .certmanager_version' ${configFile})
		CONTACT_EMAIL=$(jq -r '.https .contact_email' ${configFile})
		DOMAIN_NAME=$(jq -r '.https .domain_name' ${configFile})
		NGINX_VERSION=$(jq -r '.https .nginx_version' ${configFile})

		# Checking required variables
		REQUIREDVARS="\
			CERTMANAGER_VERSION \
			CONTACT_EMAIL \
			DOMAIN_NAME \
			NGINX_VERSION \
			"

		for required_var in $REQUIREDVARS; do
			if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ]; then
				echo "--> ${required_var} must be set for deployment" >&2
				exit 1
			fi
		done

		# Configure URL for Custom Resource Definitions
		STRIPPED_VERSION=$(echo "${CERTMANAGER_VERSION}" | tr -d 'v')
		SHORT_VERSION=${STRIPPED_VERSION%.*}
		CERTMANAGER_CRDS="https://raw.githubusercontent.com/jetstack/cert-manager/release-${SHORT_VERSION}/deploy/manifests/00-crds.yaml"

	else
		if [ x${CONTACT_EMAIL} == 'xnull' ]; then CONTACT_EMAIL=''; fi
		if [ x${DOMAIN_NAME} == 'xnull' ]; then DOMAIN_NAME=''; fi
		if [ x${CERTMANAGER_VERSION} == 'xnull' ]; then CERTMANAGER_VERSION=''; fi
		if [ x${NGINX_VERSION} == 'xnull' ]; then NGINX_VERSION=''; fi
	fi

	echo "--> Configuration read in:
      AKS_NODE_COUNT: ${AKS_NODE_COUNT}
      AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
      AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
      BINDERHUB_NAME: ${BINDERHUB_NAME}
      BINDERHUB_VERSION: ${BINDERHUB_VERSION}
      CERTMANAGER_VERSION: ${CERTMANAGER_VERSION}
      CONTACT_EMAIL: ${CONTACT_EMAIL}
      CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
      DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
      DOCKERHUB_ORGANISATION: ${DOCKERHUB_ORGANISATION}
      DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}
      DOMAIN_NAME: ${DOMAIN_NAME}
      ENABLE_HTTPS: ${ENABLE_HTTPS}
      NGINX_VERSION: ${NGINX_VERSION}
      REGISTRY_NAME: ${REGISTRY_NAME}
      REGISTRY_SKU: ${REGISTRY_SKU}
      RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
      RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
      SP_APP_ID: ${SP_APP_ID}
      SP_TENANT_ID: ${SP_TENANT_ID}
      " | tee read-config.log

fi

set -eo pipefail

# Normalise resource group location to remove spaces and have lowercase
RESOURCE_GROUP_LOCATION=$(echo ${RESOURCE_GROUP_LOCATION//[[:blank::]]/} | tr '[:upper:]' '[:lower:]')

# Generate a valid name for the AKS cluster
AKS_NAME=$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-' | cut -c 1-59)-AKS

# Format BinderHub name for Kubernetes
HELM_BINDERHUB_NAME=$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//')

# Define extra terraform vars based on options
if [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then
  ACR_TFVARS=(-var="enable_acr=true" -var="registry_name=${REGISTRY_NAME}" -var="registry_sku=${REGISTRY_SKU}")
else
  ACR_TFVARS=""
fi


# Deploy infrastructure using terraform
cd "${DIR}/terraform"
terraform init
terraform apply \
  -var="az_sub=${AZURE_SUBSCRIPTION}" \
  -var="az_sp_id=${SP_APP_ID}" \
  -var="az_sp_password=${SP_APP_KEY}" \
  -var="az_tenant_id=${SP_TENANT_ID}" \
  -var="resource_group=${RESOURCE_GROUP_NAME}" \
  -var="location=${RESOURCE_GROUP_LOCATION}" \
  -var="aks_name=${AKS_NAME}" \
  -var="binderhub_name=${HELM_BINDERHUB_NAME}" \
  -auto-approve \
  ${ACR_TFVARS}
cd "${DIR}"

# Output ACR variables from Terraform
if [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then

	# Populating some variables
	ACR_LOGIN_SERVER=$(terraform output acr_login_server)
	ACR_ID=$(terraform output acr_id)

	# Reassign IMAGE_PREFIX to conform with BinderHub's expectation:
	# <container-registry>/<project-id>/<prefix>-name:tag
	IMAGE_PREFIX=${BINDERHUB_NAME}/${IMAGE_PREFIX}
fi

# # If HTTPS is required, set up a DNS zone and empty A records
# if [[ -n $ENABLE_HTTPS ]]; then
# 	# Create a DNS zone
# 	az network dns zone create -g $RESOURCE_GROUP_NAME -n $DOMAIN_NAME -o table | tee create-dns-zone.log

# 	# Echo name name servers
# 	NAME_SERVERS=$(az network dns zone show -g $RESOURCE_GROUP_NAME -n $DOMAIN_NAME --query nameServers -o tsv)
# 	printf "Please update your parent domain with the following name servers:\n%s" "${NAME_SERVERS}" | tee name-servers.log

# 	# Create empty A records for the binder and hub pods
# 	az network dns record-set a create -g $RESOURCE_GROUP_NAME -z $DOMAIN_NAME --ttl 300 -n binder -o table | tee create-binder-a-record.log
# 	az network dns record-set a create -g $RESOURCE_GROUP_NAME -z $DOMAIN_NAME --ttl 300 -n hub -o table | tee create-hub-a-record.log

# 	# Set some extra variables
# 	BINDER_HOST="binder.${DOMAIN_NAME}"
# 	HUB_HOST="hub.${DOMAIN_NAME}"
# 	BINDER_SECRET="${HELM_BINDERHUB_NAME}-binder-secret"
# 	HUB_SECRET="${HELM_BINDERHUB_NAME}-hub-secret"
# fi

# Get kubectl credentials from Azure
echo "--> Fetching kubectl credentials from Azure"
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME --overwrite-existing | tee get-credentials.log

# Check nodes are ready
nodecount="$(kubectl get node | awk '{print $2}' | grep -c Ready)"
while [[ ${nodecount} -ne ${AKS_NODE_COUNT} ]]; do
	echo -n "$(date)"
	echo " : ${nodecount} of ${AKS_NODE_COUNT} nodes ready"
	sleep 15
	nodecount="$(kubectl get node | awk '{print $2}' | grep -c Ready)"
done
echo
echo "--> Cluster node status:"
kubectl get node | tee kubectl-status.log
echo

# Setup ServiceAccount for tiller
echo "--> Setting up tiller service account"
kubectl --namespace kube-system create serviceaccount tiller | tee tiller-service-account.log

# Give the ServiceAccount full permissions to manage the cluster
echo "--> Giving the ServiceAccount full permissions to manage the cluster"
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller | tee cluster-role-bindings.log

# Check helm installation
helm=$(command -v helm3 || command -v helm)
HELM_VERSION=$($helm version -c --short | cut -f1 -d".")

if [ "${HELM_VERSION}" == "v3" ]; then
	echo "--> You are running helm v3!"
elif [ "${HELM_VERSION}" == "v2" ]; then
	echo "--> You have helm v2 installed, but we really recommend using helm v3."
	echo "    Please install helm v3 and rerun this script."
	exit 1
else
	echo "--> Helm not found. Please run setup.sh then rerun this script."
	exit 1
fi

# Create tokens for the secrets file:
apiToken=$(openssl rand -hex 32)
secretToken=$(openssl rand -hex 32)

# Get the latest helm chart for BinderHub:
$helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
$helm repo update

# If HTTPS is enabled, get nginx-ingress and cert-manager helm charts and
# install them into the hub namespace
if [[ -n $ENABLE_HTTPS ]]; then
	echo "--> Add nginx-ingress and cert-manager helm repos"
	$helm repo add stable https://kubernetes-charts.storage.googleapis.com
	$helm repo add jetstack https://charts.jetstack.io
	$helm repo update
	kubectl apply --validate=false -f ${CERTMANAGER_CRDS}

	echo "--> Install nginx-ingress helm chart"
	$helm install nginx-ingress stable/nginx-ingress \
		--namespace ${HELM_BINDERHUB_NAME} \
		--version ${NGINX_VERSION} \
		--create-namespace \
		--timeout 10m0s \
		--wait | tee nginx-chart-install.log

	echo "--> Install cert-manager helm chart"
	$helm install cert-manager jetstack/cert-manager \
		--namespace ${HELM_BINDERHUB_NAME} \
		--version ${CERTMANAGER_VERSION} \
		--create-namespace \
		--timeout 10m0s \
		--wait | tee cert-manager-chart-install.log

	LOAD_BALANCER_IP=$(kubectl get svc nginx-ingress-controller -n ${HELM_BINDERHUB_NAME} | awk '{ print $4}' | tail -n 1)

	echo "--> cert-manager pods status:"
	kubectl get pods --namespace $HELM_BINDERHUB_NAME | tee cert-manager-get-pods.log

	# Create a ClusterIssuer to test deployment
	echo "--> Testing cert-manager webhooks"
	kubectl apply -f ${DIR}/templates/test-resources.yaml
	sleep 30
	kubectl describe certificate -n cert-manager-test | tee cert-manager-test.log

	# Clean up resources
	kubectl delete -f ${DIR}/templates/test-resources.yaml

	# Parse info to cluster issuer
	echo "--> Writing ClusterIssuer config"
	sed -e "s/<namespace>/${HELM_BINDERHUB_NAME}/g" \
		-e "s/<contact_email>/${CONTACT_EMAIL}/g" \
		${DIR}/templates/cluster-issuer-template.yaml >${DIR}/cluster-issuer.yaml

	# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub.
	if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ]; then

		echo "--> Generating initial configuration file"
		if [ -z "${DOCKERHUB_ORGANISATION}" ]; then
			sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
				-e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
				-e "s/<jupyterhub-ip>/${HUB_HOST}/" \
				-e "s/<cluster-issuer>/letsencrypt-staging/g" \
				-e "s/<binder-host>/${BINDER_HOST}/g" \
				-e "s/<binder-secret-name>/${BINDER_SECRET}/" \
				-e "s/<hub-host>/${HUB_HOST}/g" \
				-e "s/<hub-secret-name>/${HUB_SECRET}/" \
				-e "s/<load-balancer-ip>/${LOAD_BALANCER_IP}/" \
				${DIR}/templates/https-config-template.yaml >${DIR}/config.yaml
		else
			sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
				-e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
				-e "s/<jupyterhub-ip>/${HUB_HOST}/" \
				-e "s/<cluster-issuer>/letsencrypt-staging/g" \
				-e "s/<binder-host>/${BINDER_HOST}/g" \
				-e "s/<binder-secret-name>/${BINDER_SECRET}/" \
				-e "s/<hub-host>/${HUB_HOST}/g" \
				-e "s/<hub-secret-name>/${HUB_SECRET}/" \
				-e "s/<load-balancer-ip>/${LOAD_BALANCER_IP}/" \
				${DIR}/templates/https-config-template.yaml >${DIR}/config.yaml
		fi

		echo "--> Generating initial secrets file"
		sed -e "s/<apiToken>/${apiToken}/" \
			-e "s/<secretToken>/${secretToken}/" \
			-e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
			-e "s/<password>/${DOCKERHUB_PASSWORD}/" \
			${DIR}/templates/secret-template.yaml >${DIR}/secret.yaml

	elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then

		echo "--> Generating initial configuration file"
		sed -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@g" \
			-e "s@<prefix>@${DOCKER_IMAGE_PREFIX}@" \
			-e "s/<jupyterhub-ip>/${HUB_HOST}/" \
			-e "s/<cluster-issuer>/letsencrypt-staging/g" \
			-e "s/<binder-host>/${BINDER_HOST}/g" \
			-e "s/<binder-secret-name>/${BINDER_SECRET}/" \
			-e "s/<hub-host>/${HUB_HOST}/g" \
			-e "s/<hub-secret-name>/${HUB_SECRET}/" \
			-e "s/<load-balancer-ip>/${LOAD_BALANCER_IP}/" \
			${DIR}/templates/https-acr-config-template.yaml >${DIR}/config.yaml

		echo "--> Generating initial secrets file"
		sed -e "s/<apiToken>/${apiToken}/" \
			-e "s/<secretToken>/${secretToken}/" \
			-e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@" \
			-e "s/<username>/${SP_APP_ID}/" \
			-e "s/<password>/${SP_APP_KEY}/" \
			${DIR}/templates/acr-secret-template.yaml >${DIR}/secret.yaml
	fi

else

	# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub.
	if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ]; then

		echo "--> Generating initial configuration file"
		if [ -z "${DOCKERHUB_ORGANISATION}" ]; then
			sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
				-e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
				${DIR}/templates/config-template.yaml >${DIR}/config.yaml
		else
			sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
				-e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
				${DIR}/templates/config-template.yaml >${DIR}/config.yaml
		fi

		echo "--> Generating initial secrets file"
		sed -e "s/<apiToken>/${apiToken}/" \
			-e "s/<secretToken>/${secretToken}/" \
			-e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
			-e "s/<password>/${DOCKERHUB_PASSWORD}/" \
			${DIR}/templates/secret-template.yaml >${DIR}/secret.yaml

	elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then

		echo "--> Generating initial configuration file"
		sed -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@g" \
			-e "s@<prefix>@${DOCKER_IMAGE_PREFIX}@" \
			${DIR}/templates/acr-config-template.yaml >${DIR}/config.yaml

		echo "--> Generating initial secrets file"
		sed -e "s/<apiToken>/${apiToken}/" \
			-e "s/<secretToken>/${secretToken}/" \
			-e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@" \
			-e "s/<username>/${SP_APP_ID}/" \
			-e "s/<password>/${SP_APP_KEY}/" \
			${DIR}/templates/acr-secret-template.yaml >${DIR}/secret.yaml
	fi
fi

echo "--> Installing Helm chart"
$helm install $HELM_BINDERHUB_NAME jupyterhub/binderhub \
	--version=$BINDERHUB_VERSION \
	--namespace=$HELM_BINDERHUB_NAME \
	-f ${DIR}/secret.yaml \
	-f ${DIR}/config.yaml \
	--create-namespace \
	--timeout 10m0s \
	--wait | tee binderhub-chart-install.log

if [[ -n $ENABLE_HTTPS ]]; then
	# Be error tolerant for this stage
	set +e

	CLUSTER_RESOURCE_GROUP="MC_${RESOURCE_GROUP_NAME}_${AKS_NAME}_${RESOURCE_GROUP_LOCATION}"
	echo "--> Retrieving resources in ${CLUSTER_RESOURCE_GROUP}"

	IP_ADDRESS_NAME="$(az resource list -g "${CLUSTER_RESOURCE_GROUP}" --query "[?type == 'Microsoft.Network/publicIPAddresses'].name" -o tsv | grep ^kubernetes-)"
	echo "IP Address: ${IP_ADDRESS_NAME}" | tee ip-address-name.log

	ipAddressAttempts=0
	while [ -z "${IP_ADDRESS_NAME}" ]; do
		((ipAddressAttempts++))
		echo "--> IP Address Name pull attempt ${ipAddressAttempts} of 10 failed"
		if ((ipAddressAttempts > 9)); then
			echo "--> Failed to pull the IP Address name. You will have to set the A records manually. You can do this by running set_a_records.sh."
			break
		fi
		echo "--> Waiting 30s before trying again"
		sleep 30
		IP_ADDRESS_NAME="$(az resource list -g "${CLUSTER_RESOURCE_GROUP}" --query "[?type == 'Microsoft.Network/publicIPAddresses'].name" -o tsv | grep ^kubernetes-)"
		echo "IP Address: ${IP_ADDRESS_NAME}" | tee ip-address-name.log
	done

	if [ -n "${IP_ADDRESS_NAME}" ]; then
		IP_ADDRESS_ID="$(az resource show -g "${CLUSTER_RESOURCE_GROUP}" -n "${IP_ADDRESS_NAME}" --resource-type 'Microsoft.Network/publicIPAddresses' --query id -o tsv)"
		echo "IP Address ID: ${IP_ADDRESS_ID}" | tee ip-address-id.log

		az network dns record-set a update -n hub -g "${RESOURCE_GROUP_NAME}" -z "${DOMAIN_NAME}" --target-resource "${IP_ADDRESS_ID}" -o table | tee update-hub-a-record.log
		az network dns record-set a update -n binder -g "${RESOURCE_GROUP_NAME}" -z "${DOMAIN_NAME}" --target-resource "${IP_ADDRESS_ID}" -o table | tee update-binder-a-record.log
	fi

	# Revert to error-intolerance
	set -eo pipefail

else
	# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
	echo "--> Retrieving JupyterHub IP"
	# shellcheck disable=SC2030 disable=SC2036
	JUPYTERHUB_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1) | tee jupyterhub-ip.log
	# shellcheck disable=SC2031
	while [ "${JUPYTERHUB_IP}" == '<pending>' ] || [ -z "${JUPYTERHUB_IP}" ]; do
		echo "Sleeping 30s before checking again"
		sleep 30
		JUPYTERHUB_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1)
		echo "JupyterHub IP: ${JUPYTERHUB_IP}" | tee jupyterhub-ip.log
	done

	if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ]; then

		echo "--> Finalising configurations"
		if [ -z "$DOCKERHUB_ORGANISATION" ]; then
			sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
				-e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
				-e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
				${DIR}/templates/config-template.yaml >${DIR}/config.yaml
		else
			sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
				-e "s/<prefix>/${DOCKERHUB_IMAGE_PREFIX}/" \
				-e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
				${DIR}/templates/config-template.yaml >${DIR}/config.yaml
		fi

	elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ]; then

		echo "--> Finalising configurations"
		sed -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@g" \
			-e "s@<prefix>@${DOCKER_IMAGE_PREFIX}@" \
			-e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
			${DIR}/templates/acr-config-template.yaml >${DIR}/config.yaml

	fi

	echo "--> Updating Helm chart"
	$helm upgrade $HELM_BINDERHUB_NAME jupyterhub/binderhub \
		--namespace $HELM_BINDERHUB_NAME \
		--version=$BINDERHUB_VERSION \
		-f ${DIR}/secret.yaml \
		-f ${DIR}/config.yaml \
		--cleanup-on-fail \
		--timeout 10m0s \
		--wait | tee helm-upgrade.log

	# Print Binder IP address
	echo "--> Retrieving Binder IP"
	BINDER_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1)
	echo "Binder IP: ${BINDER_IP}" | tee binder-ip.log
	while [ "${BINDER_IP}" = '<pending>' ] || [ "${BINDER_IP}" = "" ]; do
		echo "Sleeping 30s before checking again"
		sleep 30
		BINDER_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1)
		echo "Binder IP: ${BINDER_IP}" | tee binder-ip.log
	done
fi

echo "BinderHub deployment completed!"

if [[ -n $BINDERHUB_CONTAINER_MODE ]] || [[ "$LOG_TO_BLOB_STORAGE" == 'true' ]]; then
	# Finally, save outputs to blob storage
	#
	# Create a storage account
	echo "--> Creating storage account"
	CONTAINER_NAME="$(echo ${BINDERHUB_NAME}deploylogs | tr '[:upper:]' '[:lower:]')"
	STORAGE_ACCOUNT_NAME="$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -20)$(openssl rand -hex 2)"
	az storage account create \
		--name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} \
		--sku Standard_LRS -o table | tee storage-create.log
	# Create a container
	echo "--> Creating storage container: ${CONTAINER_NAME}"
	az storage container create --account-name ${STORAGE_ACCOUNT_NAME} \
		--name ${CONTAINER_NAME} -o table | tee container-create.log
	# Push the files
	echo "--> Pushing log files"
	az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
		--destination ${CONTAINER_NAME} --source "." \
		--pattern "*.log" -o table
	echo "--> Pushing yaml files"
	az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
		--destination ${CONTAINER_NAME} --source "." \
		--pattern "*.yaml" -o table
	echo "--> Getting and pushing ssh keys"
	cp ~/.ssh/id_rsa ${DIR}/id_rsa_${BINDERHUB_NAME}
	cp ~/.ssh/id_rsa.pub ${DIR}/id_rsa_${BINDERHUB_NAME}.pub
	az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
		--destination ${CONTAINER_NAME} --source "." \
		--pattern "id*" -o table
fi
