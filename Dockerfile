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