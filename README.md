# CustomDeepLearningReleaseContainer

Recently, I needed to customize the runtime environment of a Vertex AI Workbench environment to support Python 3.11. Google Cloud provides ![prebuilt containers for custom training](https://cloud.google.com/vertex-ai/docs/training/pre-built-containers) which can be used to extend functionality by installing additional packages you might need to customize the environment.

Using guidance provided in the ![Create an instance using a custom container](https://cloud.google.com/vertex-ai/docs/workbench/instances/create-custom-container) documentation I was able to install Python 3.11 and include an additional python kernell to use in the Jupyter Lab environment hosted by Vertex AI Workbench.

