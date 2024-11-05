
# YouTube Clone MERN Stack with GCP

This repository contains a YouTube clone built using the MERN stack (MongoDB, Express.js, React.js, Node.js) and deployed on Google Cloud Platform (GCP) using Terraform. The CI/CD pipeline was made using GitHub Actions.

# Table of Contents

- [YouTube Clone MERN Stack with GCP](#youtube-clone-mern-stack-with-gcp)
- [Table of Contents](#table-of-contents)
- [GCP Infrastructure as Code](#gcp-infrastructure-as-code)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
  - [CI/CD Pipeline](#cicd-pipeline)
  - [Application Architecture](#application-architecture)
- [Setup](#setup)
  - [Initial Setup](#initial-setup)
  - [Enable APIs](#enable-apis)
  - [Grant Necessary Roles for Terraform](#grant-necessary-roles-for-terraform)
      - [Example `common.tfvars` File](#example-commontfvars-file)
  - [Setup Guide for Firebase and MongoDB](#setup-guide-for-firebase-and-mongodb)
    - [1. Create a Firebase Account](#1-create-a-firebase-account)
    - [2. Configure Domain Access](#2-configure-domain-access)
    - [3. Configure `./client/src/firebase.js`](#3-configure-clientsrcfirebasejs)
    - [4. Create a MongoDB Cluster](#4-create-a-mongodb-cluster)
      - [5. Get Your MongoDB URI](#5-get-your-mongodb-uri)
    - [6. Enable Domain CORS Origin](#6-enable-domain-cors-origin)
    - [7. Storing Secrets in Google Cloud Secret Manager](#7-storing-secrets-in-google-cloud-secret-manager)
- [Technical Documentation](#technical-documentation)
- [License](#license)

# GCP Infrastructure as Code

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)

Production-ready infrastructure code for deploying scalable web applications on Google Cloud Platform using Terraform.

## Features

- Global Load Balancing with SSL
- Content Delivery Network (CDN)
- Automated Health Checks
- Custom Domain Configuration
- Monitoring and Logging
- Multi-environment Support

## Prerequisites

- [Git](https://git-scm.com/downloads)
- [Make](https://www.gnu.org/software/make/) (Essential for running the provided commands)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- A [Google Cloud Platform](https://console.cloud.google.com/) account
- A [GitHub](https://github.com/) account

# Architecture Overview

## CI/CD Pipeline

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Docker](https://img.shields.io/badge/Docker-2496ED.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED.svg?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)

![CI/CD Pipeline](./assets/cicd-pipeline.png)

The CI/CD pipeline follows these steps:

1. Code is pushed to the GitHub repository
2. The GitHub Actions workflow is triggered
3. Workload Identity Federation authenticates with GCP
4. GCloud authentication configures Docker
5. The Docker image is built
6. The Build process uses secrets from Secret Manager
7. The image is pushed to Artifact Registry
8. Deployment to Compute Engine
9. The container pulls secrets from Secret Manager
10. Application logs to Cloud Logging
11. Metrics are sent to Cloud Monitoring

## Application Architecture

[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![NGINX](https://img.shields.io/badge/NGINX-009639.svg?style=for-the-badge&logo=nginx&logoColor=white)](https://www.nginx.com/)
[![React](https://img.shields.io/badge/React-61DAFB.svg?style=for-the-badge&logo=react&logoColor=white)](https://reactjs.org/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-47A248.svg?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![Node.js](https://img.shields.io/badge/Node.js-8CC84B.svg?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

![Application Architecture](./assets/app-architecture.png)

The application flow works as follows:

1. User requests reach Cloud DNS
2. Traffic is routed through Cloud CDN
3. Static content is served from Cloud Storage
4. The Load Balancer routes requests to instances
5. Compute Engine runs the containerized application
6. Container images are pulled from Artifact Registry
7. NGINX serves as a reverse proxy
8. The React frontend is served from built assets
9. Express.js handles API requests
10. The backend connects to MongoDB
11. Firebase handles authentication
12. Media content is stored in Cloud Storage

# Setup

This guide will walk you through setting up and deploying a YouTube clone application on Google Cloud Platform (GCP) using Terraform and GitHub Actions for CI/CD.

## Initial Setup

1. Fork the Repository

   ```bash
   # Fork the repository at https://github.com/markbosire/youtube-clone-gcp
   # Then clone your forked repository
   git clone https://github.com/YOUR_USERNAME/youtube-clone-gcp.git
   cd youtube-clone-gcp
   ```

2. Set Up GCP Service Accounts and enable APIs

## Enable APIs

```bash
gcloud services enable compute.googleapis.com && \
gcloud services enable dns.googleapis.com && \
gcloud services enable storage.googleapis.com && \
gcloud services enable monitoring.googleapis.com && \
gcloud services enable logging.googleapis.com && \
gcloud services enable cloudresourcemanager.googleapis.com && \
gcloud services enable secretmanager.googleapis.com && \
gcloud services enable iam.googleapis.com && \
gcloud services enable artifactregistry.googleapis.com
```

## Grant Necessary Roles for Terraform

```bash
# Set the GCP project ID (replace with your actual project ID)
export PROJECT_ID=your-project-id

# Create a dedicated service account for Terraform operations
# This account will be used to manage infrastructure and deploy resources
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# Grant Compute Admin role
# Allows Terraform to create, modify, and delete compute resources like VMs and disks
# Essential for managing compute infrastructure
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Grant Compute Network User role
# Enables Terraform to use GCP networking features
# Required for configuring network interfaces, firewall rules, and VPC settings
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.networkUser"

# Grant DNS Administrator role
# Allows Terraform to manage DNS records and zones
# Necessary if your infrastructure requires DNS configuration
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

# Grant Service Account User role
# Enables Terraform to run operations as other service accounts
# Required for deploying resources that use service accounts
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Grant Storage Object Admin role
# Allows Terraform to manage storage objects and buckets
# Required for managing Terraform state files in GCS and other storage operations
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Create and download the service account key
# This key file will be used by Terraform to authenticate with GCP
# IMPORTANT: Keep this key secure and never commit it to version control
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account=terraform-sa@$PROJECT_ID.iam.gserviceaccount.com

mv terraform-sa-key.json terraform
```

b. Configure Workload Identity Federation for GitHub Actions:

```bash
# Create a Workload Identity Pool
# Set the GCP project ID (replace with your actual project ID)
export PROJECT_ID="YOUR PROJECT ID"
# Set the GITHUB USERNAME (replace with your actual USERNAME)
export GITHUB_USERNAME="YOUR GITHUB USERNAME"
# Obtain GCP Project Number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Create a Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create a Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository_owner==$GITHUB_USERNAME" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create a Service Account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

# Grant required roles for GitHub Actions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.instanceAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.createOnPushWriter"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB_USERNAME/youtube-clone-gcp"
```
3. Configure GitHub Repository Secrets

   Add the following secrets in your GitHub repository (Settings > Secrets and variables > Actions > secrets):

   - `PROJECT_ID`: Your Google Cloud Project ID
   - `WORKLOAD_IDENTITY_PROVIDER`: The Workload Identity Provider ID in this format '(projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider)'
     You can get the project number using this command:
     ```bash
     export PROJECT_ID="YOUR PROJECT ID"
     # Obtain GCP Project Number
     gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
     ```
   - `SERVICE_ACCOUNT`: The GitHub Actions service account email

    ```bash
    export PROJECT_ID="YOUR PROJECT ID"
    gcloud iam service-accounts list --project=$PROJECT_ID
    ```

4. Update GitHub Actions Workflow

   Edit `.github/workflows/build-push-deploy.yml` and uncomment the push section. Ensure the workload identity provider and service account details are correctly configured.

5. Configure Variables in `terraform/environments/common.tfvars`

The `common.tfvars` file contains variables required for deploying resources on GCP. Update the values in this file to match your environment.

#### Example `common.tfvars` File

```hcl
# Google Cloud Project ID
gcp_project_id = "your-project-id"

# Domain name for SSL and DNS configuration
domain_name = "yourdomain.com"

# Application name to prefix resource names
app_name = "myapp"
```

## Setup Guide for Firebase and MongoDB

This guide will help you set up a Firebase account, configure your Firebase settings, create a MongoDB cluster, and store your secrets in Google Cloud Secret Manager.

### 1. Create a Firebase Account

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click on **"Get Started"**.
3. If you don't have a Google account, create one. If you already have an account, log in.
4. Once logged in, click on **"Add project"** to create a new project.
5. Follow the prompts to set up your project and make sure to enable **Google Analytics** if needed.
6. Once the project is created, click on **"Continue"**.

### 2. Configure Domain Access

To allow your custom domain to access your Firebase project, follow these steps:

1. In the Firebase Console, go to **"Authentication"** from the left sidebar.
2. Click on the **"Sign-in method"** tab.
3. Go to the Sign-in method tab.
4. Scroll down to Google and click the edit pencil icon.
5. Toggle Enable to on.
6. Add a Project support email if prompted.
7. Click Save.
8. Go to the Settings method tab.
9. Scroll down to **"Authorized domains"** and click **"Add domain"**.
10. Enter your domain name (e.g., `markbosire.click` or `www.markbosire.click`).
11. Click **"Save"** to authorize the domain.

### 3. Configure `./client/src/firebase.js`

1. In your Firebase project, click on the **"Settings"** icon (⚙️) next to **"Project Overview"** in the left sidebar.
2. Under **"Your apps"**, click on **"Web"** to register a web app.
3. After registering, you will see your Firebase configuration settings.
4. Copy the **`apiKey`** that you will set later.
5. Replace the values of the others in your `.client/src/firebase.js` file.

Here is how your the config should look, but the values will be different:

```javascript
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY, 
  authDomain: "clone-59a2e.firebaseapp.com",
  projectId: "clone-59a2e",
  storageBucket: "clone-59a2e.appspot.com",
  messagingSenderId: "510132767380",
  appId: "1:510132767380:web:9963ad58a8f85f3219c281",
};
```

Make sure to copy the `apiKey` from the Firebase settings later.

### 4. Create a MongoDB Cluster

1. Go to the [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) website.
2. Sign up for a new account or log in if you already have one.
3. Click on **"Build a Cluster"**.
4. Choose **Google Cloud Platform (GCP)** as your cloud provider and select the appropriate region for your cluster.
5. Select the cluster tier that fits your needs (you can start with the free tier).
6. Click on **"Create Cluster"** and wait for your cluster to be provisioned.
7. Ensure you have enabled access from anywhere in the network access.

#### 5. Get Your MongoDB URI

1. Once your cluster is created, click on **"Connect"**.
2. Choose **"Connect your application"**.
3. Copy the connection string (MongoDB URI) provided. It should look like this:

   ```
   mongodb+srv://<username>:<password>@cluster0.mongodb.net/<dbname>?retryWrites=true&w=majority
   ```

4. Replace `<username>`, `<password>`, and `<dbname>` with your actual values.

### 6. Enable Domain CORS Origin

Go to `./server/index.js`
Edit the http and https domain to your domain:

```javascript
    app.use(
      cors({
        origin: [
          "http://localhost:3000",
          "http://localhost:80",
          "http://markbosire.click",//replace with your domain
          "https://markbosire.click", //replace with your domain
        ],
        credentials: true,
      })
    );
```

### 7. Storing Secrets in Google Cloud Secret Manager

Now, you'll need to store your secrets in Google Cloud Secret Manager.

1. **Enable the Secret Manager API**:

   ```bash
   gcloud services enable secretmanager.googleapis.com
   ```

2. **Create each secret**:

   ```bash
   # Export environment variables for secrets
   # Generate a JWT secret and export it
   export JWT_SECRET=$(openssl rand -base64 32)
   echo "Generated JWT_SECRET: $JWT_SECRET"

   # Export other environment variables for secrets
   export MONGO_URI="YOUR_MONGO_URI"
   export FIREBASE_API_KEY="YOUR_FIREBASE_API_KEY"

   # Create MONGO secret
   gcloud secrets create MONGO --replication-policy="automatic"
   printf "%s" "$MONGO_URI" | gcloud secrets versions add MONGO --data-file=-

   # Create JWT secret
   gcloud secrets create JWT --replication-policy="automatic"
   echo -n "$JWT_SECRET" | gcloud secrets versions add JWT --data-file=-

   # Create REACT_APP_FIREBASE_API_KEY secret
   gcloud secrets create REACT_APP_FIREBASE_API_KEY --replication-policy="automatic"
   echo -n "$FIREBASE_API_KEY" | gcloud secrets versions add REACT_APP_FIREBASE_API_KEY --data-file=-
   ```

   Replace `YOUR_MONGO_URI` and `YOUR_FIREBASE_API_KEY` with your actual values and take note of your jwt secrets in case of any issue.

3. Initialize the Project

   Change `PROJECT_ID` in `./Makefile`

   ```bash
   PROJECT_ID=banded-meridian-435911-g6 # change this to your project id
   ```

   Create backend

   ```bash
   make create-tf-backend-bucket
   ```

   Confirm if `terraform-sa-key.json` is in the `terraform` folder

   ```bash
   cd terraform
   ls
   ```

   Edit the project ID in `./main.tf`

   ```hcl
   backend "gcs" {
     bucket = "banded-meridian-435911-g6-terraform" # change the project id (banded-meridian-435911-g6) to yours
     prefix = "/state/youtube"
   }
   ```

   If it's there, add the application credentials for Terraform to use and initialize it

   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=terraform-sa-key.json
   terraform init
   ```

   ```bash
   # Move to the main folder
   cd ../

   # Create the Terraform backend bucket

   # Initialize Terraform workspace
   make terraform-create-workspace ENV=staging
   make terraform-init ENV=staging

   # Deploy infrastructure
   make terraform-action ENV=staging TF_ACTION=apply
   ```

4. Start CI-CD pipeline

   ```bash
   git add .
   git commit -m "your message"
   git push origin main
   ```

5. Update your domain's name servers

   ```bash
   # Retrieve the name servers, then update it in your domain settings
   gcloud dns managed-zones describe youtube-dns-zone-staging --format="get(nameServers)"
   ```

   After the DNS has finished propagating, you can visit the site. This will take a while.
   
### Monitoring and Logging

You can find instructions on monitoring and logging in [Monitoring and Logging](./docs/monitoringandlogging.md)

# Technical Documentation

For detailed technical documentation, please refer to:

- [Infrastructure](./docs/infrastructure.md)
- [CI/CD](./docs/CI-CD.md)

# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
