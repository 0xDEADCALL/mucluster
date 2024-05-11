#!/bin/bash

# Start SSH
service ssh start
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)

# If the node is the master boot yarn and hadoop
if [ "$TYPE" == "master" ]; 
then
    # Boot as master node
    hdfs --daemon start namenode

    # Start replication node
    hdfs --daemon start secondarynamenode

    # Start HBase
    start-hbase.sh

    # Bootstrap timelineservice
    while ! hdfs dfs -mkdir -p /hbase/coprocessor
    do 
        echo "Failed creating /hbase/coprocessor"
    done

    # Copy files
    hadoop fs -put $TIMELINE_LIB/hadoop-yarn-server-timelineservice-hbase-coprocessor-3.3.4.jar \
        /hbase/coprocessor/hadoop-yarn-server-timelineservice.jar

    # Populate HBase
    hbase org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator -create 

    # Start timeline service v2
    yarn --daemon start timelinereader

    # Create required directories for spark
    while ! hdfs dfs -mkdir -p /spark-logs;
    do
        echo "Failed creating /spark-logs hdfs dir"
    done

    # Start YARN resource manager
    yarn --daemon start resourcemanager
    mapred --daemon start historyserver

    # Run schematool if we don't have a schema
    has_schema=$( schematool -dbType postgres -info &> >(grep -c "\"VERSION\" does not exist") )
    if [[ has_schema -eq 1 ]]
    then
        schematool -dbType postgres -initSchema
    fi

    # Start spark history server
    start-history-server.sh

    # Start livy
    livy-server start

    # Start hive
    hiveserver2 start &
    hiveserver2 --service metastore -p 12003 -verbose

    
# If it's a slave boot only 
elif [ "$TYPE" == "slave" ]; 
then
    # start the worker node processes
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
fi
sleep infinity