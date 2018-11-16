#!/bin/bash
#author:caomuzhong
#date:2018-9-26
#一键部署lnmp架构容器化

echo -e "\033[31;32m*****************************************************\033[0m"
echo -e "\033[34m================一键部署lnmp容器化===================\033[0m"
echo -e "\033[31;32m*****************************************************\033[0m"
echo
echo "版本：nginx：1.14.0  mariadb：10.3.10  php：7.2.10"
echo
echo -e "\033[31;32m===========部署前的准备=========\033[0m"
echo -e "\033[34m-----------创建nginx用户和组---------\033[0m"
id nginx &> /dev/null
[ $? -ne 0 ] && groupadd -g 1080 nginx  && useradd -g 1080 -u 1080 -M -s /sbin/nologin nginx
echo -e "\033[34m-----------创建mysql用户和组---------\033[0m"
id mysql &> /dev/null
[ $? -ne 0 ] && groupadd -g 3306 mysql  && useradd -g 3306 -u 3306 -M -s /sbin/nologin mysql
echo -e "\033[34m-----------创建网站目录和数据库data目录---------\033[0m"
[ ! -d /myweb ] && mkdir /myweb && chown -R nginx.nginx /myweb && chmod -R 777 /myweb
[ ! -d /mydb ] && mkdir /mydb/{3306,3307}/data -p && chown -R mysql.mysql /mydb && chmod -R 777 /mydb
echo
echo -e "\033[34-----------创建nginx、mariadb、php日志存放目录---------\033[0m"
[ ! -d /var/log/nginx/ ] && mkdir /var/log/nginx/ && chown nginx.nginx /var/log/nginx/
echo -e "\033[31;32m===========安装docker=========\033[0m"
echo -e "\033[34m-----------下载repo文件---------\033[0m"
[ ! -f /etc/yum.repos.d/docker-ce.repo ] && curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce -y
echo -e "\033[34m-----------设置加速器---------\033[0m"
[ ! -d /etc/docker ] && mkdir /etc/docker
cat >/etc/docker/daemon.json<<EOF
{
 "registry-mirrors": ["https://1xesnmzk.mirror.aliyuncs.com","http://hub-mirror.c.163.com","https://registry.docker-cn.com"]
}
EOF
systemctl start docker && echo -e "\033[31;32m-----------docker启动成功---------\033[0m"
echo -e "\033[31;32m===================================\033[0m"
echo -e "\033[34m    创建nginx、mariadb、php镜像    \033[0m"
echo -e "\033[31;32m===================================\033[0m"
[ ! -d nginx ] && mkdir nginx 
[ ! -d mariadb ] && mkdir mariadb
[ ! -d php ] && mkdir  php
cat>nginx/nginx.conf<<EOF
user  nginx nginx;
worker_processes  1;
worker_rlimit_nofile 65535;
error_log  /var/log/nginx/error.log notice;
events {
    use epoll;
    worker_connections  65535;
}
http {
    include mime.types;
    default_type application/octet-stream;
    server_names_hash_bucket_size 3526;
    server_names_hash_max_size 4096;
    log_format combined_realip '\$remote_addr \$http_x_forwarded_for [\$time_local]'
    ' \$host "\$request_uri" \$status'
    ' "\$http_referer" "\$http_user_agent"';
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 30;
    client_header_timeout 3m;
    client_body_timeout 3m;
    send_timeout 3m;
    connection_pool_size 256;
    client_header_buffer_size 1k;
    large_client_header_buffers 8 4k;
    request_pool_size 4k;
    output_buffers 4 32k;
    postpone_output 1460;
    client_max_body_size 10m;
    client_body_buffer_size 256k;
    client_body_temp_path /usr/local/nginx/client_body_temp;
    proxy_temp_path /usr/local/nginx/proxy_temp;
    fastcgi_temp_path /usr/local/nginx/fastcgi_temp;
    fastcgi_intercept_errors on;
    tcp_nodelay on;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 8k;
    gzip_comp_level 5;
    gzip_http_version 1.1;
    gzip_types text/plain application/x-javascript text/css text/htm 
    application/xml;
    include /usr/local/nginx/conf.d/*.conf;
}
EOF
cat>nginx/server.conf<<EOF
server {
listen       80;
server_name  localhost;
location / {
    root   /usr/local/nginx/html;
    index  index.php index.html index.htm;
}
location ~ \.php$ {
    root           /usr/local/nginx/html;
    fastcgi_pass   php:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME   /usr/local/nginx/html\$fastcgi_script_name;
    include        fastcgi_params;
}
}
EOF
echo -e "\033[34m================创建nginx Dockerfile===========\033[0m"
cat>nginx/Dockerfile<<EOF
FROM centos

#File Author / Maintainer
MAINTAINER caomuzhong www.logmm.com

#RUN yum install -y gcc gcc-c++ pcre-devel openssl-devel libxml2-devel openssl libcurl-devel make zlib zlib-devel gd-devel

#ADD http://nginx.org/download/nginx-1.14.0.tar.gz .
#Install Nginx
RUN  groupadd -g 1080 nginx  && useradd -g 1080 -u 1080 -M -s /sbin/nologin nginx \
   &&  mkdir -p /var/log/nginx  \
   &&  chown nginx.nginx /var/log/nginx \
   && yum install -y gcc gcc-c++ pcre-devel make openssl-devel libxml2-devel  libcurl-devel  zlib-devel gd-devel \
   && curl -O http://nginx.org/download/nginx-1.14.0.tar.gz \
   && tar xf nginx-1.14.0.tar.gz && rm -f nginx-1.14.0.tar.gz \
   &&  cd nginx-1.14.0 && ./configure --prefix=/usr/local/nginx \
       --http-log-path=/var/log/nginx/access.log \
       --error-log-path=/var/log/nginx/error.log \
       --user=nginx \
       --group=nginx \
       --with-http_ssl_module \
       --with-http_realip_module \
       --with-http_flv_module \
       --with-http_mp4_module \
       --with-http_gunzip_module \
       --with-http_gzip_static_module \
       --with-http_image_filter_module \
       --with-http_stub_status_module &&  make && make install && yum clean all \
  && rm -f /usr/local/nginx/conf/nginx.conf && mkdir /usr/local/nginx/conf.d/ && cd / && rm -rf /nginx-1.14.0
COPY nginx/nginx.conf  /usr/local/nginx/conf/nginx.conf
COPY nginx/server.conf /usr/local/nginx/conf.d/

#Expose ports
EXPOSE 80 443

#Front desk start nginx
ENTRYPOINT ["/usr/local/nginx/sbin/nginx","-g","daemon off;"] 
EOF
echo -e "\033[34m================创建mariadb Dockerfile===========\033[0m"
#从库配置文件，启动容器时挂载到容器的/etc目录中
cat>/mydb/3307/my.cnf<<EOF
# Example MariaDB config file for large systems.
#
# This is for a large system with memory = 512M where the system runs mainly
# MariaDB.
#
# MariaDB programs look for option files in a set of
# locations which depend on the deployment platform.
# You can copy this option file to one of those
# locations. For information about these locations, do:
# 'my_print_defaults --help' and see what is printed under
# Default options are read from the following files in the given order:
# More information at: http://dev.mysql.com/doc/mysql/en/option-files.html
#
# In this file, you can use all long options that a program supports.
# If you want to know which options a program supports, run the program
# with the "--help" option.

# The following options will be passed to all MariaDB clients
[client]
#password       = your_password
port            = 3306
socket          = /tmp/mysql.sock
# Here follows entries for some specific programs
# The MariaDB server
[mysqld]
port            = 3306
socket          = /tmp/mysql.sock
skip-external-locking
key_buffer_size = 256M
max_allowed_packet = 1M
table_open_cache = 256
sort_buffer_size = 1M
read_buffer_size = 1M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size= 16M
# Try number of CPU's*2 for thread_concurrency
thread_concurrency = 8
datadir = /mydb/3306/data/
innodb_file_per = on
skip_name_resolve = on
#skip-grant-tables

slow_query_log = ON
slow_query_log_file = /mydb/3306/slow.log
long_query_time = 1
# Point the following paths to different dedicated disks
#tmpdir         = /tmp/

# Don't listen on a TCP/IP port at all. This can be a security enhancement,
# if all processes that need to connect to mysqld run on the same host.
# All interaction with mysqld must be made via Unix sockets or named pipes.
# Note that using this option without enabling named pipes on Windows
# (via the "enable-named-pipe" option) will render mysqld useless!
# 
#skip-networking

# Replication Master Server (default)
# binary logging is required for replication
log-bin=mysql-bin

# binary logging format - mixed recommended
binlog_format=mixed

# required unique id between 1 and 2^32 - 1
# defaults to 1 if master-host is not set
# but will not function as a master if omitted
server-id       = 2

# Replication Slave (comment out master section to use this)
#
# To configure this host as a replication slave, you can choose between
# two methods :
#
# 1) Use the CHANGE MASTER TO command (fully described in our manual) -
#    the syntax is:
#
#    CHANGE MASTER TO MASTER_HOST=<host>, MASTER_PORT=<port>,
#    MASTER_USER=<user>, MASTER_PASSWORD=<password> ;
#
#    where you replace <host>, <user>, <password> by quoted strings and
#    <port> by the master's port number (3306 by default).
#
#    Example:
#
#    CHANGE MASTER TO MASTER_HOST='125.564.12.1', MASTER_PORT=3306,
#    MASTER_USER='joe', MASTER_PASSWORD='secret';
#
# OR
#
# 2) Set the variables below. However, in case you choose this method, then
#    start replication for the first time (even unsuccessfully, for example
#    if you mistyped the password in master-password and the slave fails to
#    connect), the slave will create a master.info file, and any later
#    change in this file to the variables' values below will be ignored and
#    overridden by the content of the master.info file, unless you shutdown
#    the slave server, delete master.info and restart the slaver server.
#    For that reason, you may want to leave the lines below untouched
#    (commented) and instead use CHANGE MASTER TO (see above)
#
# required unique id between 2 and 2^32 - 1
# (and different from the master)
# defaults to 2 if master-host is set
# but will not function as a slave if omitted
#server-id       = 2
#
# The replication master for this slave - required
#master-host     =   <hostname>
#
# The username the slave will use for authentication when connecting
# to the master - required
#master-user     =   <username>
#
# The password the slave will authenticate with when connecting to
# the master - required
#master-password =   <password>
#
# The port the master is listening on.
# optional - defaults to 3306
#master-port     =  <port>
#
# binary logging - not required for slaves, but recommended
#log-bin=mysql-bin

# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /usr/local/mysql/data
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = /usr/local/mysql/data
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
#innodb_buffer_pool_size = 256M
#innodb_additional_mem_pool_size = 20M
# Set .._log_file_size to 25 % of buffer pool size
#innodb_log_file_size = 64M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 128M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF
cp /mydb/3307/my.cnf  /root/mariadb/my.cnf
sed -i '/server-id/s/2/1/g' /root/mariadb/my.cnf
cat>mariadb/start.sh<<EOF
#!/bin/bash
if [ ! -f /mydb/3306/data/ibdata1 ]; then
       chown -R mysql.mysql /mydb/3306/data/
       /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/mydb/3306/data/
        /etc/rc.d/init.d/mariadb start
        /usr/local/mysql/bin/mysql -e "grant all on *.* to 'root'@'%' identified by '123456' with grant option;"
        /usr/local/mysql/bin/mysql -e "flush privileges;"     
fi
/etc/rc.d/init.d/mariadb restart
tail -f /etc/passwd
EOF
cat>mariadb/Dockerfile<<EOF
###  Set the base image to CentOS
FROM centos

#File Author / Maintainer
MAINTAINER caomuzhong www.logmm.com


#Download mariadb5.5.60 package

#ADD http://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-5.5.60/bintar-linux-x86_64/mariadb-5.5.60-linux-x86_64.tar.gz .
#http://mirrors.neusoft.edu.cn/mariadb//mariadb-5.5.60/bintar-linux-x86_64/mariadb-5.5.60-linux-x86_64.tar.gz
#http://ftp.hosteurope.de/mirror/archive.mariadb.org//mariadb-5.5.60/bintar-linux-x86_64/mariadb-5.5.60-linux-x86_64.tar.gz

#Unzip
RUN groupadd -g 3306 mysql && useradd -g 3306 -u 3306 -M -s /sbin/nologin mysql \
  && mkdir /mydb/3306/data/ -p \
  && chown -R mysql.mysql /mydb/ \
  && yum install -y libaio \
  && curl -O http://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-10.3.10/bintar-linux-x86_64/mariadb-10.3.10-linux-x86_64.tar.gz  \
  && tar xf mariadb-10.3.10-linux-x86_64.tar.gz -C /usr/local/ \
  && rm -f mariadb-10.3.10-linux-x86_64.tar.gz \
  && cd /usr/local/ && ln -sv mariadb-10.3.10-linux-x86_64/ mysql \
  && cd mysql/ && chown -R mysql.mysql ./* \
  && chown -R mysql.mysql /usr/local/mysql  \
  && cp support-files/mysql.server /etc/rc.d/init.d/mariadb \
  && chmod +x /etc/rc.d/init.d/mariadb \
  && touch /var/log/mariadb.log && chown mysql.mysql /var/log/mariadb.log \
  && chkconfig --add mariadb \
  && yum clean all
#expose
EXPOSE 3306
COPY mariadb/my.cnf /etc/my.cnf
ADD mariadb/start.sh  /opt/startup.sh
#RUN chmod +x /opt/startup.sh
CMD ["/bin/bash","/opt/startup.sh"]
EOF
echo -e "\033[34m================创建php Dockerfile===========\033[0m"
cat>php/Dockerfile<<EOF
###  Set the base image to CentOS
FROM centos

#File Author / Maintainer
MAINTAINER caomuzhong www.logmm.com

#Install necessary tools
#RUN yum install -y epel-release bzip2-devel openssl-devel gnutls-devel gcc gcc-c++  libmcrypt-devel libmcrypt ncurses-devel bison-devel libaio-devel openldap  openldap-devel autoconf bison libxml2-devel libcurl-devel libevent libevent-devel gd-devel  expat-devel

#ADD http://iweb.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz .
#RUN tar xf libmcrypt-2.5.8.tar.gz && cd libmcrypt-2.5.8 && ./configure && make && make install

#Install PHP7.2.x and Create dir the same for nginx's root dir

#ADD http://cn.php.net/distributions/php-7.2.7.tar.gz .
#ADD http://nz2.php.net/distributions/php-7.2.10.tar.gz .
#ADD http://hk2.php.net/distributions/php-7.2.10.tar.gz .
#ADD http://uk1.php.net/distributions/php-7.2.10.tar.gz .
RUN curl -O http://cn2.php.net/distributions/php-7.2.12.tar.gz  \
    && tar xf php-7.2.12.tar.gz && rm -f php-7.2.12.tar.gz \
    && groupadd -g 3306 mysql && useradd -g 3306 -u 3306 -s /sbin/nologin mysql \
    && groupadd -g 1080 nginx && useradd  -g 1080 -u 1080 -M -s /sbin/nologin nginx \
    && mkdir -p /usr/local/nginx/html && chown nginx.nginx /usr/local/nginx/html \
    && yum install -y epel-release bzip2-devel openssl-devel gnutls-devel gcc gcc-c++   ncurses-devel bison-devel libaio-devel openldap  openldap-devel autoconf bison libxml2-devel libcurl-devel libevent libevent-devel gd-devel  expat-devel \
    && cd / && curl -O http://iweb.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz . \
    && tar xf libmcrypt-2.5.8.tar.gz && cd libmcrypt-2.5.8 && rm -rf libmcrypt-2.5.8* && ./configure && make && make install \
    && cd /php-7.2.12 \
    && ./configure  --prefix=/usr/local/php7 \
        --with-config-file-path=/usr/local/php7/etc/ \
        --with-config-file-scan-dir=/usr/local/php7/etc/conf.d \
        --with-mysqli=mysqlnd  \
        --with-pdo-mysql=mysqlnd \
        --with-iconv-dir \
        --with-freetype-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib \
        --with-bz2 \
        --with-libxml-dir \
        --with-curl \
        --with-gd \
        --with-openssl \
        --with-mhash  \
        --with-xmlrpc \
        --with-pdo-mysql \
        --with-libmbfl \
        --with-onig \
        --with-pear \
        --enable-xml \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-fpm \
        --enable-mbstring \
        --enable-pcntl \
        --enable-sockets \
        --enable-zip \
        --enable-soap \
        --enable-opcache \
        --enable-pdo \
        --enable-mysqlnd-compression-support \
        --enable-maintainer-zts  \
        --enable-session \
        --with-fpm-user=nginx \
        --with-fpm-group=nginx  && make   && make  install  \
    && mkdir /usr/local/php7/etc/conf.d && cp php.ini-production  /usr/local/php7/etc/php.ini \
    && cp sapi/fpm/init.d.php-fpm  /etc/rc.d/init.d/php-fpm && chmod +x /etc/rc.d/init.d/php-fpm && chkconfig --add php-fpm \
    && sed -i '/post_max_size/s/8/16/g;/max_execution_time/s/30/300/g;/max_input_time/s/60/300/g;s#\;date.timezone.*#date.timezone \= Asia/Shanghai#g' /usr/local/php7/etc/php.ini \
    && curl -O http://pecl.php.net/get/redis-4.1.1.tgz \
    && tar xf redis-4.1.1.tgz \
    && cd redis-4.1.1 \
    && /usr/local/php7/bin/phpize \
    && ./configure --with-php-config=/usr/local/php7/bin/php-config && make && make install \
    && sed -i '/\;extension=bz2/aextension=redis.so'  /usr/local/php7/etc/php.ini \
    && cp /usr/local/php7/etc/php-fpm.conf.default /usr/local/php7/etc/php-fpm.conf \
    && cp /usr/local/php7/etc/php-fpm.d/www.conf.default /usr/local/php7/etc/php-fpm.d/www.conf \
    && echo -e "php_value[session.save_handler] = redis\nphp_value[session.save_path] = "tcp://127.0.0.1:6379"" >> /usr/local/php7/etc/php-fpm.d/www.conf \
    && sed -i -e 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/' /usr/local/php7/etc/php-fpm.d/www.conf && rm -rf /php-7.2.12 && rm -rf /redis-4.1.1 \
    && yum clean all
#EXPOSE
EXPOSE 9000
#Start php-fpm
ENTRYPOINT ["/usr/local/php7/sbin/php-fpm", "-F", "-c", "/usr/local/php7/etc/php.ini"]

EOF
echo -e "\033[31;32m====================================================================\033[0m"
echo -e "\033[31;32m     构建镜像的命令（建议打开多个终端同时执行以下命令,节省时间）    \033[0m"
echo -e "\033[34m构建nginx镜像：docker build -t centos_nginx -f nginx/Dockerfile .      \033[0m"
echo -e "\033[34m构建mariadb镜像：docker build -t centos_mariadb -f mariadb/Dockerfile . \033[0m"
echo -e "\033[34m构建php镜像：docker build -t centos_php -f php/Dockerfile .             \033[0m"
echo -e "\033[31;32m======================================================================\033[0m"
