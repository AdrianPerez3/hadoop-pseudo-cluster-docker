#!/bin/bash

# Start SSH service (requires root privileges)
sudo service ssh start

# Start Hadoop services
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Keep the container running
tail -f /dev/null
