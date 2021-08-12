#!/bin/bash
set -e
export PGPASSWORD=255320

#Create initial docker containers (postgres and mongodb), apply initial db structure to postgres
echo "Create network..."
docker network create -d bridge --subnet=172.18.0.0/16 peon-network
echo "Launching postgres container..."
docker run --network=peon-network --ip=172.18.0.2 --name postgres -e POSTGRES_PASSWORD=$PGPASSWORD -d postgres
echo "Applying dump..."
sleep 3
psql -h 172.18.0.2 -p 5432 -U postgres -c 'create database peon'
psql -h 172.18.0.2 -p 5432 -U postgres -d peon -f "./peon.sql"
echo "Launching mongo container..."
docker run --network=peon-network --ip=172.18.0.3 --name mongo -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD=$PGPASSWORD -d mongo
