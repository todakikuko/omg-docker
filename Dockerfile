#
# Base
#

FROM ubuntu:16.04
MAINTAINER todakikuko kikuko.toda@mrtaddy.com

RUN apt-get update -y
RUN chmod go+w,u+s /tmp

# package
RUN apt-get install openssh-server zsh tmux build-essential -y
RUN apt-get install wget unzip curl tree grep bison libssl-dev openssl zlib1g-dev -y 
# "libssl-dev openssl zlib1g-dev" need to rbenv and pyenv
RUN apt-get install git mercurial gettext libncurses5-dev nginx libperl-dev python-dev python3-dev ruby-dev lua5.2 liblua5.2-dev luajit libluajit-5.1 libpng-dev libjpeg-dev  libxslt-dev libmcrypt-dev re2c bison libxml2-dev libjpeg8-dev libreadline6-dev libtidy-dev libxslt1-dev bzip2 libbz2-dev libcurl4-openssl-dev autoconf qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x imagemagick -y

# sshd config
RUN sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd
RUN mkdir /var/run/sshd

# user
RUN echo 'root:root' |chpasswd
RUN useradd -m todakikuko \
    && echo "todakikuko ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo 'todakikuko:todakikuko' | chpasswd

USER todakikuko
WORKDIR /home/todakikuko
ENV HOME /home/todakikuko

# ssh
RUN mkdir .ssh
RUN chmod 700 .ssh
ADD id_rsa /home/todakikuko/.ssh/id_rsa
ADD id_rsa.pub /home/todakikuko/.ssh/id_rsa.pub
USER root
RUN chown todakikuko /home/todakikuko/.ssh/id_rsa
RUN chown todakikuko /home/todakikuko/.ssh/id_rsa.pub
USER todakikuko

#
# Database
#

USER root
# SQLite
RUN apt-get install sqlite3 libsqlite3-dev -y
# client
RUN apt-get install mysql-client redis-tools postgresql-client mongodb-clients -y
USER todakikuko

#
# Programming Language
#

# Clang (3.5)
USER root
RUN apt-get install clang-3.5 -y
USER todakikuko

# Ruby (rbenv)
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN cd ~/.rbenv && src/configure && make -C src
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN ~/.rbenv/bin/rbenv install 2.2.4
RUN ~/.rbenv/bin/rbenv install 2.0.0-p247
RUN ~/.rbenv/bin/rbenv global 2.2.4

# Python (virtualenv)
USER root
RUN apt-get install python-pip -y
RUN pip install virtualenv
RUN pip install virtualenvwrapper
USER todakikuko
RUN echo 'export WORKON_HOME=$HOME/.virtualenvs' >> ~/.bashrc
RUN echo 'source `which virtualenvwrapper.sh`' >> ~/.bashrc

# Python (pyenv)
RUN git clone https://github.com/yyuu/pyenv.git ~/.pyenv
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
RUN echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc
RUN ~/.pyenv/bin/pyenv install 3.6.2
RUN ~/.pyenv/bin/pyenv install 2.7.13
RUN ~/.pyenv/bin/pyenv global 3.6.2

# Golang (1.8)
USER root
RUN wget https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.8.linux-amd64.tar.gz
RUN rm -f go1.8.linux-amd64.tar.gz
USER todakikuko
RUN echo 'export GOROOT="/usr/local/go"' >> ~/.bashrc
RUN echo 'export PATH="$GOROOT/bin:$PATH"' >> ~/.bashrc

# Node.js (nvm)
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
ENV NODE_VERSION 6.11.2
ENV NVM_DIR $HOME/.nvm
RUN . ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g gulp yo hubot coffee-script browserify phantomjs


# PHP
USER todakikuko
RUN git clone https://github.com/phpenv/phpenv.git  ~/.phpenv
RUN echo 'export PATH="$HOME/.phpenv/bin:$PATH"' >> ~/.bashrc
RUN git clone https://github.com/php-build/php-build.git ~/.phpenv/plugins/php-build
RUN echo 'eval "$(phpenv init -)"' >> ~/.bashrc

USER root
RUN /bin/bash -c "~/.phpenv/plugins/php-build/install.sh"
USER todakikuko
RUN /bin/bash -c "source ~/.bashrc"
RUN php-build 7.1.8  ~/.phpenv/versions/7.1.8
#RUN ~/.phpenv/bin/phpenv install 7.1.8
RUN ~/.phpenv/bin/phpenv global 7.1.8

COPY nginx.conf.txt /etc/nginx/nginx.conf
COPY mysql.cnf.txt /etc/mysql/conf.d/mysql.cnf

#
# Else
#

# volumes
USER todakikuko
RUN mkdir /home/todakikuko/works

# for ssh
USER root
EXPOSE 22 80
CMD ["/usr/sbin/sshd", "-D"]
