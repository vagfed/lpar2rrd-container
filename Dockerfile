FROM quay.io/centos/centos:8

######################################
# Build lpar2rrd image
######################################


# Temporary directory
ARG TEMP=/tmp/build
RUN mkdir $TEMP

# Define user
RUN useradd -c "LPAR2RRD user" -m lpar2rrd
COPY limits.txt $TEMP
RUN cat $TEMP/limits.txt >> /etc/security/limits.conf

# Enable Powertools
RUN dnf -y install dnf-plugins-core && \
	dnf -y upgrade && \
	dnf -y upgrade && \
	dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
	dnf config-manager --set-enabled powertools

# Install prereqs
RUN yum install -y perl rrdtool rrdtool-perl httpd mod_ssl
RUN yum install -y epel-release
RUN yum install -y perl-TimeDate perl-XML-Simple perl-XML-SAX perl-XML-LibXML perl-Env perl-CGI perl-Data-Dumper perl-LWP-Protocol-https perl-libwww-perl perl-Time-HiRes perl-IO-Tty
RUN yum install -y ed bc libxml2 sharutils

# Setup web server
RUN yum install -y httpd
COPY httpd.conf $TEMP
RUN cat $TEMP/httpd.conf >> /etc/httpd/conf/httpd.conf
RUN /usr/libexec/httpd-ssl-gencerts

# Install crontab
RUN yum -y install crontabs
RUN sed -i -e '/pam_loginuid.so/s/^/#/' /etc/pam.d/crond
RUN mkdir /var/adm/cron
RUN echo "lpar2rrd" >> /var/adm/cron/cron.allow

# Install lpar2rrd
ARG VERSION=lpar2rrd-7.30
WORKDIR $TEMP
RUN yum install -y wget
RUN wget https://www.lpar2rrd.com/download-static/lpar2rrd/$VERSION.tar
#COPY $VERSION.tar $TEMP
USER lpar2rrd
WORKDIR /home/lpar2rrd
RUN tar xvf $TEMP/$VERSION.tar
WORKDIR $VERSION
RUN echo -e "\n" | ./install.sh
RUN chmod -R 777 /home/lpar2rrd
WORKDIR /home/lpar2rrd/lpar2rrd

# Setup cron jobs
COPY crontab.txt $TEMP
RUN crontab $TEMP/crontab.txt

# Stup start script
USER root
COPY start.sh /root
RUN chmod 777 /root/start.sh

# Set Timezone
ENV TZ="Europe/Rome"


# Clean up
RUN rm -rf $TEMP

EXPOSE 80 8162


CMD ["/bin/bash", "-c", "/root/start.sh"]




