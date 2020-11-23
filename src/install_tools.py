# -*- coding: utf-8 -*-

import sys
import platform
import subprocess
from .run_command import run_cmd, run_pipe_cmd

SUDO = "/usr/bin/sudo"


def detect_os():
    return platform.system().lower()


def install_tools():
    os = detect_os()
    print("--> OS: %s" % os)

    # Linux install
    if os == "linux":
        # apt-based installs
        out = run_cmd(["apt", "--version"])

        if out["returncode"] == 0:
            print("--> Checking system packages and installing any missing packages")

            print("--> Updating apt")
            run_cmd([SUDO, "apt", "update"])

            # Install system packages
            APT_PACKAGES = ["curl", "openssl", "jq"]
            for package in APT_PACKAGES:
                print("--> apt installing %s" % package)
                out = run_cmd([SUDO, "apt", "install", "-y", package])

                if out["returncode"] != 0:
                    print(
                        "--> %s install failed; please install manually and re-run this script"
                    )
                    sys.exit(1)
                elif "is already the newest version" in out["output"]:
                    print("--> %s is up-to-date" % package)

            # Install Azure-CLI
            out = run_cmd(["az", "--version"])

            if out["returncode"] != 0:
                print("--> Attempting to install Azure-CLI with deb packages")
                cmds = [
                    ["curl", "-sL", "https://aka.ms/InstallAzureCLIDeb"],
                    [SUDO, "bash"],
                ]
                out = run_pipe_cmd(cmds)

                if out["returncode"] != 0:
                    print(
                        "--> Azure-CLI install failed; please install manually and re-run this script"
                    )
                    sys.exit(1)

            else:
                print("--> Azure-CLI already installed")

            # Install kubectl
            out = run_cmd(["kubectl", "version", "--client", "--short"])

            if out["returncode"] != 0:
                print("--> Attempting to install kubectl with deb packages")
                out = run_cmd(
                    [SUDO, "apt-get", "install", "-y", "apt-transport-https", "gnupg2"]
                )

                cmds = [
                    [
                        "curl",
                        "-s",
                        "https://packages.cloud.google.com/apt/doc/apt-key.gpg",
                    ],
                    [SUDO, "apt-key", "add", "-"],
                ]
                out = run_pipe_cmd(cmds)

                cmds = [
                    ["echo", "deb https://apt.kubernetes.io/ kubernetes-xenial main"],
                    [SUDO, "tee", "-a", "/etc/apt/sources.list.d/kubernetes.list"],
                ]
                out = run_pipe_cmd(cmds)

                out = run_cmd([SUDO, "apt-get", "install", "-y", "kubectl"])

                if out["returncode"] != 0:
                    print(
                        "--> kubectl install failed; please install manually and re-run this script"
                    )
                    sys.exit(1)

            else:
                print("--> kubectl already installed")

            # Install helm
            out = run_cmd(["helm", "version", "--short"])

            if out["returncode"] != 0:
                print("--> Attempting to install helm with deb packages")
                cmds = [
                    ["curl", "https://helm.baltorepo.com/organization/signing.asc"],
                    [SUDO, "apt-key", "add", "-"],
                ]
                out = run_pipe_cmd(cmds)

                cmds = [
                    ["echo", "deb https://baltocdn.com/helm/stable/debian/ all main"],
                    [SUDO, "tee", "/etc/apt/sources.list.d/helm-stable-debian.list"],
                ]
                out = run_pipe_cmd(cmds)

                out = run_cmd([SUDO, "apt-get", "install", "helm"])

                if out["returncode"] != 0:
                    print(
                        "--> helm install failed; please install manually and re-run this script"
                    )
                    sys.exit(1)

            else:
                print("--> helm already installed")

    # MacOS install
    elif os == "darwin":
        # Homebrew installs
        out = run_cmd(["brew", "--version"])

        if out["returncode"] == 0:
            print("--> Checking system packages and installing any missing packages")

            print("--> Updating brew")
            run_cmd(["brew", "update"])

        # Install packages
        BREW_PACKAGES = ["curl", "jq", "azure-cli", "kubernetes-cli", "kubernetes-helm"]
        for package in BREW_PACKAGES:
            out = run_cmd(["brew", "ls", "--versions", package])

            if out["output"] == "":
                print("--> brew installing %s" % package)
                out = run_cmd(["brew", "install", package])

                if out["returncode"] != 0:
                    print(
                        "--> %s install failed; please install manually and re-run this script"
                        % package
                    )

            else:
                print("--> %s already installed" % package)


def main():
    install_tools()


if __name__ == "__main__":
    main()
