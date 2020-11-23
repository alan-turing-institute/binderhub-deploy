import os
import os.path as op
from glob import glob
from src import __version__
from setuptools import setup, find_packages

# Source dependencies from requirements.txt file.
try:
    with open(op.join("src", "requirements.txt"), "r") as f:
        lines = f.readlines()
        install_packages = [line.strip() for line in lines]
except FileNotFoundError:
    install_packages = []

setup(
    name="binderhub_deploy",
    version=__version__,
    install_requires=install_packages,
    include_package_data=True,
    python_requires=">=3.7",
    author="Sarah Gibson",
    author_email="sgibson@turing.ac.uk-0p",
    # this should be a whitespace separated string of keywords, not a list
    keywords="deployment cli-tool binderhub azure",
    description="CLI tool to deploy a BinderHub to Azure Cloud",
    long_description=open("./README.md", "r").read(),
    long_description_content_type="text/markdown",
    license="MIT",
    packages=find_packages(),
    use_package_data=True,
    entry_points={"console_scripts": ["bhub-deploy = src.cli:main"]},
)
