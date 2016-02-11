# Intermine on Docker

Docker-compose project to build an intermine container instance.

## Getting Started

### Prerequisities

docker and docker-compose

### Installing

```
git clone https://zorino@bitbucket.org/zorino/centos-intermine.git
cd centos-intermine
docker-compose up
```

#### Bootstrap the demo intermine database (malariamine)

```
docker exec centosintermine_intermine-webapp_1 bootstrap-intermine-demo.sh
xdg-open http://localhost:8080/malariamine
```

#### Bootstrap an existing intermine database

COMING SOON
