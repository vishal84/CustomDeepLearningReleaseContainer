# DockerFile
FROM us-docker.pkg.dev/deeplearning-platform-release/gcr.io/workbench-container:latest

ENV MAMBA_ROOT_PREFIX=/opt/micromamba
RUN micromamba create -n python311 -c conda-forge python=3.11 -y
SHELL ["micromamba", "run", "-n", "python311", "/bin/bash", "-c"]
RUN micromamba install -c conda-forge pip -y

# RUN pip install --upgrade pip
RUN pip install ipykernel
RUN pip install torch torchaudio torchvision

RUN python -m ipykernel install --prefix "/opt/micromamba/envs/python311" --name python311 --display-name "python311"
RUN rm -rf "/opt/micromamba/envs/python311/share/jupyter/kernels/python3"

# Override the existing CMD directive from the base container.
CMD ["/run_jupyter.sh"]