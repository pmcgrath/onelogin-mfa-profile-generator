# Local user's Ids
GROUP_ID = $(shell id -g)
USER_ID = $(shell id -u)

# Version
VERSION = 1.0

# Default to env var value, but allow override via the make target invocation
AWS_PROFILE = $(shell echo $$AWS_PROFILE)

# Image
IMAGE_NAME = onelogin-mfa-profile-generator
IMAGE = ${USER}/${IMAGE_NAME}
TAGGED_IMAGE = ${IMAGE}:${VERSION}


# Targets
# Image targets
build-image:
	@# Build local docker image
	docker image build --tag ${TAGGED_IMAGE} .


push-image:
	@# Push image, assumes you have are already logged in to dockerhub
	@docker image push ${TAGGED_IMAGE}


list-image:
	@docker image ls ${IMAGE}


# Run targets
run:
	@# Run will use env vars to pass data to generate script rather than args, see readme.md for context
	@docker container run \
		-ti \
		--rm \
		--name ${IMAGE_NAME} \
		--env AWS_REGION=${AWS_REGION} \
		--env AWS_PROFILE=${AWS_PROFILE} \
		--env EMAIL=${EMAIL} \
		--env ONELOGIN_APP_ID=${ONELOGIN_APP_ID} \
		--env ONELOGIN_CLIENT_ID=${ONELOGIN_CLIENT_ID} \
		--env ONELOGIN_CLIENT_SECRET=${ONELOGIN_CLIENT_SECRET} \
		--env ONELOGIN_SUB_DOMAIN=${ONELOGIN_SUB_DOMAIN} \
		--env AWS_ACCOUNT_MAP="${AWS_ACCOUNT_MAP}" \
		${TAGGED_IMAGE}


run-mutate-my-creds-file:
	@# Run will use env vars to pass data to generate script rather than args, see readme.md for context
	@# This time we mount the current users ~/.aws directory so it is updated directly, hence we need the --user
	@#	Assuming current user is 1000 which matches the image "somebody" user
	@# Your brave enough to do this - do you trust the docker image and the jar file ?
	@docker container run \
		-ti \
		--rm \
		--name ${IMAGE_NAME} \
		--env AWS_REGION=${AWS_REGION} \
		--env AWS_PROFILE=${AWS_PROFILE} \
		--env EMAIL=${EMAIL} \
		--env ONELOGIN_APP_ID=${ONELOGIN_APP_ID} \
		--env ONELOGIN_CLIENT_ID=${ONELOGIN_CLIENT_ID} \
		--env ONELOGIN_CLIENT_SECRET=${ONELOGIN_CLIENT_SECRET} \
		--env ONELOGIN_SUB_DOMAIN=${ONELOGIN_SUB_DOMAIN} \
		--env AWS_ACCOUNT_MAP="${AWS_ACCOUNT_MAP}" \
		--user "${USER_ID}:${GROUP_ID}" \
		--volume ${HOME}/.aws:/onelogin/.aws \
		${TAGGED_IMAGE}
