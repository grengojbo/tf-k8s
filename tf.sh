#!/usr/bin/env bash
#set -e

unset AWS_SECRET_KEY
unset AWS_ACCESS_KEY

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`
#if [ -z "${provider}" ]; then
#    echo "'provider' variable must be set"
#    exit
#fi
#
#if [ -z "${env}" ]; then
#    echo "'env' variable must be set"
#    exit
#fi
#
#vault_path=${vault_path:-""}
#vault_ttl=${vault_ttl:-"15m"}
#
#vault_aws=${vault_aws:-"true"}
#vault_aws_role=${vault_aws_role:-"admin"}
#vault_aws_iam=${vault_aws_iam:-"false"}
#
#valid_identifier()
#{
#    echo "$1" | tr '[:lower:]' '[:upper:]' | tr -cs '[:alpha:][:digit:]\n' '_'
#}
#
#key="$(valid_identifier "${provider}")_$(valid_identifier "${env}")_KEY"
#secret="$(valid_identifier "${provider}")_$(valid_identifier "${env}")_SECRET"
#token="$(valid_identifier "${provider}")_$(valid_identifier "${env}")_TOKEN"
#
#if (which pass >/dev/null 2>&1); then
#    pass_key="$(pass "terraform/${provider}/${env}/access_key" || echo '')"
#    pass_secret="$(pass "terraform/${provider}/${env}/secret" || echo '')"
#    pass_token="$(pass "terraform/${provider}/${env}/token" || echo '')"
#
#    if [ -n "${pass_key}" ] && [ -n "${pass_secret}" ]; then
#        declare "${key}"="${pass_key}"
#        declare "${secret}"="${pass_secret}"
#    fi
#    if [ -n "${pass_token}" ]; then
#        declare "${token}"="${pass_token}"
#    fi
#fi
#
#if [ -n "${VAULT_ADDR}" ]; then
#    if [ -z "${VAULT_TOKEN}" ]; then
#        if [ -n "${VAULT_ROLE_ID}" ] && [ -n "${VAULT_SECRET_ID}" ]; then
#            declare -x "VAULT_TOKEN"=$(curl -s -X POST -d "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"${VAULT_SECRET_ID}\"}" "${VAULT_ADDR}/v1/auth/approle/login" | jq -r .auth.client_token)
#            if [ -z "${VAULT_TOKEN}" ] || [ "${VAULT_TOKEN}" == "null" ]; then
#                echo "Error fetching 'VAULT_TOKEN' from 'VAULT_ROLE_ID' and 'VAULT_SECRET_ID'"
#                exit
#            fi
#        else
#            echo "'VAULT_TOKEN' or ( 'VAULT_ROLE_ID' and 'VAULT_SECRET_ID' ) must be set!"
#            exit
#        fi
#    fi
#
#    if [ "${vault_aws}" == "true" ]; then
#        if [ -z "${vault_path}" ]; then
#          vault_path="aws"
#        fi
#
#        if [ -z "${vault_aws_role}" ]; then
#          echo "'vault_aws_role' variable must be set"
#          exit
#        fi
#
#        # We use STS by default but if we need to perform IAM actions we can't use it
#        if [ "${vault_aws_iam}" == "true" ]; then
#            creds=$(curl -s -X GET -H "X-Vault-Token: ${VAULT_TOKEN}" -d "{\"ttl\":\"${vault_ttl}\"}" "${VAULT_ADDR}/v1/${vault_path}/creds/${vault_aws_role}" | jq .data)
#        else
#            creds=$(curl -s -X GET -H "X-Vault-Token: ${VAULT_TOKEN}" -d "{\"ttl\":\"${vault_ttl}\"}" "${VAULT_ADDR}/v1/${vault_path}/sts/${vault_aws_role}" | jq .data)
#            declare -x "AWS_SESSION_TOKEN"=$(echo ${creds} | jq -r .security_token)
#        fi
#
#        if [ -z "$(echo ${creds})" ] || [ "$(echo ${creds} | jq -r .access_key)" == "null" ]; then
#            echo "Unable to fetch AWS credentials from Vault"
#            exit
#        fi
#
#        declare -x "AWS_ACCESS_KEY_ID"=$(echo ${creds} | jq -r .access_key)
#        declare -x "AWS_SECRET_ACCESS_KEY"=$(echo ${creds} | jq -r .secret_key)
#
#        echo "Fetched AWS credentials from Vault."
#    fi
#fi
#
#case $provider in
#    aws)
#        if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
#            declare -x "AWS_ACCESS_KEY_ID=${!key}"
#            declare -x "AWS_SECRET_ACCESS_KEY=${!secret}"
#
#            if [ -n "${!token}" ]; then
#                declare -x "AWS_SESSION_TOKEN=${!token}"
#            fi
#        fi
#        ;;
#    azurerm)
#        if [ -z "${ARM_CLIENT_ID}" ]; then
#            declare -x "ARM_CLIENT_ID=${!key}"
#            declare -x "ARM_CLIENT_SECRET=${!secret}"
#        fi
#        ;;
#    "do")
#        if [ -z "${DIGITALOCEAN_TOKEN}" ]; then
#            declare -x "DIGITALOCEAN_TOKEN=${!secret}"
#        fi
#        ;;
#    google)
#        if [ -z "${GOOGLE_CREDENTIALS}" ]; then
#            declare -x "GOOGLE_CREDENTIALS=${!secret}"
#        fi
#        ;;
#    scaleway)
#        if [ -z "${SCALEWAY_ORGANIZATION}" ]; then
#            declare -x "SCALEWAY_ORGANIZATION=${!key}"
#            declare -x "SCALEWAY_TOKEN=${!secret}"
#        fi
#        ;;
#    ovh)
#        if [ -z "${OS_PASSWORD}" ]; then
#            declare -x "OS_USERNAME=${!key}"
#            declare -x "OS_PASSWORD=${!secret}"
#        elif [ -z "${OS_AUTH_TOKEN}" ]; then
#            declare -x "OS_AUTH_TOKEN=${!secret}"
#        fi
#        if [ -z "${OVH_APPLICATION_KEY}" ]; then
#            declare -x "OVH_APPLICATION_KEY=${!key}"
#            declare -x "OVH_APPLICATION_SECRET=${!secret}"
#            declare -x "OVH_CONSUMER_KEY=${!token}"
#        fi
#        ;;
#esac

if [ -n "$debug" ]; then
    declare -x "TF_LOG=$debug"
fi

if [[ "${1}" == "createBucket" ]]; then
    aws --profile ${AWS_PROFILE} s3api head-bucket --region ${REGION} --bucket ${S3_BUCKET} > /dev/null 2>&1
    RES=$?
    if [[  "${RES}" == "0" ]]; then
        echo "${BOLD}${GREEN}S3 bucket ${S3_BUCKET} exists${RESET}"
    else

        echo "${BOLD}${YELLOW}S3 bucket ${S3_BUCKET} was not found, creating new bucket with versioning enabled to store tfstate${RESET}"
        aws --profile ${AWS_PROFILE} s3api create-bucket \
            --bucket ${S3_BUCKET} \
 		    --acl private \
 		    --region ${REGION} \
 		    --create-bucket-configuration LocationConstraint=${REGION}
 	    aws --profile ${AWS_PROFILE} s3api put-bucket-versioning \
 		    --bucket ${S3_BUCKET} \
 		    --versioning-configuration Status=Enabled
 	    echo "${BOLD}${GREEN}S3 bucket ${S3_BUCKET} created$(RESET)"
    fi
fi

if [[ "${1}" == "createDynamodb" ]]; then
    aws --profile ${AWS_PROFILE} dynamodb describe-table --table-name ${DYNAMODB_TABLE} > /dev/null 2>&1
    if [[  "$?" == "0" ]]; then
 	    echo "${BOLD}${GREEN}DynamoDB Table ${DYNAMODB_TABLE} exists${RESET}"
 	else
 	    echo "${BOLD}${YELLOW}DynamoDB table ${DYNAMODB_TABLE} was not found, creating new DynamoDB table to maintain locks${RESET}"
 	    aws --profile ${AWS_PROFILE} dynamodb create-table \
     	    --region ${REGION} \
 	        --table-name ${DYNAMODB_TABLE} \
 	        --attribute-definitions AttributeName=LockID,AttributeType=S \
     	    --key-schema AttributeName=LockID,KeyType=HASH \
 	        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
 		echo "${BOLD}${GREEN}DynamoDB table ${DYNAMODB_TABLE} created${RESET}"
 		echo "Sleeping for 10 seconds to allow DynamoDB state to propagate through AWS"
 		sleep 10
 	    aws ec2 --profile=${AWS_PROFILE} describe-key-pairs --key-names ${ENV}_infra_key > /dev/null 2>&1
 	    if [[ "$?" == "0" ]]; then
 	        echo "${BOLD}${GREEN}EC2 Key Pair ${ENV}_infra_key exists${RESET}"
 	    else
 	        echo "${BOLD}${RED}EC2 Key Pair ${ENV}_infra_key was not found${RESET}"
 	        read -p "${BOLD}Do you want to generate a new keypair? [y/Y]: ${RESET}" ANSWER
     	    if [[ "${ANSWER}" == "y" ]] || [[ "${ANSWER}" == "Y" ]]; then
 	        mkdir -p ~/.ssh
 	        ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/${ENV}_infra_key
         	aws ec2 --profile=${AWS_PROFILE} import-key-pair --key-name "${ENV}_infra_key" --public-key-material "file://~/.ssh/${ENV}_infra_key.pub"
     	    fi
 	  fi
 	fi
fi

if [[ "${1}" == "destroyBackend" ]]; then
 	aws --profile ${AWS_PROFILE} dynamodb delete-table \
 		--region ${REGION} \
 		--table-name ${DYNAMODB_TABLE} > /dev/null 2>&1
 	if [[ "$?" != "0" ]]; then
 	    echo "${BOLD}${RED}Unable to delete DynamoDB table ${DYNAMODB_TABLE}${RESET}"
    else
 		echo "${BOLD}${RED}DynamoDB table ${DYNAMODB_TABLE} does not exist.${RESET}"
 	fi
# 	aws --profile ${AWS_PROFILE} s3api delete-objects \
# 		--region ${REGION} \
# 		--bucket ${S3_BUCKET} \
# 		--delete "$(aws --profile ${AWS_PROFILE} s3api list-object-versions \
# 						--region ${REGION} \
# 						--bucket ${S3_BUCKET} \
# 						--output=json \
# 						--query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" > /dev/null 2>&1
    echo "------- $? "
# 	if [[ "$?" != "0" ]]; then
# 		echo "${BOLD}${RED}Unable to delete objects in S3 bucket ${S3_BUCKET}${RESET}"
# 	fi
# 	@if ! aws --profile $(AWS_PROFILE) s3api delete-objects \
# 		--region $(REGION) \
# 		--bucket $(S3_BUCKET) \
# 		--delete "$$(aws --profile $(AWS_PROFILE) s3api list-object-versions \
# 						--region $(REGION) \
# 						--bucket $(S3_BUCKET) \
# 						--output=json \
# 						--query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" > /dev/null 2>&1 ; then \
# 			echo "$(BOLD)$(RED)Unable to delete markers in S3 bucket $(S3_BUCKET)$(RESET)"; \
# 	 fi
# 	@if ! aws --profile $(AWS_PROFILE) s3api delete-bucket \
# 		--region $(REGION) \
# 		--bucket $(S3_BUCKET) > /dev/null 2>&1 ; then \
# 			echo "$(BOLD)$(RED)Unable to delete S3 bucket $(S3_BUCKET) itself$(RESET)"; \
# 	 fi
fi
#cd "providers/${provider}/${env}"
#terraform "$@"