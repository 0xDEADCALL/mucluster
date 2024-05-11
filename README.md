# μcluster

Welcome to _μcluster_ or _mucluster_! A docker playground for experimenting with Big Data technologies like Spark, Hadoop, YARN, and more! This Docker-based setup allows you to quickly spin up an environment to test and play with various tools and frameworks without worrying about the complexities of installation and configuration.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Getting Started](#getting-started)
3. [Included Technologies](#included-technologies)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Additional Resources](#additional-resources)
7. [Disclaimer](#disclaimer)

## Prerequisites
* Docker installed on your system. You can download and install Docker from [here](https://docs.docker.com/compose/install/).
* Have a decent amount of RAM (16GB should be enough) and disk space

## Getting Started
To get started with this docker playground, follow these simple steps:

1. Clone this repository to your local environment:
    ```bash
    git clone https://github.com/AlexStirban/mucluster.git
    ```
2. Navigate to the project directory:
    ```bash
    cd mucluster
    ```
3. Copy the `.env.sample` file as `.env` and replace the values of `NOTEBOOK_UID` and `NOTEBOOK_GID` with the User ID and Group ID of your current user:
    ```bash
    cp .env.sample .env \
        && sed -i -e "s|\[UID\]|$(id -u)|g" .env \
        && sed -i -e "s|\[GID\]|$(id -g)|g" .env 
    ```
4. Build the Docker images:
    ```bash
    docker-compose build
    ```
5. Run services in detached mode:
    ```bash
    docker-compose up -d
    ```
    > [!NOTE]
    > You can also have an interactive lift of the services by omitting the `-d` flag.

6. Access the environment UIs using the URLs provided or submit jobs to your newly created cluster. Please see [Usage](#usage) for more information.

## Included Technologies

This playground deploys the following Big Data tools:
* Spark 3.5.1
* Apache Iceberg
* Hadoop 3.3.4
* HBase 1.2.6 (Standalone) for the YARN Timeline Service v.2. Please see [Documentation](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html)
* Livy 0.8.0-rc2
* Hive 4.0.0
* PostgreSQL Database (used as the metastore)
* MinIO (used as the data lake)
* Jupyter Lab & Sparkmagic (used for interactive analytics)
* Hue (used as a centralized SQL assistant)

> [!NOTE]
> Keep in mind that we won't be using the actual release binaries, but a fork I've made to update the dependencies and _fix_ some missing JVM class imports for spark3. Please see:
[(LIVY-863) Missing JVM class imports for Spark3](https://www.mail-archive.com/issues@livy.apache.org/msg00719.html) and [Livy Fork](https://github.com/AlexStirban/incubator-livy).

## Configuration
Most of the times everything should be working by now, however you might need to tweak how the services are being deployed. Below you can find the main configurations used by _μcluster_. 

### .env 
In the root directory you'll find a .env file that stores some basic settings
shared between services:
|                              | **Default Value**                        | **Description**                                                                                                              |
|------------------------------|------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| **MINIO_PORT**               | 10000                                    | Port the MinIO Server will bind to                                                                                           |
| **MINIO_PORT**               | 10001                                    | Port the MinIO Web UI will bind to                                                                                           |
| **MINIO_ROOT_USER**          | root                                     | Root user for MinIO                                                                                                          |
| **MINIO_ROOT_PASSWORD**      | wfNFHGIvYf1RrJ1                          | Root password for MinIO                                                                                                      |
| **AWS_ACCESS_KEY_ID**        | y9kmpQA4RC2asIF4toWi                     | Initial access key created and propagated to the other services                                                              |
| **AWS_SECRET_ACCESS_KEY**    | M9piklUa69UTjMcnX4zW1hl7LJJHym7BLbm0GZ2C | Initial access secret created and propagated to the other services                                                           |
| **METASTORE_USER**           | meta                                     | User for the PostgreSQL metastore instance                                                                                   |
| **METASTORE_PASS**           | 7dDWK2Ft                                 | Password for the PostgreSQL metastore instance                                                                               |
| **NOTEBOOK_UID**             | [GID]                                    | User ID to be used for Jupyter Lab when creating files and folder.  Set it to be the same as your current user with `id -u`  |
| **NOTEBOOK_GID**             | [UID]                                    | Group ID to be used for Jupyter Lab when creating files and folder.  Set it to be the same as your current user with `id -g` |
| **INCLUDE_CSV_SAMPLES**      | true                                     | Creates a `samples-csv-src` bucket in MinIO with two sample datasets: iris.csv and wine.csv                                  |
| **INCLUDE_NOTEBOOK_SAMPLES** | true                                     | Create a samples directory with two notebooks that show how to read/write files and a quick iceberg showcase                 |

### Cluster

> [!WARNING]
> **If you plan on changing the ports or hostnames used by default in the `.yml` you'll need to propagate some of them to the proper service configuration as well.**


_μcluster_ will deploy by default a master instance and two slaves (see: `docker/compute.yml`):
* The master instance deploys the RM, HBase, Timeline Service, Spark History Server, Livy and Hive.
* The slaves will only ship with hadoop and spark to act as workers.

For any tweaks use the subfolders inside the `cluster` directory:
```
📦cluster
 ┣ 📂hadoop
 ┃ ┣ 📜core-site.xml
 ┃ ┣ 📜hdfs-site.xml
 ┃ ┣ 📜mapred-site.xml
 ┃ ┗ 📜yarn-site.xml
 ┣ 📂hbase
 ┃ ┗ 📜hbase-site.xml
 ┣ 📂hive
 ┃ ┗ 📜hive-site.xml
 ┣ 📂livy
 ┃ ┣ 📜livy-env.sh
 ┃ ┗ 📜livy.conf
 ┣ 📂spark
 ┃ ┣ 📜hive-site.xml
 ┃ ┣ 📜log4j.properties
 ┃ ┗ 📜spark-defaults.conf
```
Check [Additional Resources](#additional-resources) to get more information on each specific file.

### Docker
Under the `docker` folder you'll find the definitions of each service in compose files and grouped by their purpose:
```
📦docker
 ┣ 📜analytics.yml --> Hue & Jupyter Lab + Sparkmagic
 ┣ 📜compute.yml   --> Hadoop, YARN, Hive...
 ┣ 📜networks.yml  --> Network shared by the services 
 ┗ 📜storage.yml   --> MinIO & PostgreSQL
```
If you require including a new tool, feel free to add it to any of the above categories or create a new one (remember to use the same network and include it in `compose.yml`)

### Metastore

Both Hive and Hue require an auxiliary storage to keep track of the schema changes, users logged, configurations...To manage that a PostgreSQL instance is deployed. Inside the `metastore` folder you'll find:
```
📦metastore
 ┣ 📜data    --> Mounted folder to store PostgreSQL data 
 ┣ 📜hue.ini --> Configuration file for hue
 ┗ 📜init.sh --> Bootstrapping script for PostgreSQL
```
Check [Addtional Resources](#additional-resources) to get more information on how Hue should configured.

### Minio
We're using MinIO as the data lake for it's simplicity and compatibility with S3, 
in the `minio` folder you'll find:
```
📦minio
 ┣ 📜data    --> Mounted folder to store MinIO data 
 ┣ 📜samples --> Folder with the samples that will be uploaded to `samples-csv-src` bucket
 ┗ 📜init.sh --> Bootstrapping script for MinIO
```

### Sparkmagic
As a "quick-n-dirty" analytics tool an instance of Jupyter Lab and sparkmagic is provided, 
in the `sparkmagic` folder you'll find:
```
📦sparkmagic
 ┣ 📂samples                --> Sample included in the environment
 ┃ ┣ 📜sample.ipynb
 ┃ ┗ 📜sample_iceberg.ipynb
 ┣ 📜Dockerfile             --> Image definition
 ┣ 📜config.json            --> Configuration for sparkmagic (Livy server, timeouts, kernel...)
 ┣ 📜entrypoint.sh          --> Bootstrapping script
 ┗ 📜requirements.txt       --> Requirements file used to install additional packages
```

## Usage

After starting the Docker containers as instructed in the "Getting Started" section, you can start experimenting with various Big Data technologies. Here are a few common tasks you might want to try:

* Launching a Spark job using the Spark shell or submitting a Spark application.
* Monitoring resource usage and job status via YARN ResourceManager UI.
* Create S3 resources (buckets, upload files...) using MinIO.
* Read/Transform/Save data using spark in Jupyter Lab through the Livy server.
* Query data using Hive through Hue or the beeline CLI.

> [!WARNING]
> We only have two slaves available (feel free to scale-up if you can), thus only one livy session can be started at the same time (one driver and one worker). Starting two sessions will keep the last one in queue until more resources are available.

### Web UIs
By default the different UIs used for monitoring the jobs, sessions or accessing Jupyter Lab can be found as:

|                   | **Port**                   | **Description**           |
|-------------------|----------------------------|---------------------------|
| **Jupyer Lab**    | http://localhost:8888      | Jupyter Lab + Spark Magic |
| **Yarn UI**       | http://localhost:8088/ui2/ | YARN UI v2                |
| **MinIO Console** | http://localhost:10001/    | MinIO Console             |
| **Livy**          | http://localhost:8998/     | Livy UI & Server          |
| **Spark UI**      | http://localhost:18080/    | Spark History Server      |
| **Hue**           | http://localhost:9999/     | Hue SQL Assistance        |
| **Hadoop UI**     | http://localhost:9870/     | Hadoop UI                 |

## Additional Resources
While this project serves as good starting point, it's not meant to explain how each service actually works, see the following resources for more info:
* Apache Related Configuration:
    
    * XML files: [core-site.xml](https://hadoop.apache.org/docs/r3.3.4/hadoop-project-dist/hadoop-common/core-default.xml), [hdfs-site.xml](https://hadoop.apache.org/docs/r3.3.4/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml), [mapred-site.xml](https://hadoop.apache.org/docs/r3.3.4/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml), [yarn-site.xml](https://hadoop.apache.org/docs/r2.7.3/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
    * YARN: [Determining Memory Config](https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.6.5/bk_command-line-installation/content/determine-hdp-memory-config.html)
    * Timeline Service v2: [Overview](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html) & [HBase Deployment](https://hbase.apache.org/book.html#quickstart)
        > [!WARNING]
        > You might be tempted to use the latest Hbase version, however the timelineservice v2 doesn't seem to work properly if we're not in version 1.2.6 and Java 1.8, upgrade at your own risk!
    * Hive: [Quickstart](https://cwiki.apache.org/confluence/display/Hive/GettingStarted)
    * Livy: [.conf template](https://github.com/apache/incubator-livy/blob/master/conf/livy.conf.template), [Build Livy with Docker](https://github.com/apache/incubator-livy), [(LIVY-863) Missing JVM class imports for Spark3](https://www.mail-archive.com/issues@livy.apache.org/msg00719.html)
    * Spark: [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html)

* Sparkmagic: [Install and Settings](https://github.com/jupyter-incubator/sparkmagic)
* Hue: [hue.ini](https://docs.gethue.com/administrator/configuration/connectors/)
* MinIO: [MinIO CLI](https://min.io/docs/minio/linux/reference/minio-mc.html)

## Disclaimer
This project is nothing more than a learning exercise for me. I tried making it approachable for anyone else; nonetheless, you'll need to have some understanding of Spark, Apache tools, and Docker. None of this should be used as it is in production environments as I had no security concerns at the time.

In the best-case scenario, this will work for you out-of-the-box; if not, tinker and play around, don't get frustrated and enjoy!