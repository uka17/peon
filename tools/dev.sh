#!/bin/bash
tmux new -s dev -d
tmux split-window -v -t dev:0.0
tmux send-keys -t dev:0.0 'docker start postgres' Enter
tmux send-keys -t dev:0.0 'node ~/_code/peon/server.js' Enter
tmux send-keys -t dev:0.1 'cd ~/_code/peon-web/' Enter
tmux send-keys -t dev:0.1 'npm run start' Enter
xdg-open http://localhost:9000
xdg-open https://trello.com/b/sWc07nUn/peon-web
tmux attach



