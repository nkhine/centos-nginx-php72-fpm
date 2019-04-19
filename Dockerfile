FROM centos/systemd

MAINTAINER "Norman Khine" <norman@khine.net>

#[Setup base image]
#Update centos to latest version and restart the instance.
RUN yum -y update
RUN yum install epel-release -y
RUN rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
#yum install puppet -y

#Install aws deployment tools
#RUN yum -y install awscli
#RUN yum install python-pip -y
#RUN pip install --upgrade pip
#RUN pip install pystache
#RUN pip install argparse
#RUN pip install python-daemon
#RUN pip install requests
#RUN cd /opt
#RUN curl -O https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
#RUN tar -zxf aws-cfn-bootstrap-latest.tar.gz
#RUN cd aws-cfn-bootstrap-1.4
#RUN python setup.py build
#RUN python setup.py install

#ln -s /usr/init/redhat/cfn-hup /etc/init.d/cfn-hup
#chmod +x /etc/init.d/cfn-hup
#mkdir -p /opt/aws/bin/
#ln -s /bin/cfn-hup /opt/aws/bin/cfn-hup
#ln -s /bin/cfn-init /opt/aws/bin/cfn-init
#ln -s /bin/cfn-signal /opt/aws/bin/cfn-signal
#ln -s /bin/cfn-elect-cmd-leader /opt/aws/bin/cfn-elect-cmdleader
#ln -s /bin/cfn-get-metadata /opt/aws/bin/cfn-get-metadata
#ln -s /bin/cfn-send-cmd-event /opt/aws/bin/cfn-send-cmd-event
#ln -s /bin/cfn-send-cmd-result /opt/aws/bin/cfn-send-cmdresult

#Fix cloudinit logging - remove extra debug info
#vi /etc/cloud/cloud.cfg.d/05_logging.cfg
#Add or uncomment at the end
#  - [ *log_base, *log_syslog ]
##Add:
# this tells cloud-init to redirect its stdout and stderr to
# 'tee -a /var/log/cloud-init-output.log' so the user can see output
# there without needing to look on the console.
#output: {all: '| tee -a /var/log/cloud-init-output.log'}
#

RUN yum install nginx -y
RUN yum install memcached -y
RUN yum install supervisor -y

RUN yum install php72 php72-php-fpm php72-php-pecl-memcached php72-php-gd php72-php-mbstring php72-php-mysqlnd php72-php-opcache php72-php-pdo-dblib php72-php-pecl-mcrypt php72-php-soap php72-php-xml -y

RUN cd /tmp
RUN curl -O https://elasticache-downloads.s3.amazonaws.com/ClusterClient/PHP-7.2/latest-64bit
RUN mv latest-64bit latest-64bit.tgz

RUN tar -zxvf latest-64bit.tgz
RUN mv amazon-elasticache-cluster-client.so /opt/remi/php72/root/usr/lib64/php/modules/
ADD conf/supervisord.conf /etc/supervisord.conf

RUN sed -i \
        -e "s/extension=memcached.so/extension=\/opt\/remi\/php72\/root\/usr\/lib64\/php\/modules\/amazon-elasticache-cluster-client.so/g" \
        -e "s/;memcached.sess_lock_wait_min = 150/memcached.sess_lock_wait_min = 1000/g" \
        -e "s/;memcached.sess_lock_wait_max = 150/memcached.sess_lock_wait_max = 2000/g" \
        -e "s/;memcached.sess_lock_retries = 200/memcached.sess_lock_retries = 5/g" \
    /etc/opt/remi/php72/php.d/50-memcached.ini
RUN sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/user = apache/user = nginx/g" \
        -e "s/group = apache/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = nobody/listen.owner = nginx/g" \
        -e "s/;listen.group = nobody/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        -e "s/= files/= memcached/g" \
        -e "s/= \/var\/opt\/remi\/php72\/lib\/php\/session/= 172.17.0.3:11211/g" \
    /etc/opt/remi/php72/php-fpm.d/www.conf


# Copy our nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
    mkdir -p /etc/nginx/sites-enabled/ && \
    mkdir -p /etc/nginx/ssl/ && \
    rm -Rf /var/www/* && \
    mkdir -p /var/www/html/
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

ADD scripts/start.sh /start.sh
#RUN chmod +x /start.sh
RUN chmod 755 /start.sh


# copy in code
ADD src/ /var/www/html/
ADD errors/ /var/www/errors

# add telnet - so we can test memcached, see README.md
RUN yum install telnet -y

EXPOSE 80

CMD ["/start.sh"]
