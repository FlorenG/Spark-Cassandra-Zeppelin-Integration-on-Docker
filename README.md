# Spark-Cassandra-Zeppelin-Integration-on-Docker


  - Run perl script <i>sparkling.pl</i> to create spark container.</br> 


You will be prompted to:

``bash-4.1#``

Start Spark Shell: 
```
bash-4.1#spark-shell \ 
--master yarn-client \  
--packages datastax:spark-cassandra-connector:1.6.0-s_2.10  

[=======snip=======]

Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.6.0
      /_/

[=======snip=======]

scala>
scala>
```
  - For Zeppelin container creation go to https://github.com/Satanette/Zeppelin-on-Docker---Perl-script


  - Creating Cassandra container:



1)For Cassandra container, we will be using the official repository: </br> 
```
root@server# docker run --name=cassy -d cassandra
```
2) Connect to CQL and create a simple example: </br> 
```
root@server# docker exec -ti cassy cqlsh localhost
Connected to Test Cluster at localhost:9042.
[cqlsh 5.0.1 | Cassandra 3.10 | CQL spec 3.4.4 | Native protocol v4]
Use HELP for help.
cqlsh> 
cqlsh>  create keyspace rapcas with replication={'class':'SimpleStrategy', 'replication_factor':1};
cqlsh> use rapcas;
cqlsh:rapcas>  create table users (id varchar PRIMARY KEY, email varchar, password varchar, name varchar);
cqlsh:rapcas> insert into users(id, email, name, password) values('user1', 'user1@example.com', 'foo', 'super secret');
cqlsh:rapcas> select * from users;

 id    | email             | name | password
-------+-------------------+------+--------------
 user1 | user1@example.com |  foo | super secret

(1 rows)

```

3) Make sure Spark and Cassandra are in the same network:
```
root@server#docker network create --driver=bridge another_bridge 
root@server#docker network ls
NETWORK ID          NAME                DRIVER              SCOPE  
0cb64dac0168        another_network     bridge              local 
bb2b7ad13878        bridge              bridge              local
[...snip...]
```

Add containers Spark and Cassandra to the newly created bridge,  <i>another_network bridge</i>:</br>

```
root@server# docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep cassandra
a97b571a6bd6        cassandra
root@server# docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep spark
09f864b0e1b0        spark:1.6.0
root@server# docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep  ledzeppelin
5bd9cfdb969d  
root@server#
root@server# docker network connect another_bridge a97b571a6bd6
root@server# docker network connect another_bridge 09f864b0e1b0 
root@server# docker network connect another_bridge 5bd9cfdb969d
root@server#
```

Enter in each container and ping each other (below, how to find out the IPs). If ping is successful, they are in same network, and we can proceed with integration.
```
root@server# docker inspect $( docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep cassandra) | grep IPAddress | awk 'NR==2 {print $NF}' | cut -f1 -d ','
"172.17.0.4"
root@server#
root@server#  docker inspect $(docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep spark) | grep IPAddress |  awk 'NR==2 {print $NF}' | cut -f1 -d ','
"172.17.0.2"

root@server#  docker inspect $(docker ps  | sed -e 's/^\(.\{41\}\).*/\1/' | grep ledzeppelin | grep IPAddress |  awk 'NR==2 {print $NF}' | cut -f1 -d ','
"172.17.0.3"

``` 

From scala, run as following:

```
scala> import org.apache.spark.SparkContext
import org.apache.spark.SparkContext

scala> import org.apache.spark.SparkContext._
import org.apache.spark.SparkContext._

scala> import org.apache.spark.SparkConf
import org.apache.spark.SparkConf

scala> sc.stop

scala> val conf = new SparkConf(true).set("spark.cassandra.connection.host", "172.17.0.4") 
conf: org.apache.spark.SparkConf = org.apache.spark.SparkConf@bd1bd79

scala> val sc=new SparkContext("local[2]", "test", conf)


scala> import com.datastax.spark.connector._
import com.datastax.spark.connector._

scala> val rdd = sc.cassandraTable ("rapcas", "users")

scala>println(rdd.first)

```

Output will be:

```
[=======snip=======]

17/02/23 07:17:26 INFO scheduler.TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool
17/02/23 07:17:26 INFO scheduler.DAGScheduler: Job 0 finished: take at CassandraRDD.scala:121, took 1.763659 s
CassandraRow{id: user1, email: user1@example.com, name: foo, password: super secret}

scala> 17/02/23 07:17:34 INFO cql.CassandraConnector: Disconnected from Cassandra cluster: Test Cluster
scala>

```


From Zeppelin's side, do the following:

1) From <i>Interpreters</i>, go to <b>spark</b> and add <i>spark.cassandra.connection.host </i>, and the Cassandra cluster's IP:


![ScreenShot](https://github.com/Satanette/test/blob/master/add_hosts_spark_cassandra.png)

Now add the necessary dependecies:

![ScreenShot](https://github.com/Satanette/test/blob/master/spark_add_dependencies.png)



2) Still from <i>Interpreters</i>, this time go to <b>cassandra</b> and add <i> Cassandra cluster's IP </i>

![ScreenShot](https://github.com/Satanette/test/blob/master/hosts_cassandra.png)



3) Create new notebook and test it:

![ScreenShot](https://github.com/Satanette/test/blob/master/workish.png)






