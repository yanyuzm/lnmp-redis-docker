#!/bin/bash
#2018-10-11
#www.logmm.com
menu(){ 
        echo
        echo -e "\033[31;32m                         docker部署mycat脚本                      \033[0m"
        echo -e "\033[31;32m============================================================================\033[0m"
        echo "说明：脚本放在/root目录中执行  "
        echo "执行前，先下载把jdk1.8的tar.gz包到/root/mycat目录，重命名为：jdk1.8.tar.gz  "
        echo -e "\033[31;32m============================================================================\033[0m"
        echo
        read -p "请输入数字：1[安装]，2[退出脚本]:"   num
}
install_mycat() {
 [ ! -d mycat ] && mkdir mycat
#mycat配置文件
cat>mycat/server.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!-- - - Licensed under the Apache License, Version 2.0 (the "License"); 
	- you may not use this file except in compliance with the License. - You 
	may obtain a copy of the License at - - http://www.apache.org/licenses/LICENSE-2.0 
	- - Unless required by applicable law or agreed to in writing, software - 
	distributed under the License is distributed on an "AS IS" BASIS, - WITHOUT 
	WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. - See the 
	License for the specific language governing permissions and - limitations 
	under the License. -->
<!DOCTYPE mycat:server SYSTEM "server.dtd">
<mycat:server xmlns:mycat="http://io.mycat/">
	<system>
	<property name="useSqlStat">0</property>  <!-- 1为开启实时统计、0为关闭 -->
	<property name="useGlobleTableCheck">0</property>  <!-- 1为开启全加班一致性检测、0为关闭 -->

		<property name="sequnceHandlerType">2</property>
      <!--  <property name="useCompression">1</property>--> <!--1为开启mysql压缩协议-->
        <!--  <property name="fakeMySQLVersion">5.6.20</property>--> <!--设置模拟的MySQL版本号-->
	<!-- <property name="processorBufferChunk">40960</property> -->
	<!-- 
	<property name="processors">1</property> 
	<property name="processorExecutor">32</property> 
	 -->
		<!--默认为type 0: DirectByteBufferPool | type 1 ByteBufferArena-->
		<property name="processorBufferPoolType">0</property>
		<!--默认是65535 64K 用于sql解析时最大文本长度 -->
		<!--<property name="maxStringLiteralLength">65535</property>-->
		<!--<property name="sequnceHandlerType">0</property>-->
		<!--<property name="backSocketNoDelay">1</property>-->
		<!--<property name="frontSocketNoDelay">1</property>-->
		<!--<property name="processorExecutor">16</property>-->
		<!--
			<property name="serverPort">8066</property> <property name="managerPort">9066</property> 
			<property name="idleTimeout">300000</property> <property name="bindIp">0.0.0.0</property> 
			<property name="frontWriteQueueSize">4096</property> <property name="processors">32</property> -->
		<!--分布式事务开关，0为不过滤分布式事务，1为过滤分布式事务（如果分布式事务内只涉及全局表，则不过滤），2为不过滤分布式事务,但是记录分布式事务日志-->
		<property name="handleDistributedTransactions">0</property>
		
			<!--
			off heap for merge/order/group/limit      1开启   0关闭
		-->
		<property name="useOffHeapForMerge">1</property>

		<!--
			单位为m
		-->
		<property name="memoryPageSize">1m</property>

		<!--
			单位为k
		-->
		<property name="spillsFileBufferSize">1k</property>

		<property name="useStreamOutput">0</property>

		<!--
			单位为m
		-->
		<property name="systemReserveMemorySize">384m</property>


		<!--是否采用zookeeper协调切换  -->
		<property name="useZKSwitch">true</property>


	</system>
	
	<!-- 全局SQL防火墙设置 -->
	<!-- 
	<firewall> 
	   <whitehost>
	      <host host="127.0.0.1" user="mycat"/>
	      <host host="127.0.0.2" user="mycat"/>
	   </whitehost>
       <blacklist check="false">
       </blacklist>
	</firewall>
	-->
	
	<user name="root">
		<property name="password">123456</property>
		<property name="schemas">wordpress</property>
		
		<!-- 表级 DML 权限设置 -->
		<!-- 		
		<privileges check="false">
			<schema name="TESTDB" dml="0110" >
				<table name="tb01" dml="0000"></table>
				<table name="tb02" dml="1111"></table>
			</schema>
		</privileges>		
		 -->
	</user>
	<user name="wpuser">
		<property name="password">123456</property>
		<property name="schemas">wordpress</property>
	</user>

	<user name="user">
		<property name="password">user</property>
		<property name="schemas">wordpress</property>
		<property name="readOnly">true</property>
	</user>

</mycat:server>

EOF
cat>mycat/schema.xml<<EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
        <schema name="wordpress" checkSQLschema="false" sqlMaxLimit="1000" dataNode="dn1" />
        <!--   <schema name="zblog" checkSQLschema="false" sqlMaxLimit="1000" dataNode="dn2" /> -->

        <dataNode name="dn1" dataHost="localhost1" database="mywpdb" />
       <!--    <dataNode name="dn2" dataHost="localhost1" database="zblog" /> -->
        <dataHost name="localhost1" maxCon="2000" minCon="1" balance="1"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="2"  slaveThreshold="100">
            <heartbeat>select user()</heartbeat>

            <writeHost host="hostMaster" url="144.34.196.107:3306" user="wpuser" password="wpadmin">
                  <!-- can have multi read hosts -->
                  <readHost host="hostSlave" url="144.34.196.107:3307" user="wpuser" password="wpadmin" />
            </writeHost>
        </dataHost>
</mycat:schema>
EOF
#Dockerfile文件
cat>mycat/Dockerfile<<EOF
###  Set the base image from CentOS
FROM centos
#File Author / Maintainer
MAINTAINER caomuzhong www.logmm.com
#install jdk mycat
#ADD  mycat/jdk1.8.tar.gz /usr/local/
ADD  mycat/jdk1.8.rpm .
#ADD mycat/mycat  /usr/local/mycat
RUN rpm -ivh jdk1.8.rpm \
   && curl -O http://dl.mycat.io/1.6-RELEASE/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz \
   && tar xf Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz -C /usr/local \
   && rm -f Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz \
#RUN mv /usr/local/mycat/conf/server.xml{,.bak} \
#  && mv /usr/local/mycat/conf/schema.xml{,.bak}  
#COPY mycat/*.xml /usr/local/mycat/conf/
#COPY mycat/schema.xml /usr/local/mycat/conf/
#ENV JAVA_HOME /usr/local/jdk1.8.0_181
#ENV CLASSPATH \$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
#ENV PATH \$PATH:\$JAVA_HOME/bin
EXPOSE 8066 9066
RUN chmod -R 777 /usr/local/mycat/bin  
CMD ["./usr/local/mycat/bin/mycat","console"]
EOF
echo -e "\033[34m执行构建mycat镜像：docker build -t centos_mycat -f mycat/Dockerfile .      \033[0m"
}
#脚本运行入口
run_install(){
     #   while true;do
     #   menu
     #   case $num in
     #   "1")
                   echo -e "\033[34m========docker部署mycat===========\033[0m"
                   install_mycat
                   echo -e "\033[34m========退出脚本后，执行构建命令===========\033[0m"
                   exit 0
    #               ;;
      #  "2")
      #             exit 0
      #             ;;
      #    *)
     #              ;;
     #   esac
    #    done
}
#调用脚本运行入口
run_install