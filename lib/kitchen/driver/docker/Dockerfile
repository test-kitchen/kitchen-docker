FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -y openssh-server

RUN mkdir /var/run/sshd

RUN useradd -d /home/kitchen -m -s /bin/bash kitchen

RUN echo kitchen:kitchen | chpasswd
