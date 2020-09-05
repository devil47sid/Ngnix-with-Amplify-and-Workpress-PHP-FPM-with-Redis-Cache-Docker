FROM ubuntu:16.04
MAINTAINER Siddharth Mishra

#Adding letsencrypt repository
RUN sudo apt-get install software-properties-common -y
RUN sudo apt-get update -y

#Install certbot
RUN apt-get install certbot -y

#Install Nginx plugin for Certbot
RUN sudo apt-get install python-certbot-nginx -y
