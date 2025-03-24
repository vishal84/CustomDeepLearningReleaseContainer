# CustomDeepLearningReleaseContainer

Recently, I needed to customize the runtime environment of a Vertex AI Workbench environment to support Python 3.11. Google Cloud provides [prebuilt containers for custom training](https://cloud.google.com/vertex-ai/docs/training/pre-built-containers) which can be used to extend functionality by installing additional packages you might need to customize the environment.

Using guidance provided in the [Create an instance using a custom container](https://cloud.google.com/vertex-ai/docs/workbench/instances/create-custom-container) documentation I was able to install Python 3.11 and include an additional python kernell to use in the Jupyter Lab environment hosted by Vertex AI Workbench.

## Dockerfile

The `Dockerfile` referenced in this repository provides an example of how to customize the runtime environment to suite your needs from an existing prebuilt container image. The sections below provide a breakdown of the `Dockerfile` in more detail.

### Extend base image
```
FROM us-docker.pkg.dev/deeplearning-platform-release/gcr.io/workbench-container:latest
```

This custom container uses the `workbench-container:latest` prebuilt container as its base image.

### Install OS packages

```
RUN apt-get update && apt-get install -y gsutil
```

This steps updates package lists for upgrades and installs `gsutil` for interacting with Google Cloud Storage.

### Install python 3.11, pip packages and python kernel

The `workbench-container` image comes pre-installed with `micromamba` which can manage specific python packages for an environment being hosted.

```
ENV MAMBA_ROOT_PREFIX=/opt/micromamba
RUN micromamba create -n python311 -c conda-forge python=3.11 -y
SHELL ["micromamba", "run", "-n", "python311", "/bin/bash", "-c"]
RUN micromamba install -c conda-forge pip -y

# RUN pip install --upgrade pip
RUN pip install ipykernel
RUN pip install torch torchaudio torchvision
```

### Add and Remove python environments

The following snippet installs a new python kernell named `python311` that can be used within the Jupyter Lab environment hosted by Vertex AI Workbench and removes an unnecessary `python3` environment.

```
RUN python -m ipykernel install --prefix "/opt/micromamba/envs/python311" --name python311 --display-name "python311"
RUN rm -rf "/opt/micromamba/envs/python311/share/jupyter/kernels/python3"
```

### Execute `/run_jupyter.sh` script

The last requirement is for the `/run_jupyter.sh` script to run in order to scaffold the Jupyter Lab environment upon startup.

```
/# Override the existing CMD directive from the base container.
CMD ["/run_jupyter.sh"]
```