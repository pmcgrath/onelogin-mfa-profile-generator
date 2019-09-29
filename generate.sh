#!/usr/bin/env ash
# Script that uses the https://github.com/onelogin/onelogin-aws-cli-assume-role
# See also https://developers.onelogin.com/api-docs/1/samples/aws-cli
# Using env vars rather than script args, will populate a named profile in an aws credentials file


# Env vars we expected to be set
# Could also turn these into args
: ${AWS_REGION:?'i.e. us-east-2'}
: ${AWS_PROFILE:?'aws credentials file profile to set/update i.e. mfa'}
: ${EMAIL:?'This is the onelogin email you use, i.e. first.last@nearform.com'}
: ${ONELOGIN_APP_ID}
: ${ONELOGIN_CLIENT_ID}
: ${ONELOGIN_CLIENT_SECRET}
: ${ONELOGIN_SUB_DOMAIN}


# Check if creating credential file for first time - if so lets assume using no volume mount to change on host for a "docker container run" env
creds_file_path=/onelogin/.aws/credentials
creds_file_path_already_exists=false; [[ -f ${creds_file_path} ]] && creds_file_path_already_exists=true


# File that the jar will read from, see https://github.com/onelogin/onelogin-aws-cli-assume-role/blob/master/onelogin-aws-assume-role-cli/dist/onelogin.sdk.properties
cat > onelogin.sdk.properties << EOF
onelogin.sdk.client_id=${ONELOGIN_CLIENT_ID}
onelogin.sdk.client_secret=${ONELOGIN_CLIENT_SECRET}
onelogin.sdk.ip=
EOF


# Print AWS account map if it exists
[[ ! -z "${AWS_ACCOUNT_MAP}" ]] && echo -e "\e[32mAWS account map\e[0m\n${AWS_ACCOUNT_MAP}"


# Execute
# See https://github.com/onelogin/onelogin-aws-cli-assume-role/blob/master/onelogin-aws-assume-role-cli/src/main/java/com/onelogin/aws/assume/role/cli/OneloginAWSCLI.java#L178
java -jar onelogin-aws-cli.jar \
	--appid ${ONELOGIN_APP_ID} \
	--file ${creds_file_path} \
	--profile ${AWS_PROFILE} \
	--region ${AWS_REGION} \
	--subdomain ${ONELOGIN_SUB_DOMAIN} \
	--username ${EMAIL}


echo -e "\n\n\n"
if [[ $creds_file_path_already_exists == true ]]; then
	# Guessing you mounted the host ~/.aws directory on a "docker container run" env
	echo "You should be able to test with: aws --profile ${AWS_PROFILE} sts get-caller-identity"
	echo "Can also set your profile with export AWS_PROFILE=${AWS_PROFILE}"
else
	# Extract generated temp creds and echo - thinking is you want to set manually on the host and we are in a "docker container run" env
	aws_access_key_id=$(cat ${creds_file_path} | grep access_key_id | cut -f2 -d'=')
	aws_secret_access_key=$(cat ${creds_file_path} | grep aws_secret_access_key | cut -f2 -d'=')
	aws_session_token=$(cat ${creds_file_path} | grep aws_session_token | cut -f2 -d'=')

	echo "[${AWS_PROFILE}]"
	echo "aws_access_key_id = ${aws_access_key_id}"
	echo "aws_secret_access_key = ${aws_secret_access_key}"
	echo "aws_session_token = ${aws_session_token}"
	echo "region = ${AWS_REGION}"
fi
