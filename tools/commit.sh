#!/bin/bash
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    if [ "$2" = "-db" ]; then	
        echo "Backuping DB..."
    	./backup_restore.sh
    fi
    echo "Pushing to git..."
    git status
    git add .
    git commit -m "$1"
    git push
fi
