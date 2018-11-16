
# LNMP+redis架构docker化脚本

==========================

# 【一、系统环境】 #

==========================

**软件版本：**  nginx1.14.0、mariadb10.3.10、php-7.2.12  redis:5.0.0 phpredis:4.1.1

**宿主机系统：**  RHEL 7.5

宿主机网站目录：/myweb，数据库data目录：/mydb/3306/data，/mydb/3307/data/

其中，3306目录为主库，3307目录为从库

【**为方便测试，数据库root用户，密码：123456，授权host为%。实际中，必须修改。**】

**宿主机关闭防火墙和selinux**

==========================

# 【二、脚本说明】 #

==========================

总共有3个脚本文件：

**1、lnmp-docker.sh：**  该脚本主要是创建nginx、mariadb、php的配置文件及其

Dockerfile文件、宿主机网站、数据库data目录以及相关的用户和组。脚本执行

完成后，按照提示去创建镜像。

**2、mycat-docker.sh：**  此脚本主要创建mycat的Dockerfile文件。【必须

把jdk1.8的rpm软件包下载放到/root/mycat目录中，并且重命名为jdk1.8.rpm，

才能执行构建命令！】

**3、redis-docker.sh：**创建mycat的Dockerfile文件。

**4、compose-docker.sh：**   此脚本用户生成容器编排的yaml文件。

**5、ip.sh：**执行此脚本可以查看各个容器的ip。

**【nginx、mariadb、php、redis、mycat都使用编译安装，而不是使用现成的镜像】**

==========================

# 【三、文件目录】 #

==========================

这里有两类文件目录：

**一是：存放各个Dockerfile的目录：**

脚本执行完成后，生成的目录文件结构：

    [root@lb02 ~]# tree mariadb/
    
     mariadb/
       ├── Dockerfile
       └── start.sh
       0 directories, 2 files

    [root@lb02 ~]# tree nginx

     nginx
      ├── Dockerfile
      ├── nginx.conf
      └── server.conf

       0 directories, 3 files

    [root@lb02 ~]# tree php/

     php/
      └── Dockerfile

     0 directories, 1 file

    [root@lb02 ~]# tree mycat/

    mycat/

     ├── Dockerfile

     ├── jdk1.8.rpm ---此软件包并非脚本生成，得自己下载放到此目录中。

     ├── schema.xml

     └── server.xml

    0 directories, 4 files

    [root@lb02 ~]# 

    [root@lb02 ~]# tree redis
    redis
    └── Dockerfile

    0 directories, 1 file
    [root@lb02  ~]# 

**二是：配置文件目录：**

脚本执行后会生成一些配置文件，将相关的配置文件复制到webconf中对应的目录即可。结构如下：

	[root@lb02 ~]# tree webconf/
	webconf/
	├── mycat
	│   ├── schema.xml
	│   └── server.xml
	├── nginx
	│   ├── conf.d
	│   │   └── server.conf
	│   └── nginx.conf
	├── php
	│   └── www.conf
	└── redis.conf
	
	4 directories, 6 files
	[root@lb02 ~]# 



==========================

# 【四、mariadb主从】 #

==========================

容器启动后，需要手动配置mariadb数据库主从

3306端口为主库端口，3307端口为从库端口,均映射到容器中的3306端口。

主库：/mydb/3306/data/

从库：/mydb/3307/data/

==========================

# 【五、读写分离】 #

==========================

全部容器启动成功后，mycat读写分离已经配置好了。自定义的配置文件为：

/root/mycat、/root/webconf/目录中的schema.xml、server.xml，可根据实际修改。

登录9066端口，查看信息：

![](https://i.imgur.com/1U5i2Dz.jpg)

==========================

# 【六、容器启动】 #

=========================

各个镜像创建完后，信息如下：

![](https://i.imgur.com/qAHHcHR.jpg)

执行docker-compose up -d命令启动容器
 
    [root@lb02 ~]# docker-compose  up -d
    Creating network "root_default" with the default driver
    Creating mariadb-5.5.60-slave  ... done
    Creating mariadb-5.5.60-master ... done
    Creating mycat                 ... done
    Creating php-7.2.10            ... done
    Creating nginx-1.14.0          ... done
    [root@lb02 ~]#


容器启动后信息如下：

![](https://i.imgur.com/Ln4rtmD.jpg)

==========================

# 【七、部署WordPress】 #

==========================

网站目录：/myweb/，下载WordPress压缩包解压到该目录中。


效果图：

![](https://i.imgur.com/G2G77Oi.jpg)

==========================

**我的博客：**

www.logmm.com  
 
www.logmm.org
    
2018-11-16修改

==========================
