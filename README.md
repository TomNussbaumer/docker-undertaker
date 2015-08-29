# docker-undertaker

Undertaker is a Garbage Collector for Docker Containers and Images.

It will remove containers which don't match any exclusion rule and are stopped longer than the configurated period of time (default: 3600 seconds = 1 hour). Images are removed if no excluded or active container references them anymore.

## Main Use Case

Undertaker is meant for hosts with an extreme fluctuation of images and containers. Normally this are not your production machines, but developer, test and build hosts.

## Important Notices

  * __Undertaker will destroy Data Volumes with the Containers.__ Make sure you get your exclusions set up correctly!
  * If you run Undertaker not within the provided container, make sure that GNU grep is installed.

## Usage

```shell
USAGE: ./undertaker [OPTIONS]

options:

  -i pattern   exclude matching images from destruction
  -c pattern   exclude matching containers from destruction
  -e           show processed exclude lists
  -E           show excluded containers and images
  -w seconds   wait time in seconds before destroying stopped containers
               (default: 3600)
  -x           PERFORM cleanup - for safety reasons no container or image
               removal is performed automatically unless you specify this flag
  -v           show version info and exit

NOTE: exclusion patterns will be processed with grep against the
      corresponding lists

environment variables:

  TRACE                 turn on line-level tracing
  UT_IMAGE_EXCLUDES     file containing image excludes
                        (default: /etc/undertaker/image-excludes)
  UT_CONTAINER_EXCLUDES file containing container excludes
                        (default: /etc/undertaker/container-excludes)
  UT_STILLWARM_SECONDS  how long will be containers ignored after exit,
                        same as option -w (default: 3600)
```

## Running the Docker Container

Undertaker requires access to the docker socket to fullfill it's job, so you'll need to bind mount the socket to the container like this:

```shell
# replace X.Y.Z with fitting version (example: 0.3.0)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock tnussb/undertaker:X.Y.Z ... some options here
```

Undertaker is best used for one-shots: generate a container, run it once and destroy it. For automation add it as cron job.

## Testing Exclusions

Exclusion rules can be best tested when you run the Undertaker container like this:

```shell
# -e    ... show active exclusions
# -E    ... show excluded containers and images
# -w 0  ... don't ignore any stopped containers

# make sure you don't use the flag -x!  ... and replace X.Y.Z with fitting version
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock tnussb/undertaker:X.Y.Z -eE -w 0 \
  -c my-excluded-container1 \
  -c my-excluded-container2 \
  -i my-included-image1 \
  -i my-included-image2
```

## Crafting Exclusions

Container and image excludes are processed with grep, against a list of possible targets. Each line of the target list starts with the long id followed by a space and name.

examples of target lists:

```
## container target list

12b4b301124823882bc25296176b618066cc6feb4ee62b8e6cf7bac6cc0b9e79 a-test3-cont
819be7d134f052e035052e2c76d8c73a5416e0f16e04254d5537873e0781befc test1-container
987ebebdbec2f4a67fdd0e86250c1576a20e847ca8d31f652e3826ce07c00233 test2-cont
aff4ca67e1c50952b37819f2223505daa2ceae55c691779f359f893c6f1f6df2 test3-cont

## image target list

0357abd8c386ac423438e10effb00c16b9de4208cbc1f0af584a5b5cf444593d tnussb/undertaker:0.3.0
31f630c65071968699d327be41add2e301d06568a4914e1aa67c98e1db34a9d8 alpine:latest
5bd56d818842eb61485761c291fb1393b0a6fb827ad4ff21223ae026df9c7203 gliderlabs/alpine:3.2
8c2e06607696bd4afb3d03b687e361cc43cf8ec1a4a725bc96e39f05ba97dd55 busybox:latest
```

Here are some exclusion strings and what they will match:

```
-c test    # will match all (substring is part of each name)
-c 'ner$'  # matches test1.container (ends with 'ner')
-c ' test' # maches test1-container, test2-cont and test3-cont (NOTE the space!)
-c '3'     # STUPID one: matches all
-c '^12b4b3011248' # when matching short ids DONT FORGET the caret (^) to match
                   # ids starting with the given digits !
```

## Handling large exclusion lists

If you need to handle a large list of exclusions you can either mount your own files to `/etc/undertaker/image-excludes` and `container-excludes` or mount a Data Volume to `/etc/undertaker`.

