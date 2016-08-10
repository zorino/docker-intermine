# Intermine on Docker

Docker-compose project to build an intermine container instance.
Forked from [zorino/docker-intermine](https://github.com/zorino/docker-intermine)

## Getting Started

### Prerequisities

docker and docker-compose

### Quick install malariamine demo

This will build the malariamine demo project from 3 containers.

```
git clone https://github.com/gcornut/docker-intermine.git
cd docker-intermine/malariamine-demo
./docker-configure-run.sh
# Once tomcat is running :
./malariamine-build.sh
xdg-open http://localhost:8088/malariamine
```

## Detailed usage

### Repository content

```
├── configs                        -> configuration files for intermine
├── docker-compose.yml             -> docker compose configuration
├── Dockerfile.webapp              -> intermine webapp docker container configuration
├── malariamine-demo
│   ├── docker-configure-run.sh    -> script configuring and launching a malariamine demon container
│   └── malariamine-build.sh       -> script launching data integration inside malariamine demo container
├── README.md                      -> this file
└── scripts
    ├── intermine-entry.sh         -> startup script for intermine webapp container
    ├── launch-bash.sh             -> script launching a bash shell from within the intermine webapp container
    └── sample-launch-docker.sh    -> sample script
```

### Intermine container configuration

To create an all-new intermine instance, take example on the scripts inside ```malariamine-demo```.

To deploy an existing custom intermine instance, you can take example on the ```scripts/sample-launch-docker.sh``` script.
Three environment variables are required to set up a new intermine instance:
- INTERMINE_DIR: the intermine git repository (location on your machine)
- DATA_DIR: the directory containing your intermine instance data (location on your machine)
- MINE_NAME: the intermine instance name (example: malariamine, yeastmine, etc.)

### Restore intermine from dump

Once you have set up your intermine instance, you can restore it from a postgresql dump.

Place your latest postgresql dump file  in your ```DATA_DIR``` directory with the name ```latest.dump``` and start the docker container. On startup, the restoring should fire automatically.
