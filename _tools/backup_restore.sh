#!/bin/bash
pg_dump -h 172.17.0.2 -p 5432 -U postgres -O -F p -b -v -f "./peon.sql" peon
#pg_restore -h ec2-54-247-85-251.eu-west-1.compute.amazonaws.com -p 5432 -U nvaaifkvsfzpbc -d ddckjterc9mj8r -v "./peon.backup"
psql -h ec2-54-217-234-157.eu-west-1.compute.amazonaws.com -p 5432 -U lkabdjtptaesng -d de61oteg9ukstn -f "./peon.sql"