#!/bin/bash

# Create user
echo "Running as $UID, $GID"
useradd -u ${UID} -o -m lab
usermod -g ${GID} lab
export HOME=/home/lab

# Switch to user
exec su -l lab -c "jupyter lab --ip 0.0.0.0 --port 8888 --no-browser --NotebookApp.token='' --NotebookApp.password=''"

