#!/bin/bash
#2018-10-11
#www.logmm.com
[ ! -d /redis_data ] && mkdir /redis_data
echo -e "\033[34m===========  Redis  Dockerfile ==============\033[0m"
[ ! -d redis ] && mkdir redis
cat>redis/Dockerfile<<EOF
FROM centos

#File Author / Maintainer
MAINTAINER caomuzhong www.logmm.com

RUN  echo -e "sysctl vm.overcommit_memory=1\necho never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local \
  && yum install -y make gcc \
  && curl -O http://download.redis.io/releases/redis-5.0.0.tar.gz \
  && tar xf redis-5.0.0.tar.gz \
  && cd redis-5.0.0 \
  && make && make  PREFIX=/usr/local/redis install \
  && cp redis.conf /usr/local/redis/ \
  && echo "PATH=/usr/local/redis/bin:\$PATH">>/etc/profile \
  && source /etc/profile \
  && rm -rf /redis-5.0.0

EXPOSE 6379

CMD /usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
EOF
echo
echo -e "\033[34m构建redis镜像：docker build -t centos_redis -f redis/Dockerfile . \033[0m"
