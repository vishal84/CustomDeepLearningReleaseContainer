# CustomDeepLearningReleaseContainer

Recently, I needed to customize the runtime environment of a Vertex AI Workbench environment to support Python 3.11. Google Cloud provides [prebuilt containers for custom training](https://cloud.google.com/vertex-ai/docs/training/pre-built-containers) which can be used to extend functionality by installing additional packages you might need to customize the environment.

Using guidance provided in the [Create an instance using a custom container](https://cloud.google.com/vertex-ai/docs/workbench/instances/create-custom-container) documentation I was able to install Python 3.11 and include an additional python kernell to use in the Jupyter Lab environment hosted by Vertex AI Workbench.

## Dockerfile

The `Dockerfile` referenced in this repository provides an example of how to customize the runtime environment to suite your needs from an existing prebuilt container image. 

```
# DockerFile
FROM us-docker.pkg.dev/deeplearning-platform-release/gcr.io/workbench-container:latest

RUN apt-get update && apt-get install -y gsutil

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
RUN micromamba create -n python311 -c conda-forge python=3.11 -y
SHELL ["micromamba", "run", "-n", "python311", "/bin/bash", "-c"]
RUN micromamba install -c conda-forge pip -y

# RUN pip install --upgrade pip
RUN pip install ipykernel
RUN pip install plotly==5.24.1
RUN pip install nbformat==5.10.4
RUN pip install transformers==4.49.0
RUN pip install torch torchaudio torchvision
RUN pip install tensorflow==2.18.0
RUN pip install jax[cuda12]==0.5.2

RUN python -m ipykernel install --prefix "/opt/micromamba/envs/python311" --name python311 --display-name "python311"
RUN rm -rf "/opt/micromamba/envs/python311/share/jupyter/kernels/python3"

# Override the existing CMD directive from the base container.
CMD ["/run_jupyter.sh"]
```