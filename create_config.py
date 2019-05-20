"""
Script to automatically write a BinderHub config.yaml file using DockerHub as an
image/container registry. Arguments are:
* -id: DockerHub login ID
* --prefix: Prefix to be prepended to Docker image files
* -org: DockerHub organisation name. Docker ID must be a member of this organisation
* --jupyterhub_ip: IP address of the deployed JupyterHub
* --force: If a config.yaml file already exists, this argument will overwrite it
* output_file: File the config is saved to
"""

import yaml
import argparse
import os


def parse_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("-id", "--docker-id", type=str, required=True,
                        help="Docker ID")
    parser.add_argument("--prefix", type=str, required=True,
                        help="Docker image prefix")
    parser.add_argument("-org", "--docker-org", default=None,
                        help="Docker organisation ID")
    parser.add_argument("--jupyterhub_ip", type=str, default=None,
                        help="IP address of the JupyterHub")
    parser.add_argument("--template", type=str, default="config-template.yaml",
                        help="Template config file")
    parser.add_argument("--force", action="store_true",
                        help="Overwrite existing files")
    parser.add_argument("output_file", nargs="?", default="config.yaml",
                        help="Output file for config")

    return parser.parse_args()


def main():

    args = parse_args()

    if os.path.exists(args.output_file):
        if args.force == True:
            os.remove(args.output_file)
        else:
            raise RuntimeError("Output file already exists: {}".format(
                args.output_file))

    template = yaml.load(open(args.template, "r"))
    if not (args.docker_org is None):
        template['config']['BinderHub']['image_prefix'] = (
            template['config']['BinderHub']['image_prefix'].replace(
                "<docker-id>", args.docker_org).replace("<prefix>", args.prefix)
        )
    else:
        template['config']['BinderHub']['image_prefix'] = (
            template['config']['BinderHub']['image_prefix'].replace(
            "<docker-id>", args.docker_id).replace("<prefix>", args.prefix)
        )

    if not (args.jupyterhub_ip is None):
        template['hub'] = {}
        template['hub']['url'] = "http://{}".format(args.jupyterhub_ip)

    yaml.dump(template, open(args.output_file, "w"), default_flow_style=False)

    return None


if __name__ == "__main__":
    main()
