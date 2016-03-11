# Intermine on Docker

Docker-compose project to build an intermine container instance.

## Getting Started

### Prerequisities

docker and docker-compose

### Install malariamine demo

This will build the malariamine demo project from 3 containers.

```
git clone https://zorino@bitbucket.org/zorino/docker-intermine.git
cd docker-intermine
docker-compose -p malariamine up
xdg-open http://localhost:8088/malariamine
```

### Install a Mine from postgres dump

To bootstrap an existing container, you will need a directory that you will mount on the data volume container - as the volumes directive in the docker-compose file shows [malariamine folder] :

```
data:
  image: centos:centos7
  volumes:
    - ./malariamine:/data
```

The host directory [malariamine] needs :

* [intermine/malariamine/] : your mine project repository inside intermine/ project's folder :
    * see https://github.com/yeastgenome/intermine
    * see https://github.com/FlyMine/intermine
* [.intermine/malariamine.properties] : intermine properties
* [intermine-psql-dump/latest.dump] : postgres dump to be loaded


Example of a directory for yeastmine :
```
yeastmine-prod1/
├── catalina.logs
├── *intermine*
│   ├── bio
│   ├── biotestmine
│   ├── .classpath
│   ├── config
│   ├── flymine
│   ├── .git
│   ├── .gitignore
│   ├── git\_master\_diffs
│   ├── humanmine
│   ├── imbuild
│   ├── intermine
│   ├── LICENSE
│   ├── LICENSE.LIBS
│   ├── malariamine
│   ├── readme\_kk
│   ├── README.md
│   ├── RELEASE_NOTES
│   ├── testmodel
│   ├── .travis.yml
│   ├── xenmine
│   └── *yeastmine*
├── *.intermine*
│   └── yeastmine.properties
└── *intermine-psql-dump*
    ├── *latest.dump* -> yeastmine-prod1.2016-01-11.dump.final
    ├── yeastmine-prod1.2016-01-11.dump.final -> yeastmine-prod1-dump-Jan-11-2016.final
    └── yeastmine-prod1-dump-Jan-11-2016.final
```

Launch the containers for yeastmine :

```
docker-compose -p yeastmine up
# wait for the postgre database to restore ..
xdg-open http://localhost:8088/yeastmine
```
