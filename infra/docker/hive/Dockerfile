FROM eclipse-temurin:17-jdk-jammy

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl netcat-openbsd procps && \
    rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION=3.3.4
ENV HIVE_VERSION=3.1.3
ENV HADOOP_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin

WORKDIR /opt

# Install Hadoop
RUN curl -L https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar xz && \
    mv hadoop-${HADOOP_VERSION} hadoop

# Install Hive
RUN curl -L https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz | tar xz && \
    mv apache-hive-${HIVE_VERSION}-bin hive

# Install MySQL and AWS Libs for Hive
WORKDIR /opt/hive/lib
RUN curl -O https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar && \
    curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar && \
    curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

# Remove conflicting guava if present (common Hive/Hadoop issue)
RUN rm -f /opt/hive/lib/guava-*.jar && \
    cp /opt/hadoop/share/hadoop/common/lib/guava-*.jar /opt/hive/lib/

# Copy AWS libs to Hadoop classpath as well just in case
RUN cp /opt/hive/lib/hadoop-aws-3.3.4.jar /opt/hadoop/share/hadoop/tools/lib/ && \
    cp /opt/hive/lib/aws-java-sdk-bundle-1.12.262.jar /opt/hadoop/share/hadoop/tools/lib/

WORKDIR /opt/hive
EXPOSE 9083

CMD ["hive", "--service", "metastore"]
