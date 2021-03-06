#!/bin/sh

user=yuehuz

if test -b /dev/sdb && ! grep -q /dev/sdb /etc/fstab; then
    mke2fs -F -j /dev/sdb
    mount /dev/sdb /mnt
    chmod 755 /mnt
    echo "/dev/sdb	/mnt	ext3	defaults	0	0" >> /etc/fstab
fi

mkdir /mnt/hadoop
chown $user /mnt/hadoop

mkdir /dev/shm/hadoop
chown $user /dev/shm/hadoop

mkdir /mnt/hadoop-tmp-dir
chown $user /mnt/hadoop-tmp-dir

chown -R $user /usr/local/hadoop-2.7.3

sleep 10

if ! grep -q fs.defaultFS /usr/local/hadoop-2.7.3/etc/hadoop/core-site.xml; then
cat > /usr/local/hadoop-2.7.3/etc/hadoop/core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://namenode:9000/</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/mnt/hadoop-tmp-dir</value>
  </property>
</configuration>
EOF
fi

grep -o -E 'slave[0-9]+$' /etc/hosts > /usr/local/hadoop-2.7.3/etc/hadoop/slaves

if ! grep -q dfs.namenode.name.dir /usr/local/hadoop-2.7.3/etc/hadoop/hdfs-site.xml; then
cat > /usr/local/hadoop-2.7.3/etc/hadoop/hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/mnt/hadoop</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/mnt/hadoop,/dev/shm/hadoop</value>
  </property>
</configuration>
EOF
fi

if ! grep -q yarn.resourcemanager.hostname /usr/local/hadoop-2.7.3/etc/hadoop/yarn-site.xml; then
cat > /usr/local/hadoop-2.7.3/etc/hadoop/yarn-site.xml <<EOF
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>resourcemanager</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>0.0.0.0:8088</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>87040</value>
  </property>
  <property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>14</value>
  </property>
  <property>
    <name>yarn.scheduler.minimum-allocation-mb</name>
    <value>11264</value>
  </property>
  <property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>16384</value>
  </property>
  <property>
    <name>yarn.scheduler.maximum-allocation-vcores</name>
    <value>3</value>
  </property>
  <property>
    <name>yarn.scheduler.minimum-allocation-vcores</name>
    <value>1</value>
  </property>
</configuration>
EOF
fi

sleep 10

if ! grep -q mapreduce.framework.name /usr/local/hadoop-2.7.3/etc/hadoop/mapred-site.xml; then
cat > /usr/local/hadoop-2.7.3/etc/hadoop/mapred-site.xml <<EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>0.0.0.0:19888</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.command-opts</name>
    <value>-Xmx10240m</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.resource.mb</name>
    <value>15360</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.resource.cpu-vcores</name>
    <value>1</value>
  </property>
  <property>
    <name>mapreduce.map.memory.mb</name>
    <value>10240</value>
  </property>
  <property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>15360</value>
  </property>
  <property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx8192m</value>
  </property>
  <property>
    <name>mapreduce.reduce.java.opts</name>
    <value>-Xmx12288m</value>
  </property>
  <property>
    <name>mapreduce.task.io.sort.mb</name>
    <value>256</value>
  </property>
</configuration>
EOF
fi

sed -i orig -e 's@^export JAVA_HOME.*@export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64@' -e 's@^export HADOOP_CONF_DIR.*@export HADOOP_CONF_DIR=/usr/local/hadoop-2.7.3/etc/hadoop@' /usr/local/hadoop-2.7.3/etc/hadoop/hadoop-env.sh

if hostname | grep -q namenode; then
    if ! test -d /mnt/hadoop/current; then
        sudo -su $user /usr/local/hadoop-2.7.3/bin/hadoop namenode -format
    fi
        sudo -su $user /usr/local/hadoop-2.7.3/sbin/hadoop-daemon.sh --script hdfs start namenode
elif hostname | grep -q resourcemanager; then
    sudo -su $user /usr/local/hadoop-2.7.3/sbin/yarn-daemon.sh start resourcemanager
else
    sudo -su $user /usr/local/hadoop-2.7.3/sbin/yarn-daemon.sh start nodemanager
    sudo -su $user /usr/local/hadoop-2.7.3/sbin/hadoop-daemon.sh --script hdfs start datanode
fi

if hostname | grep -q namenode; then
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /user
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /user/$user
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir reads
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp/hadoop-yarn
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp/hadoop-yarn/staging
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn
    sudo -su $user /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn/staging
fi
