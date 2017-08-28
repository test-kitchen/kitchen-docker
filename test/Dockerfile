FROM centos:6
RUN yum clean all && \
    yum install -y sudo openssh-server openssh-clients which curl htop && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    mkdir -p /var/run/sshd && \
    useradd -d /home/<%= @username %> -m -s /bin/bash <%= @username %> && \
    echo <%= "#{@username}:#{@password}" %> | chpasswd && \
    echo '<%= @username %> ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/<%= @username %>/.ssh && \
    chown -R <%= @username %> /home/<%= @username %>/.ssh && \
    chmod 0700 /home/<%= @username %>/.ssh && \
    touch /home/<%= @username %>/.ssh/authorized_keys && \
    chown <%= @username %> /home/<%= @username %>/.ssh/authorized_keys && \
    chmod 0600 /home/<%= @username %>/.ssh/authorized_keys && \
    curl -L https://www.chef.io/chef/install.sh | bash && \
    echo '<%= IO.read(@public_key).strip %>' >> /home/<%= @username %>/.ssh/authorized_keys && \
    true
