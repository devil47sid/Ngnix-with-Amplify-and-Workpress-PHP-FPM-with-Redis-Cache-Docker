FROM ubuntu:16.04
MAINTAINER Siddharth Mishra

#Adding letsencrypt repository
RUN apt-get install software-properties-common -y
RUN apt-get update -y

#Install certbot
RUN apt-get install certbot -y

#Install Nginx plugin for Certbot
RUN apt-get install python-certbot-nginx -y
