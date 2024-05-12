# Select the node type
ARG type

# We'll start with the minium requirements for a slave
FROM ubuntu:18.04 AS slave

# Declare paths
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/opt/hadoop
ENV LIVY_HOME=/opt/livy
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PYSPARK_PYTHON=python3
ENV HBASE_HOME=/opt/hbase
ENV HBASE_CONF_DIR=/opt/hbase/conf
ENV HIVE_HOME=/opt/hive
ENV TIMELINE_LIB=${HADOOP_HOME}/share/hadoop/yarn/timelineservice

# Install required tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      sudo \
      curl \
      vim \
      zip \
      unzip \
      wget \ 
      net-tools \
      build-essential \
      rsync \
      openjdk-8-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download binaries
# Keep them at the beginning so downloads are cached
RUN curl -O https://archive.apache.org/dist/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz
RUN curl -O https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz

# Install hadoop and spark
RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}
RUN tar xzf  hadoop-3.3.4.tar.gz          -C ${HADOOP_HOME} --strip-components 1 && rm -rf hadoop-3.3.4.tar.gz 
RUN tar xvzf spark-3.5.1-bin-hadoop3.tgz  -C ${SPARK_HOME}  --strip-components 1 && rm -rf spark-3.5.1-bin-hadoop3.tgz

# Generate dummy SSH key for containers to communicate
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys
RUN printf "Host * \n \tUserKnownHostsFile /dev/null \n \tStrictHostKeyChecking no" >> /root/.ssh/config
RUN chmod 600 /root/.ssh/config


# Add JAVA_HOME to *-env.sh
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

# Prepare hadoop to use AWS
RUN echo "export HADOOP_OPTIONAL_TOOLS=\"hadoop-aws\"" >> "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

# Set hadoop and yarn user
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# Export additional paths
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin

# Use different stage to exploit caching as binaries are quite large
FROM slave AS pre-master

# Add hive
ENV PATH=$PATH:${HIVE_HOME}/bin

# Install hbase and modified livy server
RUN curl -O https://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
RUN curl -L -O https://github.com/AlexStirban/incubator-livy/releases/download/v0.8.0-spark3-jvm-fix/livy-0.8.0-spark3-jvm.tar.gz
RUN curl -O https://downloads.apache.org/hive/hive-4.0.0/apache-hive-4.0.0-bin.tar.gz
RUN curl -O https://jdbc.postgresql.org/download/postgresql-42.7.3.jar

# Make installation dir
RUN mkdir -p ${HBASE_HOME} && mkdir -p ${LIVY_HOME} && mkdir -p ${HIVE_HOME}

# Unpack files
RUN tar xzf  hbase-1.2.6-bin.tar.gz       -C ${HBASE_HOME}  --strip-components 1 && rm -rf hbase-1.2.6-bin.tar.gz
RUN tar xzf  livy-0.8.0-spark3-jvm.tar.gz -C ${LIVY_HOME}   --strip-components 1 && rm -rf livy-0.8.0-spark3-jvm.tar.gz
RUN tar xzf  apache-hive-4.0.0-bin.tar.gz -C ${HIVE_HOME}   --strip-components 1 && rm -rf apache-hive-4.0.0-bin.tar.gz
RUN mv postgresql-42.7.3.jar ${HIVE_HOME}/lib/postgresql-42.7.3.jar

FROM pre-master AS master

# Pull the auth for metastore
ARG metastore_user
ARG metastore_pass

# Copy configurations to each directory
COPY /hbase/*.xml        ${HBASE_CONF_DIR}
COPY /livy/*             ${LIVY_HOME}/conf
COPY /hive/*             ${HIVE_HOME}/conf

# Inject password and user for Hive
RUN sed -i -e "s|\[PASSWORD\]|${metastore_pass}|g" ${HIVE_HOME}/conf/hive-site.xml
RUN sed -i -e "s|\[USER\]|${metastore_user}|g" ${HIVE_HOME}/conf/hive-site.xml

# Configure Livy
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> "$HBASE_CONF_DIR/hadoop-env.sh"
RUN echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> "$LIVY_HOME/conf/livy-env.sh"
RUN echo "export SPARK_HOME=${SPARK_HOME}" >> "$LIVY_HOME/conf/livy-env.sh"

# Export to HBASE classpath
ENV HBASE_CLASSPATH=$HBASE_CLASSPATH:${TIMELINE_LIB}/hadoop-yarn-server-timelineservice-hbase-client-3.3.4.jar
ENV HBASE_CLASSPATH=$HBASE_CLASSPATH:${TIMELINE_LIB}/hadoop-yarn-server-timelineservice-3.3.4.jar
ENV HBASE_CLASSPATH=$HBASE_CLASSPATH:${TIMELINE_LIB}/hadoop-yarn-server-timelineservice-hbase-common-3.3.4.jar

# Export additional paths
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native
ENV PATH=${PATH}:${HBASE_HOME}/bin:${LIVY_HOME}/bin

# Expose and boot into container
FROM ${type} AS final

# Copy config files as they should be present for slaves and master
COPY /hadoop/*.xml        ${HADOOP_CONF_DIR}
COPY /spark/*             ${SPARK_HOME}/conf

# Get ARG again as it won't be accessible out of a given stage
# and pass it to entrypoint script
ARG type
ENV TYPE=${type}

# HDFS ports
EXPOSE 9870 9864 8020 9867 9868 8485 8480 50200 11000 12003 2181

# YARN ports
EXPOSE 8032 8030 8088 8031 8032 8030 8033 8040 8048 8042 10200 8188 8047 42197

# Mapred ports
EXPOSE 10020 19888 10033

# Livy
EXPOSE 8998

# Spark UI
EXPOSE 18080

# Format the node
RUN hdfs namenode -format -force

# # Entrypoint
COPY entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"] 