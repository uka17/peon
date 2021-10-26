#!/bin/bash

#Launch all needed things for development
tmux new -s dev -d
tmux split-window -v -t dev:0.0
tmux split-window -v -t dev:0.1
tmux send-keys -t dev:0.0 'docker start postgres' Enter
tmux send-keys -t dev:0.0 'docker start mongo' Enter
tmux send-keys -t dev:0.0 'cd ~/_code/peon/' Enter
tmux send-keys -t dev:0.0 'npm run dev-srv' Enter
tmux send-keys -t dev:0.1 'cd ~/_code/peon/' Enter
tmux send-keys -t dev:0.1 'npm run dev-api' Enter
tmux send-keys -t dev:0.2 'cd ~/_code/peon-web/' Enter
tmux send-keys -t dev:0.2 'npm run start' Enter
xdg-open http://localhost:9000
xdg-open https://trello.com/b/sWc07nUn/peon-web
tmux attach



