# CI/CD Process Documentation

This document outlines the Continuous Integration and Continuous Deployment (CI/CD) process for the YouTube clone project, utilizing Docker, Docker Compose, and Google Cloud services. The steps include setting up the environment, building Docker images, pushing them to the Google Container Registry (GCR), and deploying the application.

## Prerequisites

Before you begin, ensure that you have the following:

- Access to a Google Cloud project.
- Docker and Docker Compose installed on your virtual machine (VM).
- Google Cloud SDK installed and authenticated on your VM.

## Installation

### 1. Install Docker

To install Docker, run the following command:

```bash
make install-docker
```

This command will:

- Update the package list.
- Install `curl`.
- Download and install Docker.
- Add the current user to the Docker group.

### 2. Install Docker Compose

To install Docker Compose, execute:

```bash
make install-docker-compose
```

This command will:

- Update the package list.
- Create a directory for Docker CLI plugins.
- Download the Docker Compose binary and make it executable.
- Verify the installation by checking the Docker Compose version.

## CI/CD Workflow

The following commands outline the CI/CD process for building, pushing, and deploying the application.

### Build Docker Images

To build the Docker images for the backend and frontend, run:

```bash
make build
```

This command does the following:

- Builds the backend Docker image using the `Dockerfile` located in the `./server` directory.
- Builds the frontend Docker image, passing in the Firebase API key from Google Cloud Secret Manager as a build argument without displaying secrets in the shell.

### Push Docker Images to GCR

To push the Docker images to Google Container Registry, run:

```bash
make push
```

This command tags the local images and pushes them to the remote GCR repository specified in the Makefile.

### Deploy the Application

To deploy the application to the VM, execute:

```bash
make deploy
```

This command performs the following steps:

1. Pulls the latest code from the Git repository on the VM. If the repository doesn't exist, it clones it.
2. Configures Docker credentials for Google Container Registry access.
3. Stops and removes any currently running Docker containers.
4. Pulls the latest Docker images from GCR.
5. Exports necessary environment variables, including secrets from Google Cloud Secret Manager.
6. Uses Docker Compose to bring down any existing containers and start up the new ones in detached mode.

## Notes

- Ensure that the secrets `REACT_APP_FIREBASE_API_KEY`, `MONGO`, and `JWT` are set in Google Cloud Secret Manager before deployment.

## Conclusion

This CI/CD process provides a streamlined approach to deploying updates to the YouTube clone application using Docker, ensuring that the latest code and container images are always in use. By following these steps, you can maintain a consistent deployment workflow and quickly iterate on features.
