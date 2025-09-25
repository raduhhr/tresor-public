#!/bin/bash

# Folder names (anything: services, categories, dates, etc.)
folders="mc-server mc-frontend uptime-kuma grafana jellyfin syncthing filebrowser portainer prometheus traefik cf-tunnel landing-cv"

# File names to touch inside each folder (e.g. playbooks, config templates, etc.)
files=("deploy.yml" "start.yml" "stop.yml" "update.yml" "remove.yml" "status.yml" "restart.yml")

# create folders and drop files in each
for folder in $folders; do
    mkdir -p "$folder"
    echo "Creating files in $folder"

    for file in "${files[@]}"; do
        touch "$folder/$file"
    done
done

