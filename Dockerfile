# Wanted to base on an offical JRE, seems JREs are a thing of the past and you can now use jlink with modules to create a slim runtime
# See	https://docs.oracle.com/javase/9/tools/jlink.htm
#	https://stackoverflow.com/questions/53375613/why-is-the-java-11-base-docker-image-so-large-openjdk11-jre-slim
#	https://stackoverflow.com/questions/53669151/java-11-application-as-lightweight-docker-image/53669152#53669152
FROM        azul/zulu-openjdk-alpine:11 as jre-builder

# Build modules distribution - what we need
# Have jused jdeps to get the module list, see https://www.baeldung.com/jlink, so did a jdeps against the jar
RUN         jlink \
            	--verbose \
            	--add-modules \
            	java.base,java.logging,java.management,java.naming,java.security.jgss,java.xml \
            	--compress 2 \
            	--strip-debug \
            	--no-header-files \
            	--no-man-pages \
            	--output /opt/jre


# Final image
FROM        alpine:3.10

ENV         PATH = "$PATH:/opt/jre/bin"
COPY        --from=jre-builder /opt/jre /opt/jre

WORKDIR     /onelogin

# Get jar - we have no wget in this image, so lets use curl, lets also just take the latest version
RUN         wget -O onelogin-aws-cli.jar https://github.com/onelogin/onelogin-aws-cli-assume-role/blob/master/onelogin-aws-assume-role-cli/dist/onelogin-aws-cli.jar?raw=true

COPY        generate.sh .

# Ensure the /onelogin/.aws directory exists and the /onelogin directory is accesible, will use 777 so run can mount a volume and use a specific user so they have permissions
RUN         mkdir -p /onelogin/.aws && chmod -R 777 /onelogin

USER        nobody:nogroup

ENTRYPOINT  [ "./generate.sh" ]
