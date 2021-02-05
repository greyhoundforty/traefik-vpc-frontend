#!/usr/bin/env bash

## Update machine
DEBIAN_FRONTEND=noninteractive apt -qqy update
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade

## Install Docker 
DEBIAN_FRONTEND=noninteractive apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https ca-certificates curl gnupg-agent software-properties-common openssl

## Register Docker package registry
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
DEBIAN_FRONTEND=noninteractive add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

## Refresh package udpates and install Docker
DEBIAN_FRONTEND=noninteractive apt -qqy update
DEBIAN_FRONTEND=noninteractive apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install docker-ce docker-ce-cli containerd.io

## Setup containers 
## Create installation directory for Wiki.js
mkdir -p /etc/wiki

## Generate DB secret
openssl rand -base64 32 > /etc/wiki/.db-secret

## Create internal docker network
docker network create wikinet

## Create data volume for PostgreSQL
docker volume create pgdata

## Create the containers
docker create --name=db -e POSTGRES_DB=wiki -e POSTGRES_USER=wiki -e POSTGRES_PASSWORD_FILE=/etc/wiki/.db-secret -v /etc/wiki/.db-secret:/etc/wiki/.db-secret:ro -v pgdata:/var/lib/postgresql/data --restart=unless-stopped -h db --network=wikinet postgres:11
docker create --name=wiki -e LETSENCRYPT_DOMAIN=${fqdn} -e LETSENCRYPT_EMAIL=${email} -e SSL_ACTIVE=1 -e DB_TYPE=postgres -e DB_HOST=db -e DB_PORT=5432 -e DB_PASS_FILE=/etc/wiki/.db-secret -v /etc/wiki/.db-secret:/etc/wiki/.db-secret:ro -e DB_USER=wiki -e DB_NAME=wiki -e UPGRADE_COMPANION=1 --restart=unless-stopped -h wiki --network=wikinet -p 80:3000 -p 443:3443 requarks/wiki:2
docker create --name=wiki-update-companion -v /var/run/docker.sock:/var/run/docker.sock:ro --restart=unless-stopped -h wiki-update-companion --network=wikinet requarks/wiki-update-companion:latest

## Update firewall rules
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

docker start db
docker start wiki
docker start wiki-update-companion