import re
import json
import getpass

ERR_MSG = "Sorry, I did not recognise that input."

# Regular Expressions for comparison
re_yes = re.compile("yes", re.IGNORECASE)
re_no = re.compile("no", re.IGNORECASE)

re_azurecr = re.compile("azurecr")
re_dockerhub = re.compile("dockerhub")

re_basic = re.compile("Basic")
re_standard = re.compile("Standard")
re_premium = re.compile("Premium")

# Command line prompts
PROMPTS = {
    "acr": {
        "registry_name": "What name do you want to give the ACR? (This must be alpha-numerical and unique to Azure): ",
        "sku": "Which pricing tier should the ACR use? (Basic/Standard/Premium): ",
    },
    "azure": {
        "subscription": "Which Azure subscription will you be using? Please provide it's name or ID: ",
        "res_grp_name": "Which Azure Resource Group would you like to deploy into? (If it does not exist, it will be created): ",
        "location": "Which Data Centre region would you like to deploy into? (e.g., west-europe): ",
        "node_count": "How many nodes would you like to deploy? (3 is preferrable for a stable cluster): ",
        "vm_size": "What size VM would you like to deploy onto? (e.g., Standard_D2s_v3): ",
        "log_to_blob_storage": "Would you like to push logs to Azure Blob Storage? (yes/no): ",
    },
    "binderhub": {
        "name": "What name would you like your BinderHub to have?: ",
        "version": "Which version of the BinderHub helm chart should be deployed?: ",
        "image_prefix": "What shall we preppend your Docker images with? (e.g., binder-prod): ",
    },
    "docker": {
        "username": "Docker username: ",
        "password": "Docker password: ",
        "org": "Are you using a Docker Hub organisation? (yes/no): ",
    },
}
SP_PROMPTS = {
    "sp_app_id": "Service Principal ID: ",
    "sp_app_key": "Service Principal key: ",
    "sp_tenant_id": "Tenant ID: ",
}


def construct_config():
    """Command line prompts that help generate a config file for binderhub-deploy"""
    print("The following questions will construct your configuration file.\n\n")

    # Setup config dict
    config = {}
    config["acr"] = {}
    config["azure"] = {}
    config["binderhub"] = {}
    config["docker"] = {}

    # Required Azure config
    for key, prompt in PROMPTS["azure"].items():
        resp = input(prompt)

        if key == "node_count":
            resp = int(resp)

        if key == "log_to_blob_storage":
            yes = re_yes.match(resp)
            no = re_no.match(resp)

            if yes:
                resp = True
            elif no:
                resp = False
            else:
                raise ValueError(ERR_MSG)

        config["azure"][key] = resp

    # Check for Service Principal
    sp_resp = input("Will you be deploying using a Service Principal? (yes/no): ")
    yes = re_yes.match(sp_resp)
    no = re_no.match(sp_resp)

    if yes:
        for key, prompt in SP_PROMPTS.items():
            if key == "sp_app_key":
                resp = getpass.getpass(prompt)
            else:
                resp = input(prompt)
            config["azure"][key] = resp

    elif no:
        for key in SP_PROMPTS.keys():
            config["azure"][key] = None

    else:
        raise ValueError(ERR_MSG)

    # Required BinderHub config
    for key, prompt in PROMPTS["binderhub"].items():
        config["binderhub"][key] = input(prompt)

    # Container registry defaults
    resp = str(
        input(
            "Which container registry would you like to attach? (azurecr/dockerhub): "
        )
    ).lower()
    azurecr = re_azurecr.match(resp)
    dockerhub = re_dockerhub.match(resp)

    if azurecr:
        config["container_registry"] = resp

        for key in ["username", "password", "org"]:
            config["docker"][key] = None

        for key, prompt in PROMPTS["acr"].items():
            acr_resp = input(prompt)

            if key == "sku":
                acr_resp = acr_resp.capitalize()

                basic = re_basic.match(acr_resp)
                standard = re_standard.match(acr_resp)
                premium = re_premium.match(acr_resp)

                if not (basic or standard or premium):
                    raise ValueError(ERR_MSG)

            config["acr"][key] = acr_resp

    elif dockerhub:
        config["container_registry"] = resp

        for key in ["registry_name", "sku"]:
            config["acr"][key] = None

        for key, prompt in PROMPTS["docker"].items():
            if key == "password":
                docker_resp = getpass.getpass(prompt)
            else:
                docker_resp = input(prompt)

            if key == "org":
                yes = re_yes.match(docker_resp)
                no = re_no.match(docker_resp)

                if yes:
                    docker_resp = str(input("What is the organisation name?: "))
                elif no:
                    docker_resp = None
                else:
                    raise ValueError(ERR_MSG)

            config["docker"][key] = docker_resp

    else:
        raise ValueError(ERR_MSG)

    # Mask and print config
    print("\n\n")
    print("Printing masked configuration for verification.")

    mask = config.copy()

    if ("password" in mask["docker"].keys()) and (
        mask["docker"]["password"] is not None
    ):
        mask["docker"]["password"] = "***"

    if ("sp_app_key" in mask["azure"].keys()) and (
        mask["azure"]["sp_app_key"] is not None
    ):
        mask["azure"]["sp_app_key"] = "***"

    print(json.dumps(mask, indent=2, sort_keys=True))

    with open("config.json", "w") as outfile:
        json.dump(config, outfile, indent=2, sort_keys=True)

    print("Configuration file has been written to config.json")


def main():
    construct_config()


if __name__ == "__main__":
    main()
