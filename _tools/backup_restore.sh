#!/bin/bash
pg_dump -h 172.17.0.2 -p 5432 -U postgres -F c -b -v -f "./peon.backup" peon
pg_restore -h ec2-54-247-85-251.eu-west-1.compute.amazonaws.com -p 5432 -U nvaaifkvsfzpbc -d ddckjterc9mj8r -v "./peon.backup"