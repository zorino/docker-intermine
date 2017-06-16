#!/bin/bash

export MINE_NAME=yeastmine
export DATA_DIR=/path/to/data
export INTERMINE_DIR=/path/to/intermine
docker-compose -p $MINE_NAME up
