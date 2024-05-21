#!/bin/bash
#

sudo resolvectl dns ens3 1.1.1.1
sudo hostnamectl hostname docker.paranoidworld.es

sudo apt install -y cloud-guest-utils
sudo growpart /dev/vda 1
sudo apt update -y
sudo apt install -y ca-certificates curl
sudo apt install -y python3-flask
sudo mkdir -p /apps/wiremock
sudo curl https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.5.4/wiremock-standalone-3.5.4.jar -o /apps/wiremock/wiremock.jar
