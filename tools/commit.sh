#!/bin/bash
if [ -z "$1" ]; then
    echo "Error: Provide a comment for commit"
else
    ./tools/backup_restore.sh
    git status
    git add .
    git commit -m "$1"
    git push
fi
