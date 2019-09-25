#!/bin/bash
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    git status
    ./tools/backup_restore.sh
    git add .
    git commit -m "$1"
    git push
fi
