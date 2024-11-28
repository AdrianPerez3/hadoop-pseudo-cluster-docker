# Base image
FROM openjdk:11-jdk

# Set environment variables
ENV HADOOP_VERSION=3.4.1
ENV HADOOP_HOME=/usr/local/hadoop
ENV JAVA_HOME=/usr/local/openjdk-11
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Install necessary packages
RUN apt-get update && \
    apt-get install -y openssh-server wget rsync sudo && \
    rm -rf /var/lib/apt/lists/*

# Create hadoop user and group
RUN groupadd hadoop && \
    useradd -ms /bin/bash -g hadoop hadoop

# Allow hadoop user to use sudo without password
RUN echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH for hadoop user
RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -f /home/hadoop/.ssh/id_rsa -q -N "" && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chown -R hadoop:hadoop /home/hadoop/.ssh && \
    chmod 600 /home/hadoop/.ssh/authorized_keys

# Install Hadoop
COPY hadoop-${HADOOP_VERSION}.tar.gz /tmp/
RUN tar -xzvf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm /tmp/hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R hadoop:hadoop $HADOOP_HOME

# Configure Hadoop environment variables
RUN echo "export JAVA_HOME=/usr/local/openjdk-11" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Copy configuration files
COPY config/* $HADOOP_HOME/etc/hadoop/
RUN chown -R hadoop:hadoop $HADOOP_HOME/etc/hadoop/

#crear namenode y datanode
RUN mkdir -p /datos/namenode/current && \
    chown -R hadoop:hadoop /datos

# Switch to hadoop user
USER hadoop

# Format HDFS
RUN $HADOOP_HOME/bin/hdfs namenode -format -force

# Expose ports
EXPOSE 9870 8088 9000 8042 22 9864

# Switch back to root to copy the start script
USER root

# Copy the start script
COPY start-hadoop.sh /start-hadoop.sh
RUN chmod +x /start-hadoop.sh

# Switch to hadoop user
USER hadoop

# Set entry point
CMD ["/start-hadoop.sh"]
