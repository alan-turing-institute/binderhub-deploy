# Automatically deploy a BinderHub to Microsoft Azure

[BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) is a cloud-based, multi-server technology used for hosting repoducible computing environments and interactive Jupyter Notebooks.

This repo contains a set of scripts to automatically deploy a BinderHub onto [Microsoft Azure](https://azure.microsoft.com/en-gb/) and connect a [DockerHub](https://hub.docker.com/) container registry.

This repo is based on the following set of deployment scripts for Google Cloud: [nicain/binder-deploy](https://github.com/nicain/binder-deploy)

You will require a Microsoft Azure account and subscription.
A Free Trial subscription can be obtained [here](https://azure.microsoft.com/en-gb/free/).
You will be asked to provide a credit card for verification purposes.
**You will not be charged.**
Your resources will be frozen once your subscription expires, then deleted if you do not reactivate your account within a given time period.

**List of scripts:**
* [**setup.sh**](#setupsh)
* [**deploy.sh**](#deploysh)
* [**logs.sh**](#logssh)
* [**info.sh**](#infosh)
* [**teardown.sh**](#teardownsh)

## Usage

To use these scripts locally, clone this repo and change into the directory.

```
git clone https://github.com/alan-turing-institute/binderhub-deploy.git
cd binderhub-deploy
```

The Python files `create_config.py` and `create_secret.py` require Python version >= 3.6, but no extra packages are needed.

To make the scripts executable and then run them, do the following:

```
chmod 700 <script-name>.sh
./<script-name>.sh
```

To deploy, you should run `setup.sh` first, then `deploy.sh`.
You can run `logs.sh` and `info.sh` to get the JupyterHub logs and IP addresses respectively.
`teardown.sh` should only be used to remove your BinderHub deployment.

Create a file called `config.json` which has the following format.
Fill the quotation marks with your desired namespaces, etc.
(Note that `#` tokens won't be permitted in the actual JSON file.)

* For a list of available data centre regions, [see here](https://azure.microsoft.com/en-us/global-infrastructure/locations/). This should be a _region_ and **not** a _location_, e.g. "West Europe" or "Central US". These can be equivalently written as `westeurope` and `centralus`, respectively.
* For a list of available Linux Virtual Machines, [see here](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/sizes-general). This should be something like, e.g., `Standard_D2s_v3`.

```
{
  "azure": {
    "subscription": "",  # Azure subscription name
    "res_grp_name": "",  # Azure Resource Group name
    "location": "",      # Azure Data Centre region
    "node_count": 1,     # Number of nodes to deploy. 3 is preferrable for a stable cluster, but may be liable to caps.
    "vm_size": ""        # Azure virtual machine type to deploy
    "sp_app_id": null,   # Azure service principal ID (optional)
    "sp_app_key": null,  # Azure service principal password (optional)
    "sp_tenant_id": null # Azure tenant ID (optional)
  },
  "binderhub": {
    "name": "",          # Name of your BinderHub
    "version": ""        # Helm chart version to deploy, should be 0.2.0-<commit-hash>
    "contact_email": ""  # Email for letsencrypt https certificate. CANNOT be left blank.
  },
  "docker": {
    "username": null,    # Docker username (can be supplied at runtime)
    "password": null,    # Docker password (can be supplied at runtime)
    "org": null,         # A DockerHub organisation to push images to (if desired)
    "image_prefix": ""   # The prefix to preprend to Binder images (e.g. "binder-prod")
  }
}
```

You can copy [`template-config.json`](template-config.json) should you require.

#### Important for Free Trial subscriptions

If you have signed up to an Azure Free Trial subscription, you are not allowed to deploy more than 4 **cores**.
How many cores you deploy depends on your choice of `node_count` and `vm_size`.

For example, a `Standard_D2s_v3` machine has 2 cores.
Therefore, setting `node_count` to 2 will deploy 4 cores and you will have reached your quota for cores on your Free Trial subscription.

---

### setup.sh

This script checks whether the required command line programs are already installed, and if any are missing uses the system package manager or [`curl`](https://curl.haxx.se/docs/) to install command line interfaces (CLIs) for Microsoft Azure (`azure-cli`), Kubernetes (`kubectl`), Helm (`helm`), along with dependencies that are not automatically installed by those packages.

Command line install scripts were found in the following documentation:
* [Azure-CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes-CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl) (macOS version)
* [Helm-CLI](https://helm.sh/docs/using_helm/#from-script)

### deploy.sh

This script reads in values from `config.json`, deploys a Kubernetes cluster, then creates `config.yaml` and `secret.yaml` files via `create_config.py` and `create_secret.py` respectively (using `config-template.yaml` and `secret-template.yaml`).
The script will ask for your Docker ID and password if you haven't supplied them in the config file.
The ID is your Docker username, NOT the email.
If you have provided a Docker organisation in `config.json`, then Docker ID **MUST** be a member of this organisation.
Both a JupyterHub and BinderHub are installed onto the deployed Kubernetes cluster and the `config.yaml` file is updated with the JupyterHub IP address.

### logs.sh

This script will print the JupyterHub logs to the terminal for debugging.
It reads from `config.json` in order to get the BinderHub name.
It then finds the JupyterHub pod and prints the logs.

### info.sh

The script will print the IP addresses of both the JupyterHub and the BinderHub to the terminal.
It reads the BinderHub name from `config.json`.

### teardown.sh

This script will purge the Helm release, delete the Kubernetes namespace and then delete the Azure Resource Group containing the computational resources.
The user should check the [Azure Portal](https://portal.azure.com/#home) to verify the resources have been deleted.

## Azure Deployment

To deploy [Binderhub](https://binderhub.readthedocs.io/) to Azure use the deploy button below.

[![Deploy to Azure](https://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falan-turing-institute%2Fbinderhub-deploy%2Fmaster%2Fazure%2Fpaas%2Farm%2Fazure.deploy.json)

### Monitoring deployment progress

To monitor the progress of a blue-button deployment, go to the [Azure portal](https://portal.azure.com/) and select 'Resource Groups' from the left hand pane. Then in the central pane select the resource group you chose to deploy into. This will give you a right hand pane containing the resources within the group. You may need to 'refresh' until you see a new container instance. When it appears, select it, then in the new pane go to 'Settings->Containers'. You should see your new container listed. Select it, then in the lower right hand pane select 'Logs'. You may need to 'refresh' this to display the logs, possibly multiple times until the container starts up.

### Retrieving deployment output from Azure

When Binderhub is deployed using the blue button or with a local container, output logs, yaml files, and ssh keys are pushed to an Azure storage account to preserve them once the container exits. The storage account is created in the same resource group as the AKS cluster, and files are pushed into a storage blob within the account.

Both the storage blob name and the storage account name are derived from the name you gave to your BinderHub instance, but may be modified and/or have a random seed appended. To find the storage account name, navigate to your resource group by selecting 'Resource Groups' in the leftmost pant of the [Azure Portal](https://portal.azure.com/), then clicking on the resource group containing your BinderHub instance. Along with any pre-existing resources (if you re-used an existing resource group) you should see three new resources: a container instance, a Kubernetes service, and a storage account.

Make a note of the name of the storage account (referred to in the following commands as ACCOUNT_NAME) then select this storage account. In the new pane that opens, select 'Blobs' from the 'Services' section. You should see a single blob listed. Make a note of the name of this blob, which will be 'BLOB_NAME' in the following commands.

The Azure CLI can be used to fetch files from the blob. Files are fetched into a local directory, which must already exist, referred to as 'OUTPUT_DIRECTORY' in the following commands.

To fetch all files:

```
  az storage blob download-batch --account-name <ACCOUNT_NAME> --source <BLOB_NAME> --pattern "*" -d "<OUTPUT_DIRECTORY>"
```

The pattern can be used to fetch particular files, for example all log files:

```
  az storage blob download-batch --account-name <ACCOUNT_NAME> --source <BLOB_NAME> --pattern "*.log" -d "<OUTPUT_DIRECTORY>"
```

To fetch a single file, specify 'REMOTE_FILENAME' for the name of the file in blob storage, and 'LOCAL_FILENAME' for the filename it will be fetched into:

```
  az storage blob download --account-name <ACCOUNT_NAME> --container-name <BLOB_NAME> --name <REMOTE_FILENAME> --file <LOCAL_FILENAME>
```

For full documentation, see the (az storage blob documentation)[https://docs.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest].


### Service Principal Creation

You will be asked to provide a [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals) in the form launched when you click the deploy to Azure button above.

To create a Service Principal, go to the [Azure Portal](https://portal.azure.com/) (and login!) and open the Cloud Shell:

<html><img src="images/open_shell_in_azure.png" alt="Open Shell in Azure"></html>

You may be asked to create storage when you open the shell.
This is expected, click "Create".

Make sure the shell is set to Bash, not PowerShell.

<html><img src="images/bash_shell.png" alt="Bash Shell"></html>

Set the subscription you'd like to deploy your BinderHub on.

```
az account set -s <subscription>
```

This image shows the command being executed for an Azure Pass Sponsorship.

<html><img src="images/set_subscription.png" alt="Set Subscription"></html>

You will need the subscription ID, which you can retrieve by running:

```
az account list --refresh --output table
```

<html><img src="images/az_account_list.png" alt="List subscriptions"></html>

Next, create the Service Principal with the following command. Make sure to give it a sensible name.

```
az ad sp create-for-rbac --name binderhub-sp --role contributor --scopes /subscriptions/<subscription ID from above>
```

<html><img src="images/create-for-rbac.png" alt="Create Service Principal"></html>

The fields `appId`, `password` and `tenant` are the required pieces of information.
These should be copied into the "Service Principal App ID", "Service Principal App Key" and "Service Principal Tenant ID" fields in the form, respectively.

**Keep this information safe as the password cannot be recovered after this step!**

### Optional

:construction: If you want to set the continuous integration / delivery using Azure pipelines you can follow the instructions in [this tutorial](./CI/tutorial.md). 

## Contributors

We would like to acknowledge and thank the following people for their contributions:

* Tim Greaves (@tmbgreaves)
* Gerard Gorman (@ggorman)
* Tania Allard (@trallard)
* Diego Alonso Alvarez (@dalonsoa)
