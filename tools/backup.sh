#!/bin/bash

#Backup db into peon.sql file and replace heroku db with new backup
#backup db
echo "Creating a dump of local DB..."
pg_dump -h 172.17.0.2 -p 5432 -U postgres -s -O -F p -b -v -f "./peon.sql" peon
if [ $? -eq 0 ]; then
    #reset db at heroku
    heroku pg:reset postgresql-rigid-10499 --app myjobkeeper --confirm myjobkeeper
    #restore db
    echo "Restoring dump to Heroku..."
    psql -h ec2-54-217-234-157.eu-west-1.compute.amazonaws.com -p 5432 -U lkabdjtptaesng -d de61oteg9ukstn -f "./peon.sql"
else
    exit 1
fi