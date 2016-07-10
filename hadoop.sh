#!/bin/sh
#hadoop部署脚本，不一定能够执行~水平有限见谅

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

read -p "输入远端服务器IP: " ip
ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@$ip
ssh root@$ip 'sed -i "s/^#RSAAuthentication\ yes/RSAAuthentication\ yes/g" /etc/ssh/sshd_config'
ssh root@$ip 'sed -i "s/^#PubkeyAuthentication\ yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config'
ssh root@$ip 'sed -i "s/^#PermitRootLogin\ yes/PermitRootLogin\ yes/g" /etc/ssh/sshd_config'
ssh root@$ip 'service sshd restart'
hostname=`ssh root@${ip} 'hostname'`
echo "添加主机名和IP到本地/etc/hosts文件中"
echo "$ip    $hostname" >> /etc/hosts
echo "远端主机主机名称为$hostname, 请查看 /etc/hosts 确保该主机名和IP添加到主机列表文件中"
echo "主机公钥复制完成"

cat /etc/hosts | while read LINE
do
    ip=`echo $LINE | awk '{print $1}' | grep -v "::" | grep -v "127.0.0.1"`
    echo "Copying /etc/hosts to ${ip}"
    scp -o StrictHostKeyChecking=no /etc/hosts root@${ip}:/etc/
done


cd /usr/local/ 
mkdir jdk1.7
tar -zxvf jdk1.7 -C ./jdk1.7

# set java home
echo '
# set java home
export JAVA_HOME=/usr/local/jdk1.7
export CLASSPATH=$JAVA_HOME/lib:JAVA_HOME/jre/lib
export PATH=$PATH:$JAVA_HOME/bin
'>> /etc/profile

scp -r /usr/local/jdk1.7 root@node1:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node2:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node3:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node4:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node5:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node6:/usr/local/jdk1.7
scp -r /usr/local/jdk1.7 root@node7:/usr/local/jdk1.7


#set Hadoop home

cd /home
mkdir software
cd software
mkdir hadoop-2.2
tar -zxvf hadoop2.2 -C ./hadoop-2.2
 


echo '
#set Hadoop home
export HADOOP_HOME=/home/software/hadoop-2.2
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"
'>> /etc/profile

source /etc/profile

scp /etc/profile root@node1:/etc/profile
scp /etc/profile root@node2:/etc/profile
scp /etc/profile root@node3:/etc/profile
scp /etc/profile root@node4:/etc/profile
scp /etc/profile root@node5:/etc/profile
scp /etc/profile root@node6:/etc/profile
scp /etc/profile root@node7:/etc/profile



#!/bin/bash
#check the java home
if [ "$JAVA_HOME" = "" ]
    then
    echo "JAVA_HOME IS EMPTY"
    exit 1
fi

#check the hadoop home
if [ "$HADOOP_HOME" = "" ]
    then
    echo "HADOOP_HOME IS EMPTY"
    exit 1
fi

master=`hostname`
echo "The hostname of master is $master."

num_of_slaves=0
for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
    do
    num_of_slaves=`expr $num_of_slaves + 1`
    done

sed -i '18,$d' $HADOOP_HOME/etc/hadoop/core-site.xml

echo "<configuration>
        <property>
        <name>hadoop.tmp.dir</name>
        <value>file:$HADOOP_HOME/data/tmp</value>
        </property>
    
        <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$master:9000</value>
        </property>
</configuration>" >>$HADOOP_HOME/etc/hadoop/core-site.xml

sed -i '18,$d' $HADOOP_HOME/etc/hadoop/hdfs-site.xml

echo "<configuration>
        <property>
        <name>dfs.replication</name>
        <value>$num_of_slaves</value>
        </property>">>$HADOOP_HOME/etc/hadoop/hdfs-site.xml
echo "<property>
        <name>dfs.namenode.name.dir</name>
        <value>file:$HADOOP_HOME/../hdfs/name</value>
        <final>true</final>
        </property>">>$HADOOP_HOME/etc/hadoop/hdfs-site.xml

echo " <property>
        <name>dfs.federation.nameservice.id</name>
        <value>ns1</value>
        </property>
        <property>
        <name>dfs.namenode.backup.address.ns1</name>
        <value>$master:50100</value>
        </property>
        <property>
        <name>dfs.namenode.backup.http-address.ns1</name>
        <value>$master:50105</value>
        </property>
        <property>
        <name>dfs.namenode.rpc-address.ns1</name>
        <value>$master:9000</value>
        </property>
        <property>
        <name>dfs.namenode.http-address.ns1</name>
        <value>$master:23001</value>
        </property>
        <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:$HADOOP_HOME/../hdfs/data</value>
        <final>true</final>
        </property>
        <property>
        <name>dfs.namenode.secondary.http-address.ns1</name>
        <value>$master:23002</value>
        </property>
</configuration>">>$HADOOP_HOME/etc/hadoop/hdfs-site.xml

sed -i '18,$d' $HADOOP_HOME/etc/hadoop/mapred-site.xml.template

echo "<configuration>
        <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        </property>
	 <property>
        <name>mapreduce.jobhistory.address</name>
        <value>$master:10020</value>
        </property>
	 <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>$master:19888</value>
        </property>
</configuration>">>$HADOOP_HOME/etc/hadoop/mapred-site.xml.template

if [ ! -f $HADOOP_HOME/etc/hadoop/mapred-site.xml ]
    then
    cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml
    else
    echo "$HADOOP_HOME/etc/hadoop/mapred-site.xml exist"
#exit 1;

fi

sed -i '15,$d' $HADOOP_HOME/etc/hadoop/yarn-site.xml

echo "<configuration>
<!-- Site specific YARN configuration properties -->
        <property>
        <name>yarn.resourcemanager.address</name>
        <value>$master:18040</value>
        </property>
        <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>$master:18030</value>
        </property>
        <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>$master:18088</value>
        </property>
        <property>
        <name>yarn.resourcemanager.admin.address</name>
        <value>$master:18141</value>
        </property>
        <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
        </property>
        <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>$master:18025</value>
        </property>
        <property>
        <name>yarn.resourcemanager.scheduler.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
        </property>
</configuration>">>$HADOOP_HOME/etc/hadoop/yarn-site.xml

sed -i "s,^export JAVA_HOME.*,export JAVA_HOME=${JAVA_HOME},g" $HADOOP_HOME/etc/hadoop/hadoop-env.sh

if [ $num_of_slaves -gt 1 ]
    then
    echo "send Hadoop to all the slaves..."
    for slave in `cat $HADOOP_HOME/etc/hadoop/slaves`
        do
        if [ "$slave" = "symtest2" ]
        then
        continue
        fi
	# make sure that slave:$HADOOP_HOME is not exist
	#need to modify your username
        scp -r $HADOOP_HOME root@$slave:$HADOOP_HOME
        done
    else
    echo "no need "
fi

scp -r /home/software/hadoop-2.2  root@node1:/home/software/hadoop-2.2
scp -r /home/software/hadoop-2.2  root@node1:/home/software/hadoop-2.2
scp -r /home/software/hadoop-2.2  root@node1:/home/software/hadoop-2.2
scp -r /home/software/hadoop-2.2  root@node1:/home/software/hadoop-2.2
scp -r /home/software/hadoop-2.2  root@node1:/home/software/hadoop-2.2

