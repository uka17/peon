#!/bin/bash

#Make a commit to repository with provided comment, if key -db was provided - backup db and refresh it at Heroku
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    if [ "$2" = "-db" ]; then	
        echo "Backuping DB..."
        ./backup_restore.sh        
    fi
    if [ $? -eq 0 ]; then
        echo "Pushing to git..."
        git status
        git add .
        git commit -m "$1"
        git push      
    else
        exit 1
    fi            
fi
