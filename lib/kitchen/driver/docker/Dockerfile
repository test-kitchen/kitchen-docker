FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -y sudo openssh-server

RUN mkdir /var/run/sshd

RUN useradd -d /home/kitchen -m -s /bin/bash kitchen

RUN echo kitchen:kitchen | chpasswd

RUN echo 'kitchen ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo '127.0.0.1 localhost.localdomain localhost' >> /etc/hosts
