#!/bin/bash

# Start SSH
service ssh start

# Check mode has been set
if [[ -z "${WORKER_MODE}" ]]; then
  echo "WORKER_MODE is not set"
  exit 1
fi

# If the node is the master boot yarn and hadoop
if [ "${WORKER_MODE}" == "MASTER" ]; then
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
    hadoop fs -put $TIMELINE_LIB/hadoop-yarn-server-timelineservice-hbase-coprocessor-3.4.0.jar \
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

    # Star spark history server
    start-history-server.sh

# If it's a slave boot only 
elif [ "${WORKER_MODE}" == "SLAVE" ]; then
    # start the worker node processes
    hdfs --daemon start datanode
    yarn --daemon start nodemanager

sleep infinity
