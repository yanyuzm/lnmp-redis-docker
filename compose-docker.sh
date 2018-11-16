#!/bin/bash
#2018年9月26日
#by author caomuzhong
#Blog:www.logmm.com
echo
echo -e "\033[34m======================安装docker compose======================\033[0m"
[ ! -f /usr/local/bin/docker-compose ] && curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
echo -e "\033[34m====================创建部署lnmp的yaml文件====================\033[0m"
cat>docker-compose.yml<<EOF
version: "2"
services:
    redis:
       image: centos_redis
       container_name: redis-5.0.0
       ports:
         - "6379:6379"
       networks:
         - mynet
       volumes:
         - /redis_data:/redis_data:rw
         - /var/log/redis.log:/var/log/redis.log:rw
         - /root/webconf/redis.conf:/usr/local/redis/redis.conf 
       restart: always
    mariadb-slave: 
       image: centos_mariadb
       container_name: mariadb-10.3-S
       ports:
         - "3307:3306"
       networks:
         - mynet
       links:
         - mariadb-master
       environment:
         - MYSQL_ROOT_PASSWORD=123456
       volumes:
         - /mydb/3307/data/:/mydb/3306/data/:rw
         - /mydb/3307/my.cnf:/etc/my.cnf:ro
       restart: always
    mariadb-master: 
       image: centos_mariadb
       container_name: mariadb-10.3-M
       ports:
         - "3306:3306"
       networks:
         - mynet
       environment:
         - MYSQL_ROOT_PASSWORD=123456
       volumes:
         - /mydb/3306/data/:/mydb/3306/data/:rw
       restart: always
    mycat:
       image: centos_mycat
       container_name: mycat
       ports:
         - "8066:8066"
         - "9066:9066"
       networks:
         - mynet
       links:
         - mariadb-master
         - mariadb-slave
       volumes:
         - /root/mycat/server.xml:/usr/local/mycat/conf/server.xml
         - /root/mycat/schema.xml:/usr/local/mycat/conf/schema.xml
       restart: always
    php:
       image: centos_php
       container_name: php-7.2.10
       ports:
         - "9000:9000"
       networks:
         - mynet
       links:
         - mycat
         - mariadb-master
         - redis
       volumes:
         - /myweb/:/usr/local/nginx/html:rw
         - /root/webconf/php/www.conf:/usr/local/php7/etc/php-fpm.d/www.conf
       restart: always
    nginx:
       image: centos_nginx
       container_name: nginx-1.14.0
       ports:
         - "80:80"
         - "443:443"
       networks:
         - mynet
       links:
         - php
         - redis
       volumes:
         - /myweb/:/usr/local/nginx/html:rw
         - /root/webconf/nginx/nginx.conf:/usr/local/nginx/conf/nginx.conf
         - /root/webconf/nginx/conf.d/:/usr/local/nginx/conf.d/
         - /var/log/nginx/:/var/log/nginx/:rw
         - /etc/letsencrypt/live/logmm.org/privkey.pem:/etc/letsencrypt/live/logmm.org/privkey.pem
         - /etc/letsencrypt/live/logmm.org/fullchain.pem:/etc/letsencrypt/live/logmm.org/fullchain.pem
       restart: always
networks:
   mynet:
     ipam:
         config:
         - subnet: 172.18.0.0/16
           gateway: 172.18.0.1
EOF
