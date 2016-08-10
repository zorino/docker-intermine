#!/bin/bash
set -e

# Setup a new intermine
# Steps:
# - Download intermine git repository
# - Create MalariaMine
# - Configure MalariaMine (project.xml)
# - Prepare MalariaMine data

# Delete docker malariamine containers:
#   $ docker rm malariamine_webapp_1 malariamine_data_1 malariamine_postgres_1
# Delete docker malariamine image:
#   $ docker rmi -f malariamine_webapp

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export INTERMINE_DIR=$DIR/intermine
export MINE_NAME=malariamine

# clone intermine repo
if [ ! -d "$INTERMINE_DIR" ]; then
  git clone https://github.com/intermine/intermine.git $INTERMINE_DIR
else
  git --work-tree=$INTERMINE_DIR --git-dir=$INTERMINE_DIR/.git pull
fi

# malariamine project dir
MINE_DIR=$INTERMINE_DIR/malariamine
[ -d "$MINE_DIR" ] || {
  # create mine
  cd $INTERMINE_DIR
  $INTERMINE_DIR/bio/scripts/make_mine MalariaMine
  cd -
  # configure mine
  cp $INTERMINE_DIR/bio/tutorial/project.xml $MINE_DIR/
  sed -i 's/DATA_DIR/\/data/g' $MINE_DIR/project.xml
}

# prepare malaria data from archive
export DATA_DIR=$DIR/data
[ -d "$DATA_DIR" ] || {
  mkdir $DATA_DIR
  cp $INTERMINE_DIR/bio/tutorial/malaria-data.tar.gz $DATA_DIR/
  tar xvf $DATA_DIR/malaria-data.tar.gz -C $DATA_DIR
}

# launch docker container
docker-compose -p $MINE_NAME up
