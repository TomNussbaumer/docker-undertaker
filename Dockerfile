################################################################################
#
# Undertaker - Garbage Collection for Docker Containers and Images
#
# (*) based on Alpine Linux due to its incredible small size
# (*) relies on the availability of the Docker binary at:
#       https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}
# (*) has to started with docker socket bind-mounted:
#       docker run --rm \
#              -v /var/run/docker.sock:/var/run/docker.sock \
#              tnussb/undertaker:3.2
# 
################################################################################
FROM gliderlabs/alpine:3.2

RUN DOCKER_VERSION="1.8.1" apk -U add bash curl \
 && curl -so /bin/docker https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION} \
 && chmod +x /bin/docker \
 && apk del curl \
 && rm /var/cache/apk/*

COPY ./undertaker /undertaker
COPY ./exclude-containers ./exclude-images /etc/undertaker/

## using CMD instead of entrypoint so we can override it is easily
CMD ["/undertaker"]
