#!/bin/bash

#backup db
pg_dump -h 172.17.0.2 -p 5432 -U postgres -O -F p -b -v -f "./peon.sql" peon
#reset db at heroku
heroku pg:reset postgresql-rigid-10499 --app myjobkeeper --confirm myjobkeeper
#restore db
psql -h ec2-54-217-234-157.eu-west-1.compute.amazonaws.com -p 5432 -U lkabdjtptaesng -d de61oteg9ukstn -f "./peon.sql"