# binderhub-deploy

A set of scripts to automatically deploy a [BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) onto [Microsoft Azure](https://azure.microsoft.com/en-gb/) and connect a [DockerHub](https://hub.docker.com/) container registry.

**List of scripts:**
* [**info.sh**](#info.sh)
* [**teardown.sh**](#teardown.sh)

## Usage

Create a file called `config.json` which has the following format.
Fill the values with your desired namespaces, etc.
(Note that `#` tokens won't be permitted in the actual JSON file.)

```
{
  "azure": {
    "subscription": "",  # Azure subscription name
    "res_grp_name": "",  # Azure Resource Group name
    "location": "",      # Azure Data Centre location
    "cluster_name": "",  # Kubernetes cluster name
    "node_count": "",    # Number of nodes to deploy
    "vm_size": ""        # Azure virtual machine type to deploy
  },
  "binderhub": {
    "name": "",          # Name of you BinderHub
    "version": ""        # Helm chart version to deploy
  },
  "docker": {
    "org": null,         # The DockerHub organisation id belongs to (if necessary)
    "image_prefix": ""   # The prefix to preprend to Binder images (e.g. "binder-dev")
  }
}
```

---

### info.sh

The script will print the IP addresses of both the JupyterHub and the BinderHub to the terminal.
It reads the BinderHub name from `config.json` using `read_config.py`.

### teardown.sh

This script will purge the Helm release, delete the Kubernetes namespace and then delete the Azure Resource Group containing the computational resources.
The user should check the [Azure Portal](https://portal.azure.com/#home) to verify the resources have been deleted.

