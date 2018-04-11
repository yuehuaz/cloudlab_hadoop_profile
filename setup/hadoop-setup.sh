#!/bin/sh

if test -b /dev/sdb && ! grep -q /dev/sdb /etc/fstab; then
    mke2fs -F -j /dev/sdb
    mount /dev/sdb /mnt
    chmod 755 /mnt
    echo "/dev/sdb	/mnt	ext3	defaults	0	0" >> /etc/fstab
fi

mkdir /mnt/hadoop
chmod 1777 /mnt/hadoop

mkdir /dev/shm/hadoop
chmod 1777 /dev/shm/hadoop

mkdir /mnt/hadoop-tmp-dir
chmod 1777 /mnt/hadoop-tmp-dir

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
    <value>133120</value>
  </property>
  <property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>14</value>
  </property>
  <property>
    <name>yarn.scheduler.minimum-allocation-mb</name>
    <value>10240</value>
  </property>
  <property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>40960</value>
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

mkdir -p /mnt/hadoop-tmp-dir/mapred/local
chmod 1777 /mnt/hadoop-tmp-dir/mapred/local

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
    <value>-Xmx4096m</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.resource.mb</name>
    <value>10240</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.resource.cpu-vcores</name>
    <value>1</value>
  </property>
  <property>
    <name>mapreduce.map.memory.mb</name>
    <value>30720</value>
  </property>
  <property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>40960</value>
  </property>
  <property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx24576m</value>
  </property>
  <property>
    <name>mapreduce.reduce.java.opts</name>
    <value>-Xmx32768m</value>
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
	/usr/local/hadoop-2.7.3/bin/hadoop namenode -format
    fi
    /usr/local/hadoop-2.7.3/sbin/hadoop-daemon.sh --script hdfs start namenode
elif hostname | grep -q resourcemanager; then
    /usr/local/hadoop-2.7.3/sbin/yarn-daemon.sh start resourcemanager
else
    /usr/local/hadoop-2.7.3/sbin/yarn-daemon.sh start nodemanager
    /usr/local/hadoop-2.7.3/sbin/hadoop-daemon.sh --script hdfs start datanode
fi

if hostname | grep -q namenode; then
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /user
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp/hadoop-yarn
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -mkdir /tmp/hadoop-yarn/staging
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn
    /usr/local/hadoop-2.7.3/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn/staging
fi
