#!/bin/bash

# # Copy config file  & samples
mkdir -p $HOME/.sparkmagic && cp /tmp/config.json $HOME/.sparkmagic/config.json

if [[ ${INCLUDE_NOTEBOOK_SAMPLES:-false} = true ]]
then
    cp -r /tmp/samples $HOME/samples
fi

# # Recreate .env for AWS access
# # THIS IS NOT SECURE WAY TO STORE ANYTHING!!
rm -f $HOME/.env
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> ${HOME}/.env
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ${HOME}/.env

# chown everything for user
chown -R lab:lab $HOME

# Switch to user
exec su -l lab -c "jupyter lab --ip 0.0.0.0 --port 8888 --no-browser --ServerApp.token='' --ServerApp.password=''"

