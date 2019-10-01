# Purpose
Wrap [onelogin](https://github.com/onelogin/onelogin-aws-cli-assume-role) jar in a docker image so you do not require a local JRE installation



# Build image
```
# Build local docker image - will include the jar and a script, will build image based on your USER env var value
make build-image

# Show image
make list-image
```



# Run options - using this repo
I'm using [direnv](https://direnv.net/) with a .envrc file, this file will look like this
```
# AWS context
export AWS_PROFILE=mfa
export AWS_REGION=us-east-2

# Email that onelogin/aws integration is set for - You will be prompted for a onelogin password and a MFA based on this
export EMAIL=pat.mcgrath@nearform.com

# Some of these are sensitive and should not be committed to source control
export ONELOGIN_APP_ID=REDACTED
export ONELOGIN_CLIENT_ID=REDACTED
export ONELOGIN_CLIENT_SECRET=REDACTED
export ONELOGIN_SUB_DOMAIN=REDACTED

# Optional map of accounts - Will display before run, makes it easier to pick one if multiple choices
export AWS_ACCOUNT_MAP='111111111111 ted\n222222222222 toe'
```

If not using direnv, you can just do exports in the shell or add to your .bashrc as above


## Option 1 Run where some questions asked and it echos temp creds to screen
- Can you trust the image and jar file ? If you think NO - you probably already have sensitive credentials in your ~/.aws/credentials file
- Will ask you for your onelogin password and MFA token for the same
```
make run
```


## Option 2 Run where some questions asked and it updates your ~/.aws/credentials file directly
- Can you trust the image and jar file ? If you think YES
- Will ask you for your onelogin password and MFA token for the same
- This option will *update your ~/.aws/credentials file* directly as it does a volume mount for the container run
	- Assumes ~/.aws directory exists on host
	- Will create file with correct ownership, see USER_Id docker build arg
```
make run-mutate-my-creds-file

# Show updated file
cat ~/.aws/credentials
```



# Optional AWS account map
If you set the AWS_ACCOUNT_MAP env var, it will be echoed on screen

Makes sense to create profiles based on the map so you can access many at the same time
```
# Create a ted profile
make run-mutate-my-creds-file AWS_PROFILE=ted

# See profile
cat ~/.aws/credentials

# Use profile
export AWS_PROFILE=ted

# Lets check the account
aws sts get-caller-identity | jq -r .Account
```



# Profile alias options
## Option where you have cloned the repo and added a .envrc file in the same repo
Can add this to your .bashrc
- Alter path to wherever you cloned the repo
- Note we use a () to use a subshell so the env vars will not persist
- This relies on a .envrc file which we use with direnv - need to evaluate in the subshell
	- This has a default AWS_PROFILE but if you want to set for multiple profiles can set the AWS_PROFILE before calling this alias
	- WARNING - You could overwrite an existing profile if this is the case
```
alias renew-onelogin-aws='set -e; pushd . > /dev/null; existing_profile=$AWS_PROFILE; cd ~/oss/github.com/pmcgrath/onelogin-mfa-profile-generator; (eval "$(cat .envrc)"; [[ ! -z $existing_profile ]] && export AWS_PROFILE=$existing_profile; make run-mutate-my-creds-file); popd > /dev/null'
```

Usage
```
renew-onelogin-aws
```

## Option where you have a .envrc file in a different directory
Can add this to your .bashrc
- Alter path to wherever you have the .envrc file
- Note we use a () to use a subshell so the env vars will not persist
- This relies on a .envrc file which we use with direnv - need to evaluate in the subshell
	- This has a default AWS_PROFILE but if you want to set for multiple profiles can set the AWS_PROFILE before calling this alias
	- WARNING - You could overwrite an existing profile if this is the case
```
alias renew-onelogin-aws='
set -e

pushd . > /dev/null
existing_profile=$AWS_PROFILE

# ****** Change me
cd /some-directory-with-a-envrc-file

(eval "$(cat .envrc)"
[[ ! -z $existing_profile ]] && export AWS_PROFILE=$existing_profile
docker container run \
	-ti \
	--rm \
	--name onelogin \
        --env AWS_REGION=${AWS_REGION} \
        --env AWS_PROFILE=${AWS_PROFILE} \
        --env EMAIL=${EMAIL} \
        --env ONELOGIN_APP_ID=${ONELOGIN_APP_ID} \
        --env ONELOGIN_CLIENT_ID=${ONELOGIN_CLIENT_ID} \
        --env ONELOGIN_CLIENT_SECRET=${ONELOGIN_CLIENT_SECRET} \
        --env ONELOGIN_SUB_DOMAIN=${ONELOGIN_SUB_DOMAIN} \
        --env AWS_ACCOUNT_MAP="${AWS_ACCOUNT_MAP}" \
        --user "$(id -u):$(id -g)" \
        --volume ${HOME}/.aws:/onelogin/.aws \
        pmcgrath/onelogin-mfa-profile-generator:1.0
)

popd > /dev/null
'
```

Usage
```
renew-onelogin-aws
```

## Option where you have exported env vars
Can add this to your .bashrc
- Can add the exports to your .bashrc or set before calling
```
alias renew-onelogin-aws='
docker container run \
	-ti \
	--rm \
	--name onelogin \
        --env AWS_REGION=${AWS_REGION} \
        --env AWS_PROFILE=${AWS_PROFILE} \
        --env EMAIL=${EMAIL} \
        --env ONELOGIN_APP_ID=${ONELOGIN_APP_ID} \
        --env ONELOGIN_CLIENT_ID=${ONELOGIN_CLIENT_ID} \
        --env ONELOGIN_CLIENT_SECRET=${ONELOGIN_CLIENT_SECRET} \
        --env ONELOGIN_SUB_DOMAIN=${ONELOGIN_SUB_DOMAIN} \
        --env AWS_ACCOUNT_MAP="${AWS_ACCOUNT_MAP}" \
        --user "$(id -u):$(id -g)" \
        --volume ${HOME}/.aws:/onelogin/.aws \
        pmcgrath/onelogin-mfa-profile-generator:1.0
'
```

Usage
```
renew-onelogin-aws
```



# Create image with hard coded env vars
You could also create an image as another layer on top of this image

Just need to use a local docker file to create a local image - should not push to dockerhub or a shared registry

See the Dockerfile.local file, you would need to set some of the values

Build with
```
docker image build --file Dockerfile.local --tag onelogin-mfa-profile-generator:1.0 .
```

Can then use as follows
```
export AWS_PROFILE=mfa
docker container run \
	-ti \
	--rm \
	--name onelogin \
        --env AWS_PROFILE=${AWS_PROFILE} \
        --user "$(id -u):$(id -g)" \
        --volume ${HOME}/.aws:/onelogin/.aws \
        onelogin-mfa-profile-generator:1.0
```
