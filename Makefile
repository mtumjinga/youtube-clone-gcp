PROJECT_ID=anothertest-440718
ZONE=us-east4-c
VM_PATH=/home/${USER}/app
REPO_URL=https://github.com/markbosire/youtube-clone-gcp.git
APP_NAME=youtube
VM_NAME=$(APP_NAME)-instance-$(ENV)
GITHUB_SHA?=latest
IMAGE_TAG := $(GITHUB_SHA)
LOCAL_TAG_BACKEND=youtube-backend:$(GITHUB_SHA)
LOCAL_TAG_FRONTEND=youtube-frontend:$(GITHUB_SHA)
REMOTE_TAG_BACKEND=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG_BACKEND)
REMOTE_TAG_FRONTEND=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG_FRONTEND)
CONTAINER_NAME_BACKEND=youtube-backend
CONTAINER_NAME_FRONTEND=youtube-frontend



check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

run-local:
	docker-compose up 

create-tf-backend-bucket:
	gcloud storage buckets create gs://$(PROJECT_ID)-terraform --project=$(PROJECT_ID)

terraform-create-workspace: check-env
	cd terraform && terraform workspace new $(ENV)

terraform-init: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

terraform-destroy: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform destroy \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars"

TF_ACTION?=plan
terraform-action: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars"
ssh: check-env
	gcloud compute ssh --zone $(ZONE) --project $(PROJECT_ID) $(VM_NAME)

ssh-cmd: check-env
	@gcloud compute ssh --zone $(ZONE) --project $(PROJECT_ID) --command "$(CMD)" $(VM_NAME)

install-docker: check-env
	$(MAKE) ssh-cmd CMD="\
		sudo apt-get update && \
		sudo apt-get install curl && \
		curl -fsSL https://get.docker.com/ | sh && \
		sudo usermod -aG docker ${USER}"
install-docker-compose: check-env
	$(MAKE) ssh-cmd CMD=' \
		sudo apt-get update && \
		mkdir -p ~/.docker/cli-plugins/ && \
		curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose && \
		chmod +x ~/.docker/cli-plugins/docker-compose && \
		docker compose version'

build: 
	docker build -t youtube-backend:${IMAGE_TAG} -f ./server/Dockerfile ./server 
	
	@echo "Building Docker image without displaying secrets..."
	@docker build -t youtube-frontend:${IMAGE_TAG} \
  	--build-arg REACT_APP_FIREBASE_API_KEY=\"$(shell gcloud secrets versions access latest --secret="REACT_APP_FIREBASE_API_KEY" --project=$(PROJECT_ID))\" \
  	-f ./client/Dockerfile ./client 

push:
	docker tag $(LOCAL_TAG_BACKEND) $(REMOTE_TAG_BACKEND)
	docker push $(REMOTE_TAG_BACKEND)
	docker tag $(LOCAL_TAG_FRONTEND) $(REMOTE_TAG_FRONTEND)
	docker push $(REMOTE_TAG_FRONTEND)

deploy: check-env
   	
	# Pull the latest code on the VM
	$(MAKE) ssh-cmd CMD='\
		if [ -d $(VM_PATH) ]; then \
			cd $(VM_PATH) && git pull; \
		else \
			git clone $(REPO_URL) $(VM_PATH); \
		fi'

	# Configure Docker credentials on the VM for Google Container Registry access
	$(MAKE) ssh-cmd CMD='gcloud auth configure-docker --quiet'

	# Stop and remove any running containers
	$(MAKE) ssh-cmd CMD='docker stop $(docker ps -q) || true'
	$(MAKE) ssh-cmd CMD='docker rm $(docker ps -a -q) || true'
	
	# Pull the latest images on the VM
	@echo "Pulling latest container images..."
	$(MAKE) ssh-cmd CMD='cd $(VM_PATH) && docker pull $(REMOTE_TAG_BACKEND) && docker pull $(REMOTE_TAG_FRONTEND)'
	@echo "Deploying new container versions with docker compose..."
	@$(MAKE) ssh-cmd CMD='export REACT_APP_FIREBASE_API_KEY=\"$(shell gcloud secrets versions access latest --secret="REACT_APP_FIREBASE_API_KEY" --project=$(PROJECT_ID))\" && \
	export IMAGE_TAG=\"$(IMAGE_TAG)\" && \
	export MONGO=\"$(shell gcloud secrets versions access latest --secret="MONGO" --project=$(PROJECT_ID))\" && \
	export JWT=\"$(shell gcloud secrets versions access latest --secret="JWT" --project=$(PROJECT_ID))\" && \
	cd $(VM_PATH) && \
	docker compose down && \
	docker compose up -d'
