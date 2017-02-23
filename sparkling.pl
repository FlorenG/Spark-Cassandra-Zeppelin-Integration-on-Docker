#!/usr/bin/perl
use strict;



sub main {
    my $directory = "yarn_folder";

    unless(mkdir($directory, 0755)) {
        die "Unable to create $directory\n";
    }
}

main();


my $directory = './yarn_folder';
open my $fileHandle, ">>", "$directory/core-site.xml" or die "Can't open \n";
print $fileHandle "<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
      <name>fs.default.name</name>
      <value>hdfs\:\//sandbox:9000</value>
  </property>
  <property>
      <name>dfs.client.use.legacy.blockreader</name>
      <value>true</value>
  </property>

</configuration> \n";

close $fileHandle;

my $directory = './yarn_folder';
open my $fileHandle, ">>", "$directory/yarn-site.xml" or die "Can't open \n";
print $fileHandle "
<configuration>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>sandbox:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>sandbox:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>sandbox:8088</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>sandbox:8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>sandbox:8033</value>
  </property>
  <property>
      <name>yarn.application.classpath</name>
      <value>/usr/local/hadoop/etc/hadoop, /usr/local/hadoop/share/hadoop/common/\*\, /usr/local/hadoop/share/hadoop/common/lib/\*\, /usr/local/hadoop/share/hadoop/hdfs/\*\, /usr/local/hadoop/share/hadoop/hdfs/lib/\*\, /usr/local/hadoop/
share/hadoop/mapreduce/\*\, /usr/local/hadoop/share/hadoop/mapreduce/lib/\*\, /usr/local/hadoop/share/hadoop/yarn/\*\, /usr/local/hadoop/share/hadoop/yarn/lib/\*\, /usr/local/hadoop/share/spark/\*\</value>
   </property>
</configuration> ";

my $filename = 'Dockerfile';
open(my $fh, '>', 'Dockerfile');

print $fh  "FROM sequenceiq/hadoop-docker:2.6.0 \n" ;
print $fh "RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.6.1-bin-hadoop2.6.tgz | tar -xz -C /usr/local/
     cd /usr/local && ln -s spark-1.6.1-bin-hadoop2.6 spark \n";
print $fh "RUN cd /usr/local && ln -s spark-1.6.1-bin-hadoop2.6 spark
ENV SPARK_HOME /usr/local/spark ";
print $fh "RUN mkdir \$\SPARK_HOME/yarn_folder \n";
print $fh "ADD yarn_folder \$\SPARK_HOME/yarn-remote-client";
print $fh "UN \$\BOOTSTRAP && \$\HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && \$\HADOOP_PREFIX/bin/hdfs dfs -put \$\SPARK_HOME-1.6.1-bin-hadoop2.6/lib /spark";

print $fh "ENV YARN_CONF_DIR \$\HADOOP_PREFIX/etc/hadoop
ENV PATH \$\PATH:\$\SPARK_HOME/bin:\$\HADOOP_PREFIX/bin
COPY script.sh /etc/bootstrap.sh
RUN chown root.root /etc/script.sh
RUN chmod 700 /etc/script.sh ";

print$fh "RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
RUN yum -y install R \
ENTRYPOINT [\"/etc/script.sh\"] ";

close $fh;


my $filename = 'script.sh';
open(my $fh, '>', 'script.sh');
print $fh "#!/bin/bash \n";

print $fh "\:\ \$\{HADOOP_PREFIX\:\=/usr/local/hadoop}
\$\HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
rm /tmp/*.pid \n";

print $fh "cd \$\HADOOP_PREFIX/share/hadoop/common ; for cp in \$\{ACP\//\,/ }; do  echo == \$cp; curl -LO \$cp ; done; cd - \n";
print $fh "sed s/HOSTNAME/\$\HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml \n";
print $fh "echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.0-hadoop2.6.0.jar > \$\SPARK_HOME/conf/spark-defaults.conf\n";
print $fh "cp \$\SPARK_HOME/conf/metrics.properties.template \$\SPARK_HOME/conf/metrics.properties";

print $fh "echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.0-hadoop2.6.0.jar > \$\SPARK_HOME/conf/spark-defaults.conf \
cp \$\SPARK_HOME/conf/metrics.properties.template \$\SPARK_HOME/conf/metrics.properties \n";

print $fh "service sshd start
\$\HADOOP_PREFIX/sbin/start-dfs.sh
\$\HADOOP_PREFIX/sbin/start-yarn.sh \n";

print $fh "CMD=\$\{1:-\"exit 0\"}
if [[ \"\$\CMD\" == \"-d\" ]]; \
then \
        service sshd stop \
        /usr/sbin/sshd -D -d \
else \
        /bin/bash -c \"\$\*\" \
fi \n";

system("docker pull sequenceiq/spark:1.6.0");
system("docker build --rm -t sequenceiq/spark:1.6.0 . ");
system("docker run -it -p 8088:8088 -p 8042:8042 -p 4040:4040 -h sandbox sequenceiq/spark:1.6.0 bash ");

