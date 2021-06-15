#!/bin/bash
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    if [ "$2" = "-db" ]; then	
        echo "Backuping DB..."
        ./backup_restore.sh
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
fi
