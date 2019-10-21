# Copyright 2016 Philip G. Porada
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##
# INTERNAL VARIABLES
##
version  ?= "0.12.9"
os       ?= $(shell uname|tr A-Z a-z)
ifeq ($(shell uname -m),x86_64)
  arch   ?= "amd64"
endif
ifeq ($(shell uname -m),i686)
  arch   ?= "386"
endif
ifeq ($(shell uname -m),aarch64)
  arch   ?= "arm"
endif

unexport AWS_SECRET_KEY
unexport AWS_ACCESS_KEY
# unset AWS_SECRET_KEY
# unset AWS_ACCESS_KEY

ifeq ($(ENV),)
  ENV := dev
endif
ifeq ($(APP_NAME),)
  APP_NAME := k8s
endif
ifeq ($(AWS_PROFILE),)
  AWS_PROFILE := default
endif
ifeq ($(REGION),)
  REGION := eu-west-2
endif

export AWS_PROFILE
export REGION
export APP_NAME

# Read all subsquent tasks as arguments of the first task
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(args) $(RUN_ARGS):;@:)
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
landscape   := $(shell command -v landscape 2> /dev/null)
# terraform   := $(shell command -v terraform 2> /dev/null)
debug       :=
# Defaulting to level: TRACE. Valid levels are: [TRACE DEBUG INFO WARN ERROR]
export TF_LOG=
# export TF_LOG=ERROR

.ONESHELL:
.SHELL := /bin/bash
.PHONY: apply destroy-backend destroy destroy-target plan-destroy plan plan-target prep
VARS="variables/$(ENV)-$(REGION).tfvars"
CURRENT_FOLDER=$(shell basename "$$(pwd)")
S3_BUCKET=$(ENV)-$(REGION)-$(APP_NAME)-terraform
DYNAMODB_TABLE=$(ENV)-$(REGION)-$(APP_NAME)-terraform
WORKSPACE="$(ENV)-$(REGION)"
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)

export S3_BUCKET
export DYNAMODB_TABLE
export TF_VAR_s3_bucket=${S3_BUCKET}
export TF_VAR_key_bucket=$(ENV)/$(CURRENT_FOLDER)/terraform.tfstate
export TF_VAR_backend_profile=${AWS_PROFILE}
export TF_VAR_backend_region=${REGION}
# export TF_VAR_
# export TF_VAR_
# export TF_VAR_
# export TF_VAR_

##
# MAKEFILE ARGUMENTS
##
ifndef terraform
  install ?= "true"
endif
ifeq ("$(upgrade)", "true")
  install ?= "true"
endif

##
# TASKS
##
.PHONY: install
install: ## Install terraform and dependencies
ifeq ($(install),"true")
	@wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/$(version)/terraform_$(version)_$(os)_$(arch).zip
	@sudo unzip -d /usr/local/bin /tmp/terraform.zip && rm /tmp/terraform.zip
	@sudo chmod +x /usr/local/bin/terraform
endif
	@terraform --version

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

set-env:
	@if [ -z $(ENV) ]; then \
		echo "$(BOLD)$(RED)ENV was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ -z $(REGION) ]; then \
		echo "$(BOLD)$(RED)REGION was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ -z $(AWS_PROFILE) ]; then \
		echo "$(BOLD)$(RED)AWS_PROFILE was not set.$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ ! -z $${ERROR} ] && [ $${ERROR} -eq 1 ]; then \
		echo "$(BOLD)Example usage: \`AWS_PROFILE=whatever ENV=demo REGION=us-east-2 make plan\`$(RESET)"; \
		exit 1; \
	 fi
	@if [ ! -f "$(VARS)" ]; then \
		echo "$(BOLD)$(RED)Could not find variables file: $(VARS)$(RESET)"; \
		exit 1; \
	 fi

prep: set-env ## Prepare a new workspace (environment) if needed, configure the tfstate backend, update any modules, and switch to the workspace
	@#unset AWS_SECRET_KEY
	@#unset AWS_ACCESS_KEY
	@echo "$(BOLD)Verifying that the S3 bucket $(S3_BUCKET) for remote state exists$(RESET)"
	@./tf.sh createBucket
	@echo "$(BOLD)Verifying that the DynamoDB table exists for remote state locking$(RESET)"
	@./tf.sh createDynamodb
	@echo "$(BOLD)Configuring the terraform backend [S3 region ${TF_VAR_backend_region} profile ${TF_VAR_backend_profile}] $(RESET)"
	@echo "AWS_SECRET_KEY: ${AWS_SECRET_KEY}"
	@terraform init \
		-input=false \
		-force-copy \
		-lock=true \
		-upgrade \
		-verify-plugins=true \
		-backend=true \
		-backend-config="profile=$(TF_VAR_backend_profile)" \
		-backend-config="region=$(TF_VAR_backend_region)" \
		-backend-config="bucket=$(S3_BUCKET)" \
		-backend-config="key=$(ENV)/$(CURRENT_FOLDER)/terraform.tfstate" \
		-backend-config="dynamodb_table=$(DYNAMODB_TABLE)" \
	  -backend-config="acl=private"
	@echo "$(BOLD)Switching to workspace $(WORKSPACE)$(RESET)"
	@terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)

plan: prep ## Show what terraform thinks it will do
	@terraform plan \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

# -var "profile=$(AWS_PROFILE)" \
# 		-var "region=$(REGION)" \
# 		-var "bucket=$(S3_BUCKET)" \
# 		-var "key=$(ENV)/$(CURRENT_FOLDER)/terraform.tfstate" \
# 		-var "dynamodb_table=$(DYNAMODB_TABLE)" \

plan-target: prep ## Shows what a plan looks like for applying a specific resource
	@echo "$(YELLOW)$(BOLD)[INFO]   $(RESET)"; echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@read -p "PLAN target: " DATA && \
		terraform plan \
			-lock=true \
			-input=true \
			-refresh=true \
			-var-file="$(VARS)" \
			-target=$$DATA

plan-destroy: prep ## Creates a destruction plan.
	@terraform plan \
		-input=false \
		-refresh=true \
		-destroy \
		-var-file="$(VARS)"

apply: prep ## Have terraform do the things. This will cost money.
	@terraform apply \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

destroy: prep ## Destroy the things
	@terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

destroy-target: prep ## Destroy a specific resource. Caution though, this destroys chained resources.
	@echo "$(YELLOW)$(BOLD)[INFO] Specifically destroy a piece of Terraform data.$(RESET)"; echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@read -p "Destroy target: " DATA && \
		terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file=$(VARS) \
		-target=$$DATA

destroy-backend: ## Destroy S3 bucket and DynamoDB table
	@./tf.sh destroyBackend
