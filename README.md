# Build a Custom Container with Jupyterlab

Recently, I needed to customize the runtime environment of a Vertex AI Workbench instance to support Python 3.11. Google Cloud provides [prebuilt containers for custom training](https://cloud.google.com/vertex-ai/docs/training/pre-built-containers) which can be used to extend functionality by installing additional packages you might need to customize the environment.

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
# Override the existing CMD directive from the base container.
CMD ["/run_jupyter.sh"]
```

## Cloud Build job execution

To build the container to use with your workbench instance, run a cloud build job using the `cloudbuild.yaml` provided as an example. Note that we will be pushing the built container to [Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling) to reference in the terraform script used to provision the workbench instance. You will need to grant the GCP account with access to [Artifact Registry the `roles/artifactRegistry.reader` role](https://cloud.google.com/artifact-registry/docs/access-control#roles) so it can pull the image when terraform attempts to provision the Vertex AI workbench instance.

To run the Cloud Build job:
```
export PROJECT_ID = $(gcloud config get-value project)
gcloud builds submit --config cloudbuild.yaml --project $PROJECT_ID
```

This will submit a Cloud Build job using the cloudbuild.yaml file found in this repo. The build job builds the container using the base image referenced and pushes the resulting container to Artifact Registry of the project you submit the build job from.

### Share the Container Image with Service Account(s)

To ensure you can pull the container image when provisioning infrastructure, ensure that the __Artifact Registry__ repository grants the role `role/artifactRegistery.reader` to the IAM member (user, group, domain, service account, etc.) that will use the image when scaffolding a Vertex AI workbench instance.

## Deploy infrastructure using Terraform

To deploy the infrastructure required to access the custom container, clone the terraform folder to __Cloud Shell__ or jump host and apply the terraform to provision the infrastructure required.

```
git clone https://github.com/vishal84/CustomDeepLearningReleaseContainer.git
```

To apply the Terraform, switch to the terraform directory:
```
cd CustomDeepLearningReleaseContainer/terraform
```

Then run terraform apply to deploy the infrastructure. Notice that the 
```
terraform init
terraform plan
terraform apply
```

## Access the Instance

Once the infrastructure deploys you can access the Vertex AI workbench instance in Cloud Console.

Navigate to __Vertex AI__ > __Workbench__. 

You will see an instance called `custom-container-instance` provisioned by terraform in the prior step. Click on __Open JupyterLab__ button to access the instance.

![Open JupyterLab](img/open_jupyterlab.png)

Load a notebook of your choice and ensure you can select the custom python kernell installed into the environment. In this case, `Python 3.11` was installed with `pytorch 2.6` and required cuda libraries for working with GPU resources.

![python311 Kernel](img/python311_kernel.png)

