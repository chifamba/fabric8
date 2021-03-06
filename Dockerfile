FROM ubuntu
#FROM centos

# telnet is required by some fabric command. without it you have silent failures
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade      && ls
RUN apt-get install -y sudo
RUN apt-get install -y ssh
RUN apt-get install -y unzip
RUN apt-get install -y telnet
RUN apt-get install -y openjdk-7-jdk
RUN apt-get install -y maven
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties

# install SSH server so we can connect multiple times to the container
RUN apt-get install -y supervisor 
RUN apt-get install -y git
RUN mkdir /var/run/sshd && mkdir -p /var/log/supervisor

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# enable no pass and speed up authentication
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/;s/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# enabling sudo group
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
# enabling sudo over ssh
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/jre

ENV FABRIC8_KARAF_NAME root
ENV FABRIC8_BINDADDRESS 0.0.0.0
ENV FABRIC8_PROFILES docker

# add a user for the application, with sudo permissions
RUN groupadd wheel
RUN useradd -m fabric8 ; echo fabric8: | chpasswd ; usermod -a -G wheel fabric8

# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile


WORKDIR /home/fabric8

#RUN wget -nv -O fabric8.zip http://central.maven.org/maven2/io/fabric8/fabric8-karaf/1.1.0.CR2/fabric8-karaf-1.1.0.CR2.zip
ADD fabric8-karaf-1.1.0.CR2.zip /home/fabric8/fabric8.zip
RUN chmod ugo+rw /home/fabric8/fabric8.zip

USER fabric8

RUN unzip  /home/fabric8/fabric8.zip 

#RUN mv fabric8-karaf-1.1.0-SNAPSHOT fabric8-karaf
RUN mv fabric8-karaf-1.1.0.CR2 fabric8-karaf
RUN rm fabric8.zip
#RUN chown -R fabric8:fabric8 fabric8-karaf

WORKDIR /home/fabric8/fabric8-karaf/etc

# lets remove the karaf.name by default so we can default it from env vars
RUN sed -i '/karaf.name=root/d' system.properties 

RUN echo bind.address=0.0.0.0 >> system.properties
RUN echo fabric.environment=docker >> system.properties
RUN echo zookeeper.password.encode=true >> system.properties

# lets remove the karaf.delay.console=true to disable the progress bar
RUN sed -i '/karaf.delay.console=true/d' config.properties 
RUN echo karaf.delay.console=false >> config.properties

# lets add a user - should ideally come from env vars?
RUN echo >> users.properties 
RUN echo admin=admin,admin >> users.properties 

# lets enable logging to standard out
#RUN echo log4j.rootLogger=INFO, stdout, osgi:* >> org.ops4j.pax.logging.cfg 

WORKDIR /home/fabric8/fabric8-karaf

# ensure we have a log file to tail 
RUN mkdir -p data/log
RUN echo >> data/log/karaf.log

WORKDIR /home/fabric8

#RUN curl --silent --output startup.sh https://raw.githubusercontent.com/fabric8io/fabric8-docker/c9583367e3da4ca7adfc535107b9dc9ce07589d0/startup.sh

EXPOSE 22 1099 2181 8101 8181 9300 9301 44444 61616 

USER root



CMD ["/usr/bin/supervisord"]
