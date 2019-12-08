#!/bin/bash
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    if [ -n "$2" ] && [ "$z" -eq "-db"]; then	
    	./tools/backup_restore.sh
    fi
    git status
    git add .
    git commit -m "$1"
    git push
fi
