# Intermine on Docker

Docker-compose project to build an intermine container instance.
Forked from [zorino/docker-intermine](https://github.com/zorino/docker-intermine)

## Getting Started

### Prerequisities

Required software: ```docker``` & ```docker-compose```

### Quick install malariamine demo

1. Download this repository:
```shell
git clone https://github.com/gcornut/docker-intermine.git
```
2. Download intermine and setup a working malariamine instance (without any integrated data)
```shell
cd docker-intermine/malariamine-demo
./docker-configure-run.sh
```
3. *(Optional)* Integrate demo data into malariamine (only once the previous script has finished its setup)
```shell
./malariamine-integrate-data.sh
```
4. Open http://localhost:8080/malariamine to see the result

## Detailed usage

### Repository content

```
├── configs                            -> configuration files for intermine
├── docker-compose.yml                 -> docker compose configuration
├── Dockerfile.main                    -> intermine docker container configuration
├── Dockerfile.tomcat                  -> tomcat docker container configuration
├── malariamine-demo
│   ├── docker-configure-run.sh        -> script configuring and launching a malariamine demon container
│   └── malariamine-integrate-data.sh  -> script launching data integration inside malariamine demo container
├── README.md                          -> this file
└── scripts
    ├── intermine-entry.sh             -> startup script for intermine container
    ├── launch-bash.sh                 -> script launching a bash shell from within the intermine container
    └── sample-launch-docker.sh        -> sample script
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
